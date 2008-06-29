= announcements

http://www.bofh.org.uk/articles/tag/announcementsproject

== DESCRIPTION:

A port of Vassily Bykov's Smalltalk Announcements framework. Think of it as
Observer/Observable on steroids.

== FEATURES/PROBLEMS:

=== Problems first

This is very much a first cut. Testing is sparse because this is mostly a direct port
from a Smalltalk package that's pretty much test free. The API also a pretty
much straight port of the Smalltalk and isn't what could be called idiomatic
Ruby just yet.

=== Features

* Announcements are objects and can carry all the information a subscriber will need.
* Small, uniform interface for subscription

== SYNOPSIS:

  class ObservableValue
    include Announcements
    class ChangeAnnouncement < Announcements::Anouncement
      attr_accessor :from, :to

      def initialize(from, to)
        @from, @to = from, to
      end

      def inspect
        self.class.to_s.gsub(/([a-z])(A-Z)/) { $1 + ' ' + $2}.downcase << 
          " from #{@from.inspect} to #{@to.inspect}"
      end
    end

    class ValueWillChange <  ChangeAnnouncement
      def veto!
        @vetoed = true
      end

      def vetoed?
        @vetoed
      end
    end

    class ValueChanging < ChangeAnnouncement; end
    class ValueChanged < ChangeAnnouncement; end

    def self.announcer
      @@announcer ||= Announcements::Announcer.new
    end

    def announce(*args)
      self.class.announcer.announce(*args)
    end

    def value=(new_value) 
      unless announce(ValueWillChange.new(@value, new_value)).vetoed?
        announce(ValueChanging.new(@value, new_value)
        change_complete = ValueChanged.new(@value, new_value)
        @value = new_value
        announce(change_complete)
    end
  end

  # Spy on all the changes

  ObservableValue.watch(ObservableValue::ChangeAnnouncement) do |notice, sender|
    puts "#{announcer.inspect} #{announcement.inspect}"
  end

  # Remember changes for undoing

  ObservableValue.watch(ObservableValue::ValueChanged) do |notice, sender|
    command_history << UndoableCommand.new(sender, notice.from, notice.to)
  end

== REQUIREMENTS:

* Rspec, but only if you want to run the tests
* Er...
* That's it

== INSTALL:

  sudo gem install announcements

== COPYRIGHT:

Copyright (c) 2008 Piers Cawley

This library is free software; you can redistribute it and/or modify it under
the saem terms as Ruby itself.

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
