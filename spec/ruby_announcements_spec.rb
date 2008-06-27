require File.dirname(__FILE__) + '/spec_helper.rb'
require 'announcer'
require 'announcement'

# Time to add your specs!
# http://rspec.info/
class AnnouncementMockA < Announcement
end

class AnnouncementMockB < Announcement
end

class AnnouncementMockC < Announcement
end

class AnnouncementMockD < Announcement
end

describe Announcer do
  it "should be instantiatable" do
    Announcer.new.should_not be_nil
  end

  def announcer
    @announcer ||= Announcer.new
  end
  
  def target
    @target ||= mock(:target)
  end


  describe 'subscribing with a callable object' do
    it "should accept a lambda" do
      target.should_receive(:got_announcement).with(Announcement)
      announcer.subscribe Announcement, lambda {|a| target.got_announcement(a) }
      announcer.announce Announcement
    end

    it "should accept an object that responds to call" do
      callable = mock(:callable)
      callable.should_receive(:call).with(Announcement)
      announcer.subscribe Announcement, callable
      announcer.announce Announcement
    end

    it "should accept an object that responds to to_proc" do
      # Need to pull the target into scope for the class definition
      the_target = target
      the_target.should_receive(:got_announcement).with(Announcement)
      
      k = Class.new do |klass|
        @@target = the_target
        def to_proc
          lambda {|a| @@target.got_announcement a}
        end
      end

      announcer.subscribe Announcement, k.new
      announcer.announce(Announcement)
    end
  end

  describe 'when subscribing with a block' do
    it "should accept a block" do
      announcer.subscribe AnnouncementMockA do |the_announcement|
        # stuff
      end
    end

    it "should only accept an announcement class as an argument" do
      lambda { announcer.subscribe(Object) {} }.should raise_error( TypeError )
    end

    it "should not accept an announcement instance" do
      lambda { announcer.subscribe(AnnouncementMockA.new) {} }.should raise_error( TypeError )
    end
  end

  it "announcing a subclass should perform any actions subscribed to a superclass" do
    seen = []

    announcer.subscribe Announcement do |ann|
      seen << ann
    end
    
    announcer.announce AnnouncementMockA
    announcer.announce AnnouncementMockB

    seen.should == [AnnouncementMockA, AnnouncementMockB]
    
  end

  describe "with a subscription to AnnouncementMockA" do
    before :each do
      announcer.subscribe AnnouncementMockA do |the_announcement|
        target.got_announcement(the_announcement)
      end
    end

    it "#unsubscribe self should unsubscribe everything I subscribed with" do
      target.should_receive(:got_announcement).exactly(0).times
      announcer.unsubscribe self
      announcer.announce Announcement
    end
    
    it "#announce AnnouncementMockA should call the block" do
      target.should_receive(:got_announcement).with(AnnouncementMockA)
      
      announcer.announce AnnouncementMockA
    end

    it "#announce AnnouncementMockA.new should call the block" do
      ann = AnnouncementMockA.new
      
      target.should_receive(:got_announcement).with(ann)

      announcer.announce(ann)
    end

    it '#announce AnnouncementMockB should not call the block' do
      target.should_receive(:got_announcement).exactly(0).times

      announcer.announce AnnouncementMockB
    end

    it '#announce Announcement should not call the block' do
      target.should_receive(:got_announcement).exactly(0).times
      
      announcer.announce Announcement
    end
    
    it '#announce(not_a_child_of_Announcement) should raise TypeError' do
      target.should_receive(:got_announcement).exactly(0).times
      
      lambda { announcer.announce Object }.should raise_error(TypeError)
    end
  end
  
  describe "With a callable object subscribed" do
    before :each do
      @obj = mock(:callable)
      @obj.stub!(:call)
      announcer.subscribe Announcement, @obj
    end
    
    it "#unsubscribe the_object should remove the object" do
      @obj.should_receive(:call).exactly(0).times

      announcer.unsubscribe @obj
      announcer.announce Announcement
    end
  end

#   describe "when subscribing with 'subscribe Announcement, an_object => :method" do
#     before :each do
#       @obj = mock(:subscriber)
#       @obj.stub!(:method)
#       announcer.subscribe Announcement, @obj => :method
#     end
    
#     it "#announce should send(:method, Announcement) to an_object" do
#       @obj.should_receive(:method).with(Announcement)
#     end
#   end
end
