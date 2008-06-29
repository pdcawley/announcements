require 'set'
module Announcements #:nodoc:
  module Acts #:nodoc:
    module AsAnnouncer
      class WhenProxy #:nodoc:
        attr_accessor :announcer, :announcements
        def initialize(announcer, announcements)
          @announcer, @announcements = announcer, announcements
        end
        def send(message, destination) #:nodoc:
          announcer.send(:when_send_to, announcements, message, destination)
        end

        def for(subscriber, &block) #:nodoc:
          announcer.send(:when_send_for, announcements, subscriber, &block)
        end
      end
      
      def when(*announcements, &block)
        unless block_given?
          return WhenProxy.new(self, make_classes(announcements))
        end
        when_for(*(announcements + [eval('self', block)]), &block)
      end

      def unsubscribe(object)
        if registry = subscription_registry_or_nil
          registry.delete(registry.subscriptions_of(object))
        end
      end

      def unsubscribe_from(object, *announcements)
        announcements = announcements.to_announcement_classes
        if registry = subscription_registry_or_nil
          registry.delete(registry.subscriptions_of_for(object, announcements))
        end
      end
      
      def announce(announcement)
        announcement = announcement.to_announcement
        unless may_announce? announcement.class
          bad_announcement(announcement.class)
        end
        
        if registry = subscription_registry_or_nil
          registry.deliver announcement, self
        end
        return announcement
      end
      
      def subscription_registry
        subscription_registry_or_nil || (self.subscription_registry = create_subscription_registry)
      end

      def create_subscription_registry
        Announcements::SubscriptionRegistry.new
      end

      def bad_announcement(klass)
        exception = Exception.new
        exception.announcement_class = klass
        exception.receiver = self
        raise exception, "#{self.inspect} does not support announcement_class #{klass}", caller(1)
      end

      def may_announce? klass
        return true
      end

      def make_classes(*announcements)
        klasses = announcements.inject(Announcements::AnnouncementSet.new) do |acc, each|
          acc + each.to_announcement_classes
        end
        klasses.each do |each|
          unless self.may_announce? each
            bad_announcement each
          end
        end
        return klasses
      rescue NoMethodError
        raise TypeError, "#{announcements.inspect} contains some invalid classes"
      end
      
      protected
      
      def when_for(announcement, *rest, &block)
        subscriber = rest.pop
        klasses = make_classes(announcement, *rest)

        registry = subscription_registry
        registry.add_subscriptions(klasses.collect do |each|
                                     subscription = registry.create_subscription
                                     subscription.announcement_class = each
                                     subscription.block_subscriber(block, subscriber)
                                     subscription
                                   end)
      end

      def when_send_to(announcement, *rest)
        object = rest.pop
        selector = rest.pop
        klasses = make_classes(announcement, *rest)

        registry = subscription_registry
        registry.add_subscriptions(klasses.collect { |each|
                                     sub = registry.create_subscription
                                     sub.announcement_class = each
                                     sub.receiver_selector(object, selector)
                                     sub
                                   })
      end
      
    end
  end
  
  class Announcer
    include Acts::AsAnnouncer
    
    def release
      subscription_registry.release
      subscription_registry = nil
    end

    def dup
      copy = super
      subscription_registry = nil
    end

    def subscription_registry_or_nil
      @subscription_registry
    end

    def subscription_registry=(registry)
      @subscription_registry = registry
    end
  end
end
