require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Announcements::SubscriptionRegistry do
  SubscriptionRegistry = Announcements::SubscriptionRegistry
  Subscription = Announcements::Subscription

  def target
    @target ||= mock(:target, :null_class => true)
  end

  describe "class methods" do
    it "should be instantiable" do
      proc do
        SubscriptionRegistry.new.should be_instance_of SubscriptionRegistry
      end.should_not raise_error
    end
  end

  describe "instance methods" do
    describe '#<< subscription' do
      before :each do
        @registry = SubscriptionRegistry.new
        @subscription = Subscription.for_registry(@registry)
        @subscription.announcement_class = AnnouncementMockA
        @subscription.receiver_selector(target, :handler)
      end
      
      it "should succeed" do
        proc do
          @registry << @subscription
        end.should_not raise_error
      end
    end

    describe '#add_subscriptions subscriptions' do
      it "should succeed" do
        subs = Subscription.new(AnnouncementMockA) << Subscription.new(AnnouncementMockB)
        registry = SubscriptionRegistry.new
        proc do
          registry.add_subscriptions subs
        end.should_not raise_error
      end

    end
  end
end
