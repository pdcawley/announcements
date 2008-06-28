require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Announcements::Subscription::Base do
  it "should exist" do
    Announcements::Subscription::Base.should be_instance_of(Class)
  end

  describe "Announcements::Subscription::Base.new(AnnouncementMockA)" do
    before :each do
      @sub = Announcements::Subscription::Base.new(AnnouncementMockA)
    end
    
    it ".send(:make_announcement, :announcement, :announcer) should raise SubclassResponsibility" do
      lambda { @sub.send :make_announcement, :announcement, :announcer } \
        .should raise_error(SubclassResponsibility)
    end

    it "announce(AnnouncementMockA.new, :announcer should call :make_announcement" do
      announcement = AnnouncementMockA.new
      @sub.should_receive(:make_announcement).with(announcement, :announcer)
      @sub.announce(announcement, :announcer)
    end

    it "announce(Announcement.new, :announcer) should not call :make_announcement" do
      @sub.should_receive(:make_announcement).exactly(0).times
      @sub.announce(Announcement.new, :announcer)
    end
  end
end

describe Announcements::Subscription do
  it "should be a factory function" do
    Announcements::Subscription(Announcement) {true}.should \
      be_instance_of(Announcements::Subscription::BlockHandler)
    Announcements::Subscription(Announcement, :object => :method_name).should \
      be_instance_of(Announcements::Subscription::MessageSender)
  end
  
  it "announce should not do anything if the announcement is 'wrong'" do
    called = false
    sub = Announcements::Subscription(AnnouncementMockA) { called = true }
    sub.announce(Announcement.new, :announcer)
    called.should be_false
  end
end

describe Announcements::Subscription::BlockHandler do
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

describe Announcements::Subscription::MessageSender do 
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
