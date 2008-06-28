module Announcements
  class SubscriptionRegistry
    attr_accessor :classes_and_subscriptions, :subscription_class
    
    def initialize
      @classes_and_subscriptions = {}
      @subscription_class = ::Announcements::Subscription
    end

    def release
      @classes_and_subscriptions = {}
    end

    def create_subscription
      self.subscription_class.for_registry self
    end

    def <<(subscription)
      klass = subscription.announcement_class
      original_subs = @classes_and_subscriptions[klass]
      if original_subs.nil?
        @classes_and_subscriptions = @classes_and_subscriptions.dup
        @classes_and_subscriptions[klass] = [subscription]
      else
        @classes_and_subscriptions[klass] = original_subs + [subscription]
      end
    end

    def add_subscriptions(subscriptions)
      subscriptions.each do |each|
        self << each
      end
      return SubscriptionCollection.with_all(subscriptions)
    end

    def delete(subscription)
      if subscription.is_a? Array
        return delete_subscriptions(subscription)
      end
      klass = subscription.announcement_class
      return unless @classes_and_subscriptions[klass]
      new_subs = @classes_and_subscriptions[klass].dup.delete_if {|each| each == subscription}
      subscription.deactivate
      if new_subs.empty?
        @classes_and_subscriptions = @classes_and_subscriptions.dup.delete(klass)
      else
        @classes_and_subscriptions[klass] = new_subs
      end
    end

    def delete_subscriptions(subscriptions)
      subscriptions.each {|each| self.delete(each) }
    end
    
    def all_subscriptions
      result = SubscriptionCollection.new()
      @classes_and_subscriptions.values.each do |each|
        result.add_all each
      end
      return result
    end

    def subscriptions_for(anouncements)
      klasses = announcements.to_announcement_classes
      result = SubscriptionCollection.new
      @classes_and_subscriptions.each do |(k,v)|
        result.add_all(v) if klasses.include? k
      end
      return result
    end

    def subscriptions_matching(announcement)
      result = SubscriptionCollection.new
      @classes_and_subscriptions.each do |(k,v)|
        result.add_all(v) if announcement.is_a? k
      end
      return result
    end

    def subscriptions_of(object)
      result = SubscriptionCollection.new
      @classes_and_subscriptions.values.each do |subscriptions|
        subscriptions.each do |each|
          result << each if each.subscriber == object
        end
      end
      return result
    end

    def subscriptions_of_for(object, announcements)
      klasses = announcements.to_announcement_classes
      result = SubscriptionCollection.new
      @classes_and_subscriptions.each do |(k,v)|
        if klasses.include? k
          v.each do |each|
            result << each if each.subscriber = object
          end
        end
      end
      return result
    end
    
    def empty?
      @classes_and_subscriptions.empty? || @classes_and_subscriptions.all? {|(k,v)| v.nil? || v.empty?}
    end

    def any?
      unless block_given?
        return !empty?
      end
      @classes_and_subscriptions.each do |(k,v)|
        next if v.nil?
        return true if v.any? {|each| yield [k,each]}
      end
      return false
    end
    
    def deliver(announcement, announcer)
      @classes_and_subscriptions.each do |(k,v)|
        if announcement.is_a? k
          v.each do |each|
            each.process(announcement, announcer)
          end
        end
      end
    end
  end
end
