module Announcements
  class SubscriptionCollection
    include Enumerable
    
    def self.with_all(collection)
      new collection.to_a.dup
    end

    def deliver(announcement, announcer)
      each do |each|
        if each.matches_announcement? announcement
          each.process(announcement, announcer)
        end
      end
    end

    def intercepting_with(interceptor_block)
      interceptor = DeliveryDestination.block(interceptor_block)
      each do |each|
        each.add_destination_override interceptor
      end
      begin
        yield
      ensure
        each do |each|
          each.remove_destination_override interceptor
        end
      end
    end

    def while_suspended(missed_handler = nil)
      missed_some = false
      blocker = missed_handler \
                  ? DeliveryDestination.block(proc {missed_some = true}) \
                  : DeliveryDestination.bitbucket
      
      each do |each|
        each.add_destination_override blocker
      end
      
      begin
        yield
      ensure
        each do |each|
          each.remove_destination_override blocker
        end
        if missed_some
          missed_handler.call
        end
      end
    end
    
    def each
      @array.each {|each| yield each }
    end
    
    def initialize(array = [])
      @array = array
    end

    def to_a
      @array
    end

    alias_method :to_ary, :to_a

    def +(other_collection)
      self.class.new(@array + other_collection)
    end

    def add_all(other_collection)
      @array += other_collection.to_ary
    end

    def << subscription
      @array << subscription
    end
  end
end
