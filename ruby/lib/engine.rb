require "extism"
require "custom_strategy"

def to_numeric_response(message)
    to_string_response(message).unpack1("V")
end

def to_boolean_response(message)
    numeric = to_numeric_response(message)
    numeric == 1 ? true : (numeric == 0 ? false : nil)
end

def to_string_response(message)
    message.bytes.pack("C*")
end

def to_hash_response(message)
    JSON.parse(to_string_response(message), symbolize_names: true)
end

def to_variant(raw_variant)
    payload = raw_variant[:payload] && raw_variant[:payload].transform_keys(&:to_s)
    {
        name: raw_variant[:name],
        enabled: raw_variant[:enabled],
        payload: payload,
    }
end

class Engine

    attr_accessor :engine_ptr

    def initialize
        manifest = Extism::Manifest.from_path "/home/simon/dev/experiments/samara/ruby/core.wasm"
        @plugin = Extism::Plugin.new(manifest, wasi: true)
        @custom_strategy_handler = CustomStrategyHandler.new

        self.engine_ptr = to_numeric_response(@plugin.call("new_engine", ""))

        message = {"engine_ptr": self.engine_ptr, "message": "test"}
    end

    def take_state(state)
        message = {"engine_ptr": self.engine_ptr, "message": state}
        @plugin.call("take_state", message.to_json.to_s)
    end

    def enabled?(toggle_name, context)
        custom_strategy_results = @custom_strategy_handler.evaluate_custom_strategies(toggle_name, context)
        packet = {"toggle_name": toggle_name, "context": context, "custom_strategy_results": custom_strategy_results}
        message = {"engine_ptr": self.engine_ptr, "message": packet}
        to_boolean_response(@plugin.call("is_enabled", message.to_json.to_s))
    end

    def get_variant(toggle_name, context)
        custom_strategy_results = @custom_strategy_handler.evaluate_custom_strategies(toggle_name, context)
        packet = {"toggle_name": toggle_name, "context": context, "custom_strategy_results": custom_strategy_results}
        message = {"engine_ptr": self.engine_ptr, "message": packet}
        to_variant(to_hash_response(@plugin.call("get_variant", message.to_json.to_s)))
    end

    def count_toggle(toggle_name, enabled)
        packet = {"toggle_name": toggle_name, "enabled": enabled}
        message = {"engine_ptr": self.engine_ptr, "message": packet}
        @plugin.call("count_toggle", message.to_json.to_s)
    end

    def count_variant(toggle_name, variant_name)
        packet = {"toggle_name": toggle_name, "variant_name": variant_name}
        message = {"engine_ptr": self.engine_ptr, "message": packet}
        @plugin.call("count_variant", message.to_json.to_s)
    end

    def get_metrics
        packet = {"engine_ptr": self.engine_ptr}
        message = {"engine_ptr": self.engine_ptr, "message": packet}
        to_hash_response(@plugin.call("get_metrics", message.to_json.to_s))
    end

    def register_custom_strategies(strategies)
    end
end