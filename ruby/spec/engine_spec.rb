require 'rspec'
require 'json'
require_relative '../lib/engine.rb'

index_file_path = '../client-specification/specifications/index.json'
test_suites = JSON.parse(File.read(index_file_path))

SIMPLE_FEATURES = {
  "version": 1,
  "features": [
    {
      "name": "Feature.A",
      "description": "Enabled toggle",
      "enabled": true,
      "strategies": [{
        "name": "default"
      }]
    },
    {
      "name": "Feature.B",
      "description": "Disabled toggle",
      "enabled": false,
      "strategies": [{
        "name": "default"
      }]
    },
    {
      "name": "Feature.C",
      "enabled": true,
      "strategies": []
    },
    {
      "name": "Feature.D",
      "enabled": true,
      "strategies": [{
        "name": "default",
        "constraints": [
          {
            "contextName": "email",
            "operator": "STR_CONTAINS",
            "values": ["email"]
          }]
      }]
    }
  ]
}

RSpec.describe Engine do

  describe '#checking a toggle' do
    it 'that does not exist should yield a not found' do
      engine = Engine.new
      is_enabled = engine.enabled?("test", {})
      expect(is_enabled).to be_nil
    end

    it 'should respect state set by take state' do
      engine = Engine.new

      is_enabled = engine.enabled?("Feature.A", {})
      expect(is_enabled).to be_nil

      engine.take_state(SIMPLE_FEATURES)

      is_enabled = engine.enabled?("Feature.A", {})
      expect(is_enabled).to be true
    end

    it 'should use the context for evaluation' do
      engine = Engine.new

      engine.take_state(SIMPLE_FEATURES)

      should_not_be_enabled = engine.enabled?("Feature.D", {})
      should_be_enabled = engine.enabled?("Feature.D", {
        properties: {
          email: "test@some-email.com"
        },
      })

      expect(should_not_be_enabled).to be false
      expect(should_be_enabled).to be true
    end

    it 'should clear metrics when get_metrics is called' do
      engine = Engine.new
      feature_name = 'Feature.A'

      engine.take_state(SIMPLE_FEATURES)

      engine.count_toggle(feature_name, true)
      engine.count_toggle(feature_name, false)

      metrics = engine.get_metrics() # This should clear the metrics buffer

      metric = metrics[:toggles][feature_name.to_sym]
      expect(metric[:yes]).to eq(1)
      expect(metric[:no]).to eq(1)

      metrics = engine.get_metrics()
      expect(metrics).to be_nil
    end

    it 'should increment toggle count when it exists' do
      engine = Engine.new
      toggle_name = 'Feature.A'

      engine.take_state(SIMPLE_FEATURES)

      engine.count_toggle(toggle_name, true)
      engine.count_toggle(toggle_name, false)

      metrics = engine.get_metrics()
      metric = metrics[:toggles][toggle_name.to_sym]

      expect(metric[:yes]).to eq(1)
      expect(metric[:no]).to eq(1)
    end

    it 'should increment toggle count when the toggle does not exist' do
      engine = Engine.new
      toggle_name = 'Feature.X'

      engine.count_toggle(toggle_name, true)
      engine.count_toggle(toggle_name, false)

      metrics = engine.get_metrics()
      metric = metrics[:toggles][toggle_name.to_sym]

      expect(metric[:yes]).to eq(1)
      expect(metric[:no]).to eq(1)
    end

    it 'should increment variant' do
      engine = Engine.new
      toggle_name = 'Feature.Q'

      engine.take_state(SIMPLE_FEATURES)

      engine.count_variant(toggle_name, 'disabled')

      metrics = engine.get_metrics()
      metric = metrics[:toggles][toggle_name.to_sym]

      expect(metric[:variants][:disabled]).to eq(1)
    end
  end
end

RSpec.describe 'Client Specification' do
  let(:engine) { Engine.new }

  test_suites.each do |suite|
    suite_path = File.join('../client-specification/specifications', suite)
    suite_data = JSON.parse(File.read(suite_path), symbolize_names: true)

    describe "Suite '#{suite}'" do
      before(:each) do
        engine.take_state(suite_data[:state])
      end

      suite_data.fetch(:tests, []).each do |test|
        describe "Test '#{test[:description]}'" do
          let(:context) { test[:context] }
          let(:toggle_name) { test[:toggleName] }
          let(:expected_result) { test[:expectedResult] }

          it 'returns correct result for `is_enabled?` method' do
            result = engine.enabled?(toggle_name, context) || false

            expect(result).to eq(expected_result),
                              "Failed test '#{test['description']}': expected #{expected_result}, got #{result}"
          end
        end
      end

      suite_data.fetch(:variantTests, []).each do |test|
        next unless test[:expectedResult]

        describe "Variant Test '#{test[:description]}'" do
          let(:context) { test[:context] }
          let(:toggle_name) { test[:toggleName] }
          let(:expected_result) { to_variant(test[:expectedResult]) }

          it 'returns correct result for `get_variant` method' do
            result = engine.get_variant(toggle_name, context) || {
              :name => 'disabled',
              :payload => nil,
              :enabled => false
            }

            expect(result[:name]).to eq(expected_result[:name])
            expect(result[:payload]).to eq(expected_result[:payload])
            expect(result[:enabled]).to eq(expected_result[:enabled])
          end
        end
      end
    end
  end
end
