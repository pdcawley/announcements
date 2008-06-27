require File.dirname(__FILE__) + '/spec_helper.rb'

Announcement = Announcements::Announcement
Announcer = Announcements::Announcer

describe Announcements::Subscription::Base do
  it "should exist" do
    Announcements::Subscription::Base.should be_instance_of(Class)
  end
end

describe Announcements::Subscription do
  it "should be a factory function" do
    Announcements::Subscription(Announcement) {true}.should be_kind_of(Announcements::Subscription::Base)
  end

  describe "(Announcement) { ... }" do
    it "#for? Annnouncement should be true" do
      Announcements::Subscription(Announcement) {true}.should be_for(Announcement)
    end

    it "#of? self should be true" do
      Announcements::Subscription(Announcement) {true}.should be_of(self)
    end

    it "announce(Announcement.new) should call the block" do
      called = false
      Announcements::Subscription(Announcement) { called = true }.announce(Announcement.new, :announcer)
      called.should be_true
    end
  end

  describe "(Announcement, obj => :got)" do
    before :each do
      @subscriber = mock(:subscriber)
      @subscription = Announcements::Subscription(Announcement, @subscriber => :handler)
    end
    
    it "should be a Subscriptions::MessageSender" do
      @subscription.should be_instance_of(Announcements::Subscription::MessageSender)
    end

    it "should be for Announcement" do
      @subscription.should be_for(Announcement)
    end

    it "should be of @subscriber" do
      @subscription.should be_of(@subscriber)
    end

    it "should raise an error with if the hash has more than 1 key" do
      lambda { Announcements::Subscription(Announcement, @subscriber => :handler, :foo => :bar) } \
        .should raise_error(Exception)
    end

    it "should raise an error if the hash has no keys" do
      lambda { Announcements::Subscription(Announcement, {}) } \
        .should raise_error(Exception)
    end

    it "#announce(Announcement.new) should send :handler to the subscriber" do
      announcement = Announcement.new
      @subscriber.should_receive(:handler).with(announcement, :sender)
      @subscription.announce(announcement, :sender)
    end
  end
end
