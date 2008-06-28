module Announcements
  class DeliveryDestination
    attr_accessor :receiver, :selector

    def self.receiver_selector(receiver, selector)
      new.send(:initialize_attribs, receiver, selector)
    end

    def self.block(a_block)
      receiver_selector(a_block, :call)
    end

    def deliver(announcement, announcer, subscription)
      method = receiver.is_a?(Proc) ? receiver : receiver.method(selector)
      case method.arity
      when 0
        method.call
      when 1
        method.call(announcement)
      when 2
        method.call(announcement, announcer)
      else
        method.call(announcement, announcer, subscription)
      end
    end

    private

    def initialize_attribs(receiver, selector)
      @receiver = receiver
      @selector = selector
      return self
    end
  end
end
