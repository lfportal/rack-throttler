# frozen_string_literal: true

require 'rack/throttler/version'
require 'rack/throttler/logger'
require 'rack/throttler/result'
require 'rack/throttler/store'
require 'rack/throttler/throttle'
require 'rack/utils'

module Rack
  # Throttler is rack middleware that performs rate limiting
  class Throttler
    include Rack::Utils

    ##
    # Returns the stored limiters
    def self.throttles
      @throttles ||= []
    end

    ##
    # Returns the tracking store
    def self.store
      @store ||= Store.new
    end

    ##
    # Adds a throttling rule
    def self.throttle(options)
      throttles << Throttle.new(options)
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      throttle = matching_throttle(request)
      if throttle
        result = throttle.enforce_request(request.ip)
        if result.allow
          @app.call(env)
        else
          Logger.log throttled_log_message(request)
          limit_exceeded_response(result.retry_interval)
        end
      else
        @app.call(env)
      end
    end

    private

    ##
    # Helper method to generate a response for exceeding the rate limit
    def limit_exceeded_response(retry_interval)
      retry_seconds = retry_interval.round
      [
        SYMBOL_TO_STATUS_CODE[:too_many_requests],
        { 'Content-Type' => 'text/plain', 'Retry-After' => retry_seconds },
        ["Rate limit exceeded. Try again in #{retry_seconds} second#{retry_seconds != 1 ? 's' : ''}."]
      ]
    end

    ##
    # Helper method to generate the throttled logger message
    def throttled_log_message(request)
      "Throttled #{request.request_method} \"#{normalized_request_path(request)}\" for #{request.ip} at #{Time.now}"
    end

    ##
    # Helper method to find the first matching throttle that matches the request
    def matching_throttle(request)
      self.class.throttles.find { |t| t.match?(normalized_request_path(request), request.request_method) }
    end

    ##
    # Returns the request path without any trailing slashes
    def normalized_request_path(request)
      path = request.path.gsub(%r{/+}, '/').sub(%r{/$}, '')
      path.empty? ? '/' : path
    end
  end
end
