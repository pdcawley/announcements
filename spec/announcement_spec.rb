require File.dirname(__FILE__) + '/spec_helper.rb'

describe Announcement do
  it "should respond to .to_announcement by returning an instance" do
    Announcement.to_announcement.should be_instance_of(Announcement)
  end
end

describe "An announcement" do
  it "should respond to #to_announcement by returning itself" do
    a = Announcement.new
    a.to_announcement.should be(a)
  end

  it "should not be vetoed to begin with" do
    Announcement.new.should_not be_vetoed
  end

  it "should respond to #veto" do
    a = Announcement.new
    a.veto.should be_true
    a.should be_vetoed
  end
end
