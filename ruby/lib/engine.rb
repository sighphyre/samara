require "extism"

def to_numeric_response(message)
    message.bytes.pack("C*").unpack1("V")
end

class Engine

    attr_accessor :engine_ptr

    def initialize

        manifest = Extism::Manifest.from_path "../core/wasm/target/wasm32-wasi/release/core.wasm"
        @plugin = Extism::Plugin.new(manifest, wasi: true)

        self.engine_ptr =  to_numeric_response(@plugin.call("new_engine", ""))

        message = {"engine_ptr": self.engine_ptr, "message": "test"}
    end

    def enabled?(name, context)
        message = {"engine_ptr": self.engine_ptr, "message": name}

        response = to_numeric_response(@plugin.call("is_enabled", message.to_json.to_s))
        puts response
    end

    def take_state(state)

    end

    def get_variant(name, context)
    end

    def count_toggle(toggle_name, enabled)
    end

    def count_variant(toggle_name, variant_name)
    end

    def get_metrics
    end

    def register_custom_strategies(strategies)
    end
end