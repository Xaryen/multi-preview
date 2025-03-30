// Wraps os.read_entire_file and os.write_entire_file, but they also work with emscripten.

package game

@(require_results)
read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	return _read_entire_file(name, allocator, loc)
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return _write_entire_file(name, data, truncate)
}

INCHES_PER_METER :: 1000/25.4

mm_to_inches :: #force_inline proc(mm: f32) -> (inc: f32) {
	return mm * INCHES_PER_METER / 1000
}

mm_to_inches_vec :: proc(mms: $T/[$N]$E) -> E {
	for $mm in mms {
		mm_to_inches(mm)
	}
	return mms
}

mm_to_px :: #force_inline proc(mm: f32, dpi: f32) -> (px: f32) {
	return dpi * mm_to_inches(mm)
}