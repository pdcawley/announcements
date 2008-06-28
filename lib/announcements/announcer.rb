require 'set'
module Announcements
  class Announcer
    def release
      subscription_registry.release
      subscription_registry = nil
    end

    def dup
      copy = super
      subscription_registry = nil
    end

    def subscription_registry_or_nil
      @subscription_registry
    end

    def subscription_registry=(registry)
      @subscription_registry = registry
    end
  end
end
