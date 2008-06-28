require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Announcements::Subscription do
  Subscription = Announcements::Subscription

  it ".for_registry(registry) should make a subscription" do
    proc do
      Subscription.for_registry(mock(:registry, :null_object => true)).should be_instance_of Subscription
    end.should_not raise_error
  end
end

describe "an instance of Announcements::Subscription" do
  Subscription = Announcements::Subscription

  before :each do
    @registry = mock(:registry, :null_object => true)
    @subscription = Subscription.for_registry(@registry)
    @subscription.announcement_class = AnnouncementMockA
  end

  describe "#block" do
    it "should make a DeliveryDestination using block and set :destination to it" do
      Announcements::DeliveryDestination.should_receive(:block).and_return(:destination)
      @subscription.block {true}
      @subscription.destination.should == :destination
    end

    it "should set the subscriber to the block's 'self'" do
      @subscription.block {true}
      @subscription.subscriber.should == self
    end
  end

  describe "#block_subscriber(block, subscriber)" do
    it "should make a DeliveryDestination using the block and set :destination to it" do
      Announcements::DeliveryDestination.should_receive(:block).with(:block).and_return(:destination)
      @subscription.block_subscriber(:block, :subscriber)
      @subscription.destination.should == :destination
    end

    it "should set the subscriber" do
      @subscription.block_subscriber(lambda {true}, :subscriber)
      @subscription.subscriber.should == :subscriber
    end
  end

  describe '#matches_announcement?, when announcement_class is AnnouncementMockA' do
    it "should match AnnouncementMockA.new" do
      @subscription.matches_announcement?(AnnouncementMockA.new).should be_true
    end

    it "should not match AnnouncementMockB.new" do 
      @subscription.matches_announcement?(AnnouncementMockB.new).should_not be_true
    end

    it "should not match Announcement.new" do
      @subscription.matches_announcement?(Announcement.new).should_not be_true
    end
  end
  
  describe '#matches_announcement?, when announcement_class is Announcement' do
    before :each do
      @subscription.announcement_class = Announcement
    end
    
    it "should match AnnouncementMockA.new" do
      @subscription.matches_announcement?(AnnouncementMockA.new).should be_true
    end

    it "should match AnnouncementMockB.new" do 
      @subscription.matches_announcement?(AnnouncementMockB.new).should be_true
    end

    it "should match Announcement.new" do
      @subscription.matches_announcement?(Announcement.new).should be_true
    end
  end
  
  describe '#process(announcement, announcer)' do
    it "should send process(announcement, announcer, @subscription) to destination" do
      @subscription.destination.should_receive(:deliver).with(:announcement, :announcer, @subscription)
      @subscription.process(:announcement, :announcer)
    end
  end

  describe 'destination overrides' do
    it "adding a single override should override the base destination, delivering to the override instead" do
      override = mock(:override)
      override.should_receive(:deliver).with(:announcement, :announcer, @subscription)
      @subscription.destination.should_receive(:deliver).exactly(0).times
      
      @subscription.add_destination_override(override).should == [override]
      @subscription.process(:announcement, :announcer)
    end

    it "removing any overrides will see the original destination reinstated" do
      override = mock(:override)
      override.should_receive(:deliver).exactly(0).times
      @subscription.destination.should_receive(:deliver).with(:announcement, :announcer, @subscription)

      @subscription.add_destination_override(override)
      @subscription.remove_destination_override(override)
      @subscription.process(:announcement, :announcer)
    end

    it "multiple destination overrides will all get deliveries" do
      override1 = mock(:override1)
      override1.should_receive(:deliver)
      override2 = mock(:override2)
      override2.should_receive(:deliver)

      @subscription.add_destination_override(override1)
      @subscription.add_destination_override(override2)
      @subscription.process(:announcement, :announcer)
    end
  end
end
