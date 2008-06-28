$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'announcements/announcement'
require 'announcements/announcement_set'
require 'announcements/announcer'
require 'announcements/subscription'
require 'announcements/subscription_collection'
require 'announcements/support'
require 'announcements/delivery_destination'
require 'announcements/subscription_registry'

class SubclassResponsibility < RuntimeError
end

module Announcements
  class AnnouncementError < StandardError
  end

  class BadAnnnouncementClassError < StandardError
    attr_accessor :announcement_class, :receiver
  end
end
