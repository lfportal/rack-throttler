# frozen_string_literal: true

require 'redis'
require 'securerandom'

module Rack
  class Throttler
    # The tracking store used to track client requests
    class Store
      def initialize
        @store = Redis.new
        @sha_script = @store.script(:load, script)
      end

      ##
      # Perform count and add operations atomically for thread safety (refer to script description)
      def track(key, start_time, current_time, limit)
        @store.evalsha(@sha_script, keys: [key], argv: ["(#{start_time}", current_time, limit, SecureRandom.uuid])
      end

      ##
      # Returns the first time (lowest score) for a key's set within the
      # provided range
      def earliest(key, min)
        _request_id, time = @store.zrangebyscore(key, "(#{min}", '+inf', withscores: true, limit: [0, 1]).first
        time
      end

      private

      ##
      # Lua script to track a request against a key. This script ensures a redis call to zcount and
      # zadd behave atomically to maintain thread safety. The request is only added to the key if the
      # provided limit has not been reached. It will return true if successfully added or false otherwise
      def script
        "
          local count = redis.call('ZCOUNT', KEYS[1], ARGV[1], '+inf')
          if count >= tonumber(ARGV[3]) then
            return false
          else
            redis.call('ZADD', KEYS[1], ARGV[2], ARGV[4])
            return true
          end
        "
      end
    end
  end
end
