# frozen_string_literal: true

require 'spec_helper'

describe Rack::Throttler::Store do
  subject(:store) { described_class.new }
  let(:key)       { 'key' }

  before(:all) do
    @redis = Redis.new
  end

  before(:each) do
    @redis.flushall
  end

  describe '#track' do
    let(:limit)        { 3 }
    let(:start_time)   { 2000 }
    let(:current_time) { 5000 }

    context 'where the key has not reached the limit' do
      it 'should return true' do
        expect(subject.track(key, start_time, current_time, limit)).to be_truthy
      end

      it 'should add a record for the key' do
        expect { subject.track(key, start_time, current_time, limit) }.to change { @redis.zcard(key) }.from(0).to(1)
      end
    end

    context 'where the key has reached the limit' do
      before(:each) do
        @redis.zadd(key, 3000, 'one')
        @redis.zadd(key, 3001, 'two')
        @redis.zadd(key, 3002, 'three')
      end

      it 'should return false' do
        expect(subject.track(key, start_time, current_time, limit)).to be_falsey
      end

      it 'should not add a record for the key' do
        expect { subject.track(key, start_time, current_time, limit) }.to_not change { @redis.zcard(key) }.from(3)
      end
    end
  end

  describe '#earliest' do
    before(:each) do
      @redis.zadd(key, 5000, 'one')
      @redis.zadd(key, 6000, 'two')
      @redis.zadd(key, 7000, 'three')
      @redis.zadd(key, 8000, 'four')
    end

    it 'should return the earliest time within the provided minimum bound' do
      expect(subject.earliest(key, 5500)).to eq(6000)
    end
  end
end
