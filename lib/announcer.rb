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

  def subscribe(*args, &block)
    unless block_given?
      callable = args.pop
    end

    args.each do |each|
      unless each.is_a?(Class) && each <= Announcement 
        raise TypeError, "#{each.inspect} must be an Announcement"
      end
    end
    
    args.each do |each|
      @subscribers[each] << make_actions(callable || block)
    end
  end

  def unsubscribe(context)
    @subscribers.each_value do |each|
      each.delete context
    end
  end

  def unsubscribe_from(*args)
    context = args.pop

    args.each do |each|
      @subscribers[each.to_announcement.class].delete(context)
    end
  end
  
  def announce(announcement)
    unless announcement.respond_to? :to_announcement
      raise TypeError, "#{announcement.inspect} must respond to \#to_announcement"
    end
    announcement = announcement.to_announcement

    subscribers.each do |(k,v)|
      if announcement.is_a?(k)
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
