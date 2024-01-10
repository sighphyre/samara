use extism_pdk::{plugin_fn, FnResult, Json};

use serde::{Deserialize, Serialize};
use unleash_types::client_features::ClientFeatures;
use unleash_yggdrasil::{Context, EngineState};

#[derive(serde::Deserialize)]
struct Add {
    a: u32,
    b: u32,
}
#[derive(serde::Serialize)]
struct Sum {
    sum: u32,
}

#[plugin_fn]
pub fn add(input: String) -> FnResult<String> {
    Ok(input)
}

#[derive(Serialize, Deserialize)]
struct Message<T> {
    engine_ptr: u32,
    message: T,
}

#[plugin_fn]
pub fn new_engine() -> FnResult<u32> {
    let engine = EngineState::default();
    let ptr = Box::into_raw(Box::new(engine)) as *mut u32 as u32;
    Ok(ptr)
}

#[plugin_fn]
pub fn take_state(Json(message): Json<Message<ClientFeatures>>) -> FnResult<()> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;

    let features = message.message;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    engine.take_state(features);
    Ok(())
}

#[plugin_fn]
pub fn is_enabled(Json(message): Json<Message<String>>) -> FnResult<u32> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;
    let toggle_name = message.message;
    let context = Context::default();
    let external_values = None;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    engine.is_enabled(&toggle_name, &context, &external_values);
    if engine.is_enabled(&toggle_name, &context, &external_values) {
        Ok(1)
    } else {
        Ok(0)
    }
}

extern crate pest;
