# frozen_string_literal: true

module Rack
  class Throttler
    # Throttle describes a throttling rule
    class Throttle
      MANDATORY_OPTIONS = %i[pattern method limit period].freeze

      attr_reader :limit, :period

      def initialize(options = {})
        MANDATORY_OPTIONS.each do |option|
          raise ArgumentError, "#{option} must be provided" unless options[option]
        end
        @pattern = options[:pattern]
        @method  = options[:method].upcase
        @limit   = options[:limit]
        @period  = options[:period]
      end

      ##
      # Determines whether a path/method pair match this throttle
      def match?(path, method)
        !(@pattern =~ path).nil? && @method == method.upcase
      end

      ##
      # Performs the throttling logic using the current throttling rule.
      def enforce_request(client)
        key = identifier(client)
        current_time = Time.now.to_f
        start_time = current_time - @period

        # Record the request in the tracking store. If not successful, throttle the request.
        if store.track(key, start_time, current_time, @limit)
          Rack::Throttler::Result.new
        else
          time_diff = current_time - store.earliest(key, start_time)
          retry_time = @period - time_diff
          Rack::Throttler::Result.new(allow: false, retry_interval: retry_time)
        end
      end

      private

      ##
      # A unique identifier for the client/throttling rule pair
      # used by the tracking store
      def identifier(client)
        "#{client}|#{@method}|#{@pattern.inspect}"
      end

      ##
      # Helper method to retrieve the tracking store
      def store
        Rack::Throttler.store
      end
    end
  end
end
