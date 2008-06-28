module Announcements
  class Subscription
    attr_accessor :registry, :destination, :subscriber, :announcement_class
    
    def self.for_registry(registry)
      instance = new
      instance.registry = registry
      return instance
    end

    def block(&block)
      block_subscriber(block, eval('self', block))
    end

    def block_subscriber(block, subscriber)
      self.destination = DeliveryDestination.block(block)
      self.subscriber = subscriber
    end

    def matches_announcement?(announcement)
      announcement.is_a? announcement_class
    end

    def add_destination_override(a_destination)
      (@destination_overrides ||= []) << a_destination
    end

    def remove_destination_override(a_destination)
      return unless @destination_overrides
      @destination_overrides.delete(a_destination)
      @destination_overrides = nil if @destination_overrides.empty?
    end

    def process(announcement, announcer)
      if @destination_overrides
        @destination_overrides.each do |each|
          each.deliver(announcement, announcer, self)
        end
      else
        destination.deliver(announcement, announcer, self)
      end
    end
  end
end
