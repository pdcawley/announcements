require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Announcements::SubscriptionCollection do
  SubscriptionCollection = Announcements::SubscriptionCollection

  describe ".with_all(collection)" do
    it "should make a SubscriptionCollection" do
      SubscriptionCollection.with_all([]).should be_instance_of(SubscriptionCollection)
    end
  end
end

describe 'an Announcements::SubscriptionCollection instance' do
  SubscriptionCollection = Announcements::SubscriptionCollection
  
  describe '#deliver(announcement, announcer)' do
    it "Should deliver to each of its member subscriptions that match the announcement" do
      collection = (1..2).collect do |each|
        sub = mock("matching_sub#{each}")
        sub.should_receive(:matches_announcement?).with(:announcement).and_return(true);
        sub.should_receive(:process).with(:announcement, :announcer)
        sub
      end

      collection += (1..2).collect do |each|
        sub = mock("irrelevant_sub#{each}")
        sub.should_receive(:matches_announcement?).with(:announcement).and_return(false);
        sub.should_receive(:process).exactly(0).times
        sub
      end

      subs = SubscriptionCollection.new(collection)
      subs.deliver(:announcement, :announcer)
    end
  end
  
  it "intercepting_with(a_block) test" do
    target = mock :target
    target.should_receive(:intercepted)
    sub = Announcements::Subscription.for_registry(:registry)
    sub.announcement_class = Announcement
    sub.block {true}
    
    coll = SubscriptionCollection.new([sub])
    coll.intercepting_with(lambda { target.intercepted }) do
      coll.deliver(Announcement.new, :announcer)
    end
  end

  it "while_suspended test" do
    target = mock :target
    target.should_receive(:triggered).exactly(0).times
    sub = Announcements::Subscription.for_registry(:registry)
    sub.announcement_class = Announcement
    sub.block {target.triggered}
    
    coll = SubscriptionCollection.new([sub])
    coll.while_suspended do
      coll.deliver(Announcement.new, :announcer)
    end
    
  end
end
