module Announcements
  class Announcement
    def self.to_announcement
      self.new
    end

    def self.announcement_class
      self
    end

    def self.to_announcement_classes
      [self]
    end

    def self.<<(an_announcement_class)
      AnnouncementSet.new([self, an_announcement_class])
    end
    
    @@subclasses = {}
    
    def self.inherited(child)
      (@@subclasses[self] ||= []) << child
      super
    end

    def self.subclasses
      @@subclasses[self] || []
    end

    def self.with_subclasses
      AnnouncementSet.new([self]) + subclasses
    end

    def to_announcement
      self
    end

    def announcement_class
      self.class
    end

    def veto
      @vetoed = true
    end

    def vetoed?
      @vetoed
    end
  end
end
