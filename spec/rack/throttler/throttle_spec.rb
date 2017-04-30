# frozen_string_literal: true

require 'spec_helper'

describe Rack::Throttler::Throttle do
  let(:pattern)      { %r{^/$} }
  subject(:throttle) { described_class.new(pattern: pattern, method: 'GET', limit: 3, period: 5) }

  it { should respond_to(:limit) }
  it { should respond_to(:period) }

  it 'should not be instantiatable without the pattern option' do
    expect { described_class.new(method: 'GET', limit: 3, period: 5) }
      .to raise_error(ArgumentError, 'pattern must be provided')
  end

  it 'should not be instantiatable without the method option' do
    expect { described_class.new(pattern: pattern, limit: 3, period: 5) }
      .to raise_error(ArgumentError, 'method must be provided')
  end

  it 'should not be instantiatable without the limit option' do
    expect { described_class.new(pattern: pattern, method: 'GET', period: 5) }
      .to raise_error(ArgumentError, 'limit must be provided')
  end

  it 'should not be instantiatable without the period option' do
    expect { described_class.new(pattern: pattern, method: 'GET', limit: 3) }
      .to raise_error(ArgumentError, 'period must be provided')
  end

  describe('#match?') do
    it 'should return true for a matching pattern and method' do
      expect(subject.match?('/', 'GET')).to be_truthy
    end

    it 'should return false for a non-matching pattern' do
      expect(subject.match?('/not', 'GET')).to be_falsey
    end

    it 'should return false for a non-matching method' do
      expect(subject.match?('/', 'POST')).to be_falsey
    end
  end

  describe('#enforce_request') do
    let(:client) { '1.2.3.4' }

    before(:all) do
      @redis = Redis.new
    end

    before(:each) do
      @redis.flushall
    end

    context 'for a client that has not passed the limit' do
      it 'should return an allowed result' do
        result = subject.enforce_request(client)
        expect(result.allow).to be_truthy
      end

      it 'should record the request in the store' do
        expect { subject.enforce_request(client) }
          .to change { @redis.zcard("#{client}|GET|#{pattern.inspect}") }.from(0).to(1)
      end
    end

    context 'for a client that has passed the limit' do
      let(:first_request_time)    { Time.local(2000, 1, 1, 1, 0, 0) }
      let(:rejected_request_time) { first_request_time + 4 }

      before(:each) do
        Timecop.freeze(first_request_time)
        subject.enforce_request(client)
        Timecop.freeze(first_request_time + 3)
        2.times do
          subject.enforce_request(client)
        end
      end

      after(:each) do
        Timecop.return
      end

      it 'should return a disallowed result' do
        Timecop.freeze(rejected_request_time)
        result = subject.enforce_request(client)
        expect(result.allow).to be_falsey
      end

      it 'should return the retry_interval in the result' do
        Timecop.freeze(rejected_request_time)
        result = subject.enforce_request(client)
        expect(result.retry_interval).to eq(1)
      end

      it 'should return an allowed result after the retry period' do
        Timecop.freeze(rejected_request_time + 1)
        result = subject.enforce_request(client)
        expect(result.allow).to be_truthy
      end
    end
  end
end
