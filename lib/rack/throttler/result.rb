# frozen_string_literal: true

module Rack
  class Throttler
    # Result describes the outcome of a throttling process
    class Result
      attr_accessor :allow, :retry_interval

      def initialize(options = {})
        @allow = options.fetch(:allow, true)
        @retry_interval = options[:retry_interval]
      end
    end
  end
end
