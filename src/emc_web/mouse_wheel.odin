package emc

@(default_calling_convention = "c")
foreign {
	emscripten_run_script_int :: proc(script: cstring) -> i32 ---
}

get_mousewheel_delta :: proc() -> f32 {
	return f32(emscripten_run_script_int("getWheelDelta()"))
};
