require File.dirname(__FILE__) + '/../spec_helper.rb'

class ReceiverMock
  attr_accessor :last_invocation

  def handler0
    self.last_invocation = []
  end

  def handler1(announcement)
    self.last_invocation = [announcement]
  end

  def handler2(announcement, announcer)
    self.last_invocation = [announcement, announcer]
  end

  def handler3(announcement, announcer, subscription)
    self.last_invocation = [announcement, announcer, subscription]
  end
end

describe Announcements::DeliveryDestination do
  it "should be instantiable" do
    proc {Announcements::DeliveryDestination.new}.should_not raise_error
  end

  describe ".block(block)" do
    before :each do
      @block = lambda {true}
      @destination = Announcements::DeliveryDestination.block(@block)
    end

    it "should have @block as a the receiver" do
      @destination.receiver.should == @block
    end

    it "should have :call as the selector" do
      @destination.selector.should == :call
    end
  end

  describe ".receiver_selector(:receiver, :selector)" do
    # receiver: anObject selector: aSymbol => Smalltalk FTW
    before :each do
      @destination = Announcements::DeliveryDestination.receiver_selector(:receiver, :selector)
    end

    it ".receiver should be :receiver" do
      @destination.receiver.should == :receiver
    end
    
    it ".selector should be :selector" do
      @destination.selector.should == :selector
    end
  end

  describe "an instance" do
    before :each do
      @destination = Announcements::DeliveryDestination.new
    end

    it "should have a receiver" do
      proc do
        @destination.receiver = :receiver
        @destination.receiver.should == :receiver
      end.should_not raise_error
    end

    it "should have a selector" do
      proc do
        @destination.selector = :selector
        @destination.selector.should == :selector
      end.should_not raise_error
    end
  end

  describe "an instance with a 0 argument target" do
    it ".deliver(:announcement, :announcer, :subscription) should send no arguments" do
      receiver = ReceiverMock.new
      ann = Announcements::DeliveryDestination.receiver_selector(receiver, :handler0)
      ann.deliver(:announcement, :announcer, :subscription)
      receiver.last_invocation.should == []
    end
  end

  describe "an instance with a 2 argument target" do
    it ".deliver(:announcement, :announcer, :subscription) should send the selector with :announcement, :announcer" do
      receiver = ReceiverMock.new
      ann = Announcements::DeliveryDestination.receiver_selector(receiver, :handler2)
      ann.deliver(:announcement, :announcer, :subscription)
      receiver.last_invocation.should == [:announcement, :announcer]
    end
  end
  
  describe "an instance with a 3 argument target" do
    it ".deliver(:announcement, :announcer, :subscription) should send the selector with :announcement, :announcer, :subscription" do
      receiver = ReceiverMock.new
      ann = Announcements::DeliveryDestination.receiver_selector(receiver, :handler3)
      ann.deliver(:announcement, :announcer, :subscription)
      receiver.last_invocation.should == [:announcement, :announcer, :subscription]
    end
  end

  describe "an instance with a 0 argument block" do
    it "should be called with no arguments" do 
      called = false
      ann = Announcements::DeliveryDestination.block(lambda {called = true})
      ann.deliver(:announcement, :announcer, :subscription)
      called.should == true
    end
  end

  describe "an instance with a 1 argument block" do
    it "should be called with :announcement" do
      called = nil
      ann = Announcements::DeliveryDestination.block(lambda {|a| called = [a]})
      ann.deliver(:announcement, :announcer, :subscription)
      called.should == [:announcement]
    end
  end  
  
    describe "an instance with a 2 argument block" do
    it "should be called with :announcement, :announcer" do
      called = nil
      ann = Announcements::DeliveryDestination.block(lambda {|a,b| called = [a,b]})
      ann.deliver(:announcement, :announcer, :subscription)
      called.should == [:announcement, :announcer]
    end
  end  
  
    describe "an instance with a 3 argument block" do
    it "should be called with :announcement, :announcer, :subscription" do
      called = nil
      ann = Announcements::DeliveryDestination.block(lambda {|a,b,c| called = [a,b,c]})
      ann.deliver(:announcement, :announcer, :subscription)
      called.should == [:announcement, :announcer, :subscription]
    end
  end  
end

