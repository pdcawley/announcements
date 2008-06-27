$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'announcements/announcement'
require 'announcements/announcer'
require 'announcements/subscription'

module Announcements
end
