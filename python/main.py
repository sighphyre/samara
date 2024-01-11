import extism
import json


base_state = """
{
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
            }
        ]
    }
"""


class YggdrasilEngine:
    def __init__(self):
        raw_data = bytes(
            open(
                "../core/wasm/target/wasm32-wasi/release/core.wasm",
                "rb",
            ).read()
        )
        manifest = {"wasm": [{"data": raw_data}]}
        self.plugin = extism.Plugin(manifest, wasi=True)
        self.plugin.call("new_engine", [])

        pointer_bytes = self.plugin.call("new_engine", [])
        self.ptr = int.from_bytes(pointer_bytes, "little")

    def is_enabled(self, name, context):
        message = {"engine_ptr": self.ptr, "message": name}
        result_bytes = self.plugin.call("is_enabled", data=json.dumps(message))
        ## decode the raw bytes into a boolean - it comes back a little endian 4 byte packet, LSB is what we're interested in
        return result_bytes[0] != 0

    def take_state(self, state):
        message = {"engine_ptr": self.ptr, "message": state}
        self.plugin.call("take_state", data=json.dumps(message))


engine = YggdrasilEngine()

print(engine.is_enabled("Feature.A", None))
engine.take_state(json.loads(base_state))
print(engine.is_enabled("Feature.A", None))
