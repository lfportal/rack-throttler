# frozen_string_literal: true

module Rack
  class Throttler
    # Logger returns the Rails logger if available otherwise falls back to using ruby puts
    class Logger
      def self.log(msg)
        if defined?(::Rails)
          ::Rails.logger.info(msg)
        else
          puts msg
        end
      end
    end
  end
end
