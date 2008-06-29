class Array
  def to_announcement_classes
    Announcements::AnnouncementSet.new(self)
  end
end

class Object
  def to_announcement
    raise TypeError, "#{self.inspect} cannot be coerced into an announcement"
  end
  
  def subscription_registry=(registry)
    raise "This message is not appropriate for this object"
  end

  def subscription_registry_or_nil
    nil
  end
end
