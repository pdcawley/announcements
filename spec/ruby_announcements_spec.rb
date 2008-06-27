require File.dirname(__FILE__) + '/spec_helper.rb'
require 'announcer'
require 'announcement'

# Time to add your specs!
# http://rspec.info/
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

  it "should allow subscription with a hash" do
    subscriber1 = mock(:subscriber1)
    subscriber2 = mock(:subscriber2)
    subscriber1.should_receive(:methodA).with(duck_type(:Announcement), announcer)
    subscriber2.should_receive(:methodB).with(duck_type(:Announcement), announcer)
    subscriber2.should_receive(:methodA).with(duck_type(:Announcement), announcer)

    announcer.subscribe(Announcement, subscriber1 => :methodA, subscriber2 => [:methodA, :methodB])
    announcer.announce Announcement
  end

  it "should allow subscription to multiple announcements" do
    target.should_receive(:got).exactly(2).times
    announcer.subscribe(AnnouncementMockA, AnnouncementMockB) {|a| target.got(:a)}
    announcer.announce AnnouncementMockA
    announcer.announce AnnouncementMockB
  end

  describe 'subscribing with a callable object' do
    it "should accept a lambda" do
      target.should_receive(:got_announcement).with(duck_type(:Announcement))
      announcer.subscribe Announcement, lambda {|a| target.got_announcement(a) }
      announcer.announce Announcement
    end

    it "should accept an object that responds to call" do
      callable = mock(:callable)
      callable.should_receive(:call).with(duck_type(:Announcement), announcer)
      announcer.subscribe Announcement, callable
      announcer.announce Announcement
    end
  end

  describe 'when subscribing with a block' do
    it "should accept a block" do
      announcer.subscribe AnnouncementMockA do |the_announcement|
        # stuff
      end
    end

    it "should only accept an announcement class as an argument" do
      lambda { announcer.subscribe(Object) {|| true} }.should raise_error( TypeError )
    end

    it "should not accept an announcement instance" do
      lambda { announcer.subscribe(AnnouncementMockA.new) {|| true} }.should raise_error( TypeError )
    end
  end

  it "announcing a subclass should perform any actions subscribed to a superclass" do
    seen = []

    announcer.subscribe Announcement do |ann|
      seen << ann
    end
    
    announcer.announce AnnouncementMockA
    announcer.announce AnnouncementMockB

    seen.collect {|each| each.class}.should == [AnnouncementMockA, AnnouncementMockB]
  end

  describe "with a subscription to AnnouncementMockA" do
    before :each do
      announcer.subscribe AnnouncementMockA do |the_announcement, the_announcer|
        target.got_announcement(the_announcement, the_announcer)
      end
    end

    it "#unsubscribe self should unsubscribe everything I subscribed with" do
      target.should_receive(:got_announcement).exactly(0).times
      announcer.unsubscribe self
      announcer.announce Announcement
    end
    
    it "#announce AnnouncementMockA should call the block" do
      target.should_receive(:got_announcement).with(duck_type(:AnnouncementMockA), announcer)
      
      announcer.announce AnnouncementMockA
    end

    it "#announce AnnouncementMockA.new should call the block" do
      ann = AnnouncementMockA.new
      
      target.should_receive(:got_announcement).with(ann, announcer)

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

  describe "when subscribing with 'subscribe Announcement, an_object => :method and announcing Announcement" do
    before :each do
      @obj = Class.new do |kls|
        @@method_calls = []

        def handler(announcement)
          @@method_calls << [:handler, announcement]
        end

        def method_calls
          @@method_calls
        end
      end.new
      announcer.subscribe Announcement, @obj => :handler
    end

    it "#announce should send(:method, an_announcement) to an_object" do
      announcer.announce Announcement
      @obj.method_calls.should have(1).item
      @obj.method_calls.first[0].should == :handler
      @obj.method_calls.first[1].should be_instance_of(Announcement)
    end

    it "#unsubscribe an_object should do the obvious thing" do
      announcer.unsubscribe @obj
      announcer.announce Announcement
      @obj.method_calls.should be_empty
    end
  end

  describe "With subscriptions to AnnouncementMockA and AnnouncementMockB and announcing both" do
    before :each do
      announcer.subscribe(AnnouncementMockA) {target.got_mock_a}
      announcer.subscribe(AnnouncementMockB) {target.got_mock_b}
    end

    after :each do
      announcer.announce(AnnouncementMockA)
      announcer.announce(AnnouncementMockB)
    end

    it "should fire both subscriptions" do
      target.should_receive(:got_mock_a)
      target.should_receive(:got_mock_b)
    end

    it "#unsubscribe_from(AnnouncementMockA, self) should remove the AnnouncementMockA handler" do
      target.should_receive(:got_mock_a).exactly(0).times
      target.should_receive(:got_mock_b)
      announcer.unsubscribe_from(AnnouncementMockA, self)
    end

    it "#unsubscribe_from(AnnouncementMockA, AnnouncementMockB) should remove both handlers" do
      target.should_receive(:got_mock_a).exactly(0).times
      target.should_receive(:got_mock_b).exactly(0).times
      announcer.unsubscribe_from(AnnouncementMockA, AnnouncementMockB, self)
    end
  end

  describe "#announce" do
    it "should call #to_announcement on the announcement object" do
      a = mock(:announcer)
      a.should_receive(:to_announcement).and_return(a)

      announcer.announce(a)
    end

    it "should return the announcement object" do
      a = mock(:announcer, :null_object => true)
      a.stub!(:to_announcement).and_return(a)

      announcer.announce(a).should be(a)
    end

  end
end
