class Object
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

  def subscription_registry
    unless subscription_registry_or_nil
      self.subscription_registry = create_subscription_registry
    end
  end
  
  def subscription_registry=(registry)
    raise "This message is not appropriate for this object"
  end

  def subscription_registry_or_nil
    nil
  end

  def unsubscribe(object)
    if registry = subscription_registry_or_nil
      registry.delete(registry.subscriptions_of(object))
    end
  end

  def unsubscribe_from(object, announcement, *rest)
    announcements = announcement.to_announcement_classes.add(rest)
    if registry = subscription_registry_or_nil
      registry.delete(registry.subscriptions_of_for(object, announcements))
    end
  end
  
  def when(announcement, &block)
    when_for(announcement, eval('self', block), &block)
  end

  def when_for(announcement, *rest, &block)
    subscriber = rest.pop
    klasses = announcement.to_announcement_classes + rest.collect {|each| each.to_announcement.class}
    klasses.each do |each|
      unless self.may_announce? each
        bad_announcement each
      end
    end

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
    klasses = announcement.to_announcement_classes + rest.collect {|each| each.to_announcement.class}

    klasses.each do |each|
      unless may_announce? each
        bad_announcement each
      end
    end

    registry = subscription_registry
    registry.add_subscriptions(klasses.collect { |each|
                                 sub = registry.create_subscription
                                 sub.announcement_class = each
                                 sub.receiver_selector(object, selector)
                                 sub
                               })
  end
end
