module Announcements
  module Subscription
    class Base
      attr_accessor :key
      
      def initialize(key)
        @key = key.announcement_class
      end

      def for?(announcement_class_or_instance)
        klass = announcement_class_or_instance.announcement_class
        klass == @key
      end

      def of?(object)
        subscriber == object
      end

      def announce(announcement, announcer)
        if announcement.is_a? key
          make_announcement(announcement, announcer)
        end
      end

      protected
      def make_announcement(announcement, announcer)
        raise SubclassResponsibility
      end
    end

    class BlockHandler < Base
      def initialize(key, &block)
        super(key)
        @block = block
      end
      
      def subscriber
        @subscriber ||= eval('self', @block)
      end

      protected
      def make_announcement(announcement, announcer)
        @block.call(announcement, announcer)
      end
    end

    class MessageSender < Base
      attr_reader :subscriber
      
      def initialize(announcement, subscriber, method)
        super announcement
        @subscriber = subscriber
        @method = method
      end

      protected

      def make_announcement(announcement, announcer)
        subscriber.send(@method, announcement, announcer)
      end
    end
  end

  def self.Subscription(announcement, callable = nil, &block)
    case callable
    when nil
      Subscription::BlockHandler.new(announcement, &block)
    when Hash
      unless callable.size == 1
        raise Exception, "Too many keys"
      end
      Subscription::MessageSender.new(announcement, *callable.to_a.first)
    end
  end
end
