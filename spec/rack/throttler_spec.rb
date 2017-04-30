# frozen_string_literal: true

require 'spec_helper'

describe Rack::Throttler do
  include Rack::Test::Methods

  let(:mock_app)     { double 'rack app' }
  let(:app)          { described_class.new(mock_app) }
  let(:client)       { '1.2.3.4' }
  let(:other_client) { '2.3.4.5' }
  let(:limit)        { 3 }
  let(:period)       { 5 }

  before(:all) do
    @redis = Redis.new
  end

  before(:each) do
    @redis.flushall
    allow(mock_app).to receive(:call).and_return([200, {}, ['ok']])
    described_class.throttle(pattern: %r{^/$}, method: 'get', limit: limit, period: period)
  end

  after(:each) do
    Timecop.return
  end

  context 'for a client that has not reached the limit' do
    it 'should allow consecutive requests up to the specified limit' do
      time = Time.local(2000, 1, 1, 1, 0, 0)
      Timecop.freeze(time)
      limit.times do
        get '/', {}, 'REMOTE_ADDR' => client
        expect(last_response.status).to eq(200)
      end
    end
  end

  context 'for a client that has reached the limit' do
    let(:first_request_time)    { Time.local(2000, 1, 1, 1, 0, 0) }
    let(:rejected_request_time) { first_request_time + 3 }
    let(:retry_interval)        { period - (rejected_request_time - first_request_time).to_i }

    before(:each) do
      Timecop.freeze(first_request_time)
      get '/', {}, 'REMOTE_ADDR' => client
      Timecop.freeze(first_request_time + 2)
      2.times do
        get '/', {}, 'REMOTE_ADDR' => client
      end
    end

    it 'should reject subsequent requests and return a retry time' do
      Timecop.freeze(rejected_request_time)
      get '/', {}, 'REMOTE_ADDR' => client
      expect(last_response.status).to eq(429)
      expect(last_response.body).to eq("Rate limit exceeded. Try again in #{retry_interval} seconds.")
    end

    it 'should allow requests after the retry time has passed' do
      retry_request_time = rejected_request_time + retry_interval
      Timecop.freeze(retry_request_time)
      get '/', {}, 'REMOTE_ADDR' => client
      expect(last_response.status).to eq(200)
    end

    it 'should not reject requests to other routes' do
      Timecop.freeze(rejected_request_time)
      get '/other', {}, 'REMOTE_ADDR' => client
      expect(last_response.status).to eq(200)
    end

    it 'should not reject requests from other clients' do
      Timecop.freeze(rejected_request_time)
      get '/', {}, 'REMOTE_ADDR' => other_client
      expect(last_response.status).to eq(200)
    end
  end
end
