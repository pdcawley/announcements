require 'set'
module Announcements #:nodoc:
  module Acts #:nodoc:
    
    # Acts::AsAnnouncer is the key module in the Announcements framework. This
    # is where you register interest in announcements handled by the
    # announcer. It's also the class that sends announcements. A class that
    # makes announcements might look something like:
    #
    #   class Formatter
    #     extend Acts::AsAnnouncer
    #
    #     def self.subscription_registry_or_nil
    #       @@subscription_registry
    #     end
    #
    #     def self.subscription_registry=(registry)
    #       @@subscription_registry = registry
    #     end
    #
    #     FormatterAnnouncement = Class.new Announcements::Announcement
    #
    #     class WillFormat < FormatterAnnouncement
    #       attr_accessor :source, :formatter
    #       def initialize(formatter, source)
    #         @source = source
    #       end
    #     end
    #
    #     class DidFormat < FormatterAnnouncement
    #       attr_accessor :source, :formatter
    #       attr_reader :output
    #
    #       def initialize(formatter, source, output)
    #         @source, @output = source, output
    #         @modified = false
    #       end
    #
    #       def modified?
    #         @modified
    #       end
    #
    #       def output=(modified_text)
    #         if modified_text != output
    #           @modified = true
    #           @output = modified_text
    #         end
    #         @output
    #       end
    #     end
    #
    #     def will_format(self, source)
    #       WillFormat.new(self, source)
    #     end
    #
    #     def did_format(source,output)
    #       DidFormat.new(source,output)
    #     end
    #
    #     def render(source)
    #       announce will_format(source)
    #       result = really_convert(source)
    #       notice = announce did_format(source, result)
    #       notice.modified? ? notice.output : result
    #     end
    #   end
    #
    # Let's say that we have a post processor which post process our results in
    # some way. We write:
    #
    #   Formatter.when(Formatter::DidFormat) do |notice, announcer|
    #     if announcer.is_a? HtmlFormatter
    #       notice.output = munge_html(notice.output)
    #     end
    #   end
    #
    # Or let's say we have an object to handle annnouncements:
    #
    #   Formatter.when(Formatter::DidFormat).send(:did_format, handler_object)
    #   Formatter.when(Formatter::WillFormat).send(:will_format, handler_object)
    #
    # == Motivation
    #
    # Using Announcements can seriously slim down a class's protocol. Instead
    # of defining a bunch of callbacks with varying signatures, it suffices to
    # define announcement classes with appropriate attributes and behaviours,
    # and to handle these appropriately. The announcement dispatch system
    # doesn't care what's in an announcement, so long as it implements a couple
    # of converting methods. The arguments that announce passes to each handler
    # are always the announcement, the announcer, and the subscription that's
    # handling the dispatch. Handlers can use these in whatever way they see
    # fit and, because the announcement itself is a full blown object, can
    # treat the announcement as a collecting parameter in order to communicate
    # between handlers or with the announcer.
    module AsAnnouncer
      class WhenProxy #:nodoc:
        attr_accessor :announcer, :announcements, :subscriber
        def initialize(announcer, announcements)
          @announcer, @announcements = announcer, announcements
        end
        def send(message, destination) #:nodoc:
          announcer.send(:when_send_to, announcements, message, destination)
        end

        def for(subscriber, &block) #:nodoc:
          if block_given?
            announcer.send(:when_for, announcements, subscriber, &block)
          else
            self.subscriber = subscriber
          end
        end
      end

      # Subscribes a handler to an announcement or set of announcements. The
      # handler can be specified in one of three ways:
      #
      # ===== with a block:
      #
      #   announcer.when(AnnouncementClass, AnotherAnnouncementClass ...) { ... }
      #
      # ===== with a message and target object
      #
      #   announcer.when(Announcement).send(:a_message, target_object)
      #
      # ===== with a block and a subscriber object other than +self+
      #
      #   announcer.when(...).for(subscriber) { ... }
      #
      # The subscriber object is used as the key for when unsubscribing from
      # an announcement. In the simple block case, the subscriber is the +self+
      # in the blocks's binding. In the +send+ case, it's the target object,
      # and in the +for+ case, it's the subscriber object.
      #
      # ==== Handler Signature
      #
      # The handler, whether a method or a block should take between 0 and
      # three arguments. In the three argument case, it gets called with:
      #
      # * +announcement+ - the announcement passed to +announce+
      # * +announcer+ - the object making the announcement
      # * +subscription+ - The Announcements::Subscription object that the handler
      #   was found in
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
end
module Announcements #:nodoc:
  # See Acts::AsAnnouncer for more details on this
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
