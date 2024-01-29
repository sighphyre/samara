use core::fmt;
use std::{
    collections::HashMap,
    fmt::{Display, Formatter},
};

use extism_pdk::{plugin_fn, FnResult, Json};

use serde::{Deserialize, Serialize};
use unleash_types::{client_features::ClientFeatures, client_metrics::MetricBucket};
use unleash_yggdrasil::{Context, EngineState, VariantDef};

use std::error::Error;

type CustomStrategyResults = HashMap<String, bool>;

fn to_enabled_state(toggle_state: Option<bool>) -> i32 {
    match toggle_state {
        Some(true) => 1,
        Some(false) => 0,
        None => -1,
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Message<T> {
    engine_ptr: u32,
    message: T,
}

#[derive(Serialize, Deserialize, Debug)]
struct ResolveFeatureRequest {
    toggle_name: String,
    context: Context,
    custom_strategy_results: CustomStrategyResults,
}

#[derive(Serialize, Deserialize, Debug)]
struct CountMetricsRequest {
    toggle_name: String,
    enabled: bool,
}

#[derive(Serialize, Deserialize, Debug)]
struct CountVariantRequest {
    toggle_name: String,
    variant_name: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct GetMetricsRequest {}

#[derive(Serialize, Deserialize, Debug, Clone)]
enum SamaraError {
    ToggleNotFound,
    UnspecifiedError(String),
}

impl Error for SamaraError {}

impl Display for SamaraError {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result {
        match &self {
            SamaraError::ToggleNotFound => write!(f, "Toggle not found"),
            SamaraError::UnspecifiedError(msg) => write!(f, "Unspecified error: {}", msg),
        }
    }
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
pub fn is_enabled(Json(message): Json<Message<ResolveFeatureRequest>>) -> FnResult<i32> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    let enabled = engine.check_enabled(
        &message.message.toggle_name,
        &message.message.context,
        &Some(message.message.custom_strategy_results),
    );

    Ok(to_enabled_state(enabled))
}

#[plugin_fn]
pub fn get_variant(
    Json(message): Json<Message<ResolveFeatureRequest>>,
) -> FnResult<Json<VariantDef>> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    let variant = engine.get_variant(
        &message.message.toggle_name,
        &message.message.context,
        &Some(message.message.custom_strategy_results),
    );

    Ok(Json(variant))
}

#[plugin_fn]
pub fn count_toggle(Json(message): Json<Message<CountMetricsRequest>>) -> FnResult<()> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;

    let toggle_name = message.message.toggle_name;
    let toggle_enabled = message.message.enabled;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    engine.count_toggle(&toggle_name, toggle_enabled);

    Ok(())
}

#[plugin_fn]
pub fn count_variant(Json(message): Json<Message<CountVariantRequest>>) -> FnResult<()> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    engine.count_variant(&message.message.toggle_name, &message.message.variant_name);

    Ok(())
}

#[plugin_fn]
pub fn get_metrics(
    Json(message): Json<Message<GetMetricsRequest>>,
) -> FnResult<Json<Option<MetricBucket>>> {
    let engine_ptr = message.engine_ptr as *mut u32 as *mut EngineState;

    let engine = unsafe { &mut *(engine_ptr as *mut EngineState) };
    let metrics = engine.get_metrics();

    Ok(Json(metrics))
}
