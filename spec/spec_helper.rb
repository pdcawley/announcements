begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'announcements'

Announcement = Announcements::Announcement
Announcer = Announcements::Announcer

class AnnouncementMockA < Announcement
  def AnnouncementMockA
  end
end

class AnnouncementMockB < Announcement
  def AnnouncementMockB
  end
end

class AnnouncementMockC < Announcement
  def AnnouncementMockC
  end
end

class AnnouncementMockD < Announcement
  def AnnouncementMockD
  end
end

class Announcement
  def Announcement
    # stub method for duck typing...
  end
end

