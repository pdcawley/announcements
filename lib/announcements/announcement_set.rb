require 'set'

module Announcements
  class AnnouncementSet < Set
    def to_announcement_classes
      self
    end
  end
end
