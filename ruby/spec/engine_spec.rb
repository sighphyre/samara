require 'rspec'
require 'json'
require_relative '../lib/engine.rb'

RSpec.describe Engine do

  describe '#checking a toggle' do
    it 'that does not exist should yield a not found' do
      engine = Engine.new
      engine.enabled?("test", nil)
    end
  end
end