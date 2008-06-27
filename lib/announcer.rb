require 'set'

class Announcer
  class ActionSequence
    def initialize
      @seq = Set.new
    end

    def << action
      if action.is_a? Array
        action.each do |each|
          self << each
        end
      else
        action?(action) or raise TypeError, "#{callable.inspect} must be callable or respond to to_proc"
        @seq << action
      end
    end

    def call(*args)
      @seq.each {|each| each.respond_to?(:call) ? each.call(*args) : each.to_proc.call(*args) }
    end

    def delete(context)
      @seq.delete_if {|each|
        action_context(each) == context
      }
    end

    private

    def action? callable
      callable.respond_to?(:call) || callable.respond_to?(:to_proc)
    end

    def action_context(action)
      if action.respond_to? :binding
        eval 'self', action.binding
      else
        action
      end
    end
  end
  attr_accessor :subscribers

  def initialize
    @subscribers = Hash.new {|h,k| h[k] = ActionSequence.new}
  end

  def subscribe(announcement_class, callable = nil)
    unless announcement_class.is_a?(Class) && announcement_class <= Announcement
      raise TypeError, "#{announcement_class.inspect} must be an Announcement"
    end

    @subscribers[announcement_class] << make_actions(callable || proc {|ann| yield ann})
  end

  def unsubscribe(context)
    @subscribers.each_value do |each|
      each.delete context
    end
  end

  def announce(announcement)
    target_key = announcement.is_a?(Class) ? announcement : announcement.class
    unless target_key <= Announcement
      raise TypeError, "#{target_key.inspect} is not a kind of Announcement"
    end
    subscribers.each do |(k,v)|
      if target_key <= k
        v.call(announcement)
      end
    end
  end

  private

  def make_actions(thing)
    case thing
    when Hash
      thing.collect {|(k,v)|
        method_sender(k,v)
      }
    else
      thing
    end
  end

  def method_sender(target, method)
    target.instance_eval {
      lambda {|announcement| [*method].each {|each| self.send(each, announcement)}}
    }
  end
end
