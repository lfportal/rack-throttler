# frozen_string_literal: true

require 'spec_helper'

describe Rack::Throttler::Result do
  subject(:result) { described_class.new }

  it { should respond_to(:allow) }
  it { should respond_to(:retry_interval) }

  it 'should set default allow value to be true' do
    expect(subject.allow).to eq(true)
  end

  it 'should set the default retry_interval value to be nil' do
    expect(subject.retry_interval).to be_nil
  end

  it 'should be able to be created with allow and retry_interval values' do
    result = described_class.new(allow: false, retry_interval: 3)
    expect(result.allow).to eq(false)
    expect(result.retry_interval).to eq(3)
  end
end
