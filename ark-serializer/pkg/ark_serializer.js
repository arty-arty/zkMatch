import * as wasm from "./ark_serializer_bg.wasm";
import { __wbg_set_wasm } from "./ark_serializer_bg.js";
__wbg_set_wasm(wasm);
export * from "./ark_serializer_bg.js";
