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

    def call(announcement, announcer)
      @seq.each do |each|
        case each.arity
        when 0
          each.call
        when 1
          each.call(announcement)
        else
          each.call(announcement, announcer)
        end
      end
    end

    def delete(context)
      @seq.delete_if {|each|
        action_context(each) == context
      }
    end

    private

    def action? callable
      callable.respond_to?(:call) && callable.respond_to?(:arity)
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

  def subscribe(announcement_class, callable = nil, &block)
    unless announcement_class.is_a?(Class) && announcement_class <= Announcement
      raise TypeError, "#{announcement_class.inspect} must be an Announcement"
    end

    @subscribers[announcement_class] << make_actions(callable || block)
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
        v.call(announcement, self)
      end
    end
  end

  private

  def make_actions(thing)
    if thing.is_a? Hash
      thing.collect {|(k,v)|
        method_sender(k,*v)
      }
    elsif thing.respond_to? :arity
      thing
    elsif thing.respond_to? :call
      method_sender(thing, :call)
    else
      raise TypeError, "Don't know how to turn #{thing} into an action"
    end
  end
  

  def method_sender(target, *method_names)
    arities = {}
    method_names.each do |each|
      arities[each] = target.method(each).arity
    end

    target.instance_eval {
      lambda {|announcement, announcer|
        method_names.each do |each|
          m = target.method(each)
          case m.arity
          when 0
            m.call()
          when 1
            m.call(announcement)
          else
            m.call(announcement, announcer)
          end
        end
      }
    }
  end
end
