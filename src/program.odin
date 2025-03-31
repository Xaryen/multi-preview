package program

import rl "vendor:raylib"
import "core:log"
import "core:fmt"
import "core:c"
import "core:strconv"

import emc "emc_web"

g_font: rl.Font
run: bool
texture: rl.Texture
texture2: rl.Texture
texture2_rot: f32

g_zoom_mod := f32(1)
g_dpi  := f32(150)
g_magnification := g_dpi * g_zoom_mod

g_textbuf: [255]u8
g_dpi_field := i32(g_dpi)



DEFAULT_RES   :: [2]i32{1920, 1080}

A4            :: [2]f32{297, 210}
A4_FRAME      :: [2]f32{260, 146.25}
A4_ANCH_POS   :: [2]f32{A4.x/2, A4.y*11/20}

Active_Input_Box :: enum {
	None,
	Test,
	Dpi,
}

active_box := Active_Input_Box{}

//rl.SetTextureFilter()

init :: proc() {
	run = true
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(expand_values(DEFAULT_RES), "Multiplane Previewer")

	// Anything in `assets` folder is available to load.
	texture = rl.LoadTexture("assets/round_cat.png")

	text := #load("codepoints.txt", cstring)

	// Get codepoints from text
	codepointCount := i32(0)
	codepoints := rl.LoadCodepoints(text, &codepointCount)
	
	g_font = rl.LoadFontEx("assets/NotoSansJP-Regular.ttf", 36, codepoints, codepointCount)
	rl.UnloadCodepoints(codepoints)

	rl.GuiSetFont(g_font)
	rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 36)

	// A different way of loading a texture: using `read_entire_file` that works
	// both on desktop and web. Note: You can import `core:os` and use
	// `os.read_entire_file`. But that won't work on web. Emscripten has a way
	// to bundle files into the build, and we access those using this
	// special `read_entire_file`.
	if long_cat_data, long_cat_ok := read_entire_file("assets/long_cat.png", context.temp_allocator); long_cat_ok {
		long_cat_img := rl.LoadImageFromMemory(".png", raw_data(long_cat_data), c.int(len(long_cat_data)))
		texture2 = rl.LoadTextureFromImage(long_cat_img)
		rl.UnloadImage(long_cat_img)
	}

}

update :: proc() {
	g_magnification = g_dpi * g_zoom_mod

	rl.BeginDrawing()
	rl.ClearBackground({120, 120, 153, 255})

	// PAPER
	paper := rl.Rectangle{0, 0, mm_to_px(A4.x, g_magnification),  mm_to_px(A4.y, g_magnification)}
	rl.DrawRectangleRec(paper, {230, 230, 230, 255})

	A4_pos := A4_ANCH_POS - A4_FRAME/2
	paper_frame := rl.Rectangle{
		mm_to_px(A4_pos.x, g_magnification),
		mm_to_px(A4_pos.y, g_magnification),
		mm_to_px(A4_FRAME.x, g_magnification),
		mm_to_px(A4_FRAME.y, g_magnification),
	}
	rl.DrawRectangleLinesEx(paper_frame, 2, {0, 0, 0, 255})


	{
		texture2_rot += rl.GetFrameTime()*50
		source_rect := rl.Rectangle {
			0, 0,
			f32(texture2.width), f32(texture2.height),
		}
		dest_rect := rl.Rectangle {
			500, 500,
			f32(texture2.width)*5, f32(texture2.height)*5,
		}
		rl.DrawTexturePro(texture2, source_rect, dest_rect, {dest_rect.width/2, dest_rect.height/2}, texture2_rot, rl.WHITE)
	}

	{
		//texture2_rot += rl.GetFrameTime()*50
		source_rect := rl.Rectangle {
			0, 0,
			f32(texture.width), f32(texture.height),
		}
		dest_rect := rl.Rectangle {
			500, 700,
			f32(texture.width)*5, f32(texture.height)*5,
		}
		rl.DrawTexturePro(texture, source_rect, dest_rect, {dest_rect.width/2, dest_rect.height/2}, texture2_rot, rl.WHITE)
	}




	//rl.DrawTextureEx(texture, rl.GetMousePosition(), 0, 5, rl.WHITE)

	{	
		w := rl.GetScreenWidth()
		h := rl.GetScreenHeight()

		rl.DrawRectangle(w/2, h/2, 200, 200, {35, 35, 35, 255})

		

	}



	{
		@static slider_val: f32 = 0

		BUTTON_SIZE :: [2]f32{350, 35}

		rect_pad := [2]f32{15, 15}
		start_pos := [2]f32{f32(rl.GetScreenWidth()) - BUTTON_SIZE.x - 2*rect_pad.x, 0}
		pad       := [2]f32{10, 10} 
		pad += start_pos

		pad_size  := [2]f32{0, 10}

		buttons: f32 = 8


		rl.DrawRectangleRec({
			pad.x - rect_pad.x,
			pad.y - rect_pad.y,
			BUTTON_SIZE.x + 2*rect_pad.x,
			BUTTON_SIZE.y * buttons + pad_size.y * (buttons - 1) + 2*rect_pad.y},
			rl.BLACK,
		)

		rl.GuiLabelButton({pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, "密着マルチプレビューア")

		pad.y += pad_size.y + BUTTON_SIZE.y

		if rl.GuiButton({pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, "こんにちは、世界！") {
			log.info("logging test")
			fmt.println("fmt printing test")
		}

		pad.y += pad_size.y + BUTTON_SIZE.y

		if rl.GuiSlider({pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, {}, "test", &slider_val, 0, 100) != 0 {

		}

		pad.y += pad_size.y + BUTTON_SIZE.y

		test_box_rect := rl.Rectangle{pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y}
		if rl.CheckCollisionPointRec(rl.GetMousePosition(), test_box_rect) && rl.IsMouseButtonDown(.LEFT) {
			active_box = .Test
		}
		if rl.GuiTextBox(test_box_rect, cstring(&g_textbuf[0]), 36, active_box == .Test) {

		}

		pad.y += pad_size.y + BUTTON_SIZE.y

		dpi_field_rect := rl.Rectangle{pad.x, pad.y,BUTTON_SIZE.x, BUTTON_SIZE.y}
		if rl.CheckCollisionPointRec(rl.GetMousePosition(), dpi_field_rect) && rl.IsMouseButtonDown(.LEFT) {
			active_box = .Dpi
		}
		if rl.GuiValueBox(dpi_field_rect, {},  &g_dpi_field, 1, 1000, active_box == .Dpi) != 0 {
			//run = false
			g_dpi = f32(g_dpi_field)
		}

		pad.y += pad_size.y + BUTTON_SIZE.y

		rl.GuiLabel(
			{pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y},
			fmt.ctprintf("%.2f", strconv.atof(string(g_textbuf[:])))
		)

		pad.y += pad_size.y + BUTTON_SIZE.y

		rl.GuiLabel(
			{pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y},
			//fmt.ctprintf("%.2f", slider_val),
			fmt.ctprintf("%t", rl.IsKeyDown(.LEFT_CONTROL))
		)

		pad.y += pad_size.y + BUTTON_SIZE.y

		rl.GuiLabel(
			{pad.x, pad.y, BUTTON_SIZE.x, BUTTON_SIZE.y},
			fmt.ctprintf("ZOOM: %.2f %%", g_zoom_mod*100)
		)

	}

	rl.EndDrawing()

	mouse_delta := emc.get_mousewheel_delta()

	if rl.IsKeyDown(.LEFT_CONTROL) && (mouse_delta != 0) {
		log.debugf("%.2f", mouse_delta)
		wheel_zoom := mouse_delta * 0.1
		g_zoom_mod += wheel_zoom
	}

	if rl.IsKeyDown(.ENTER) {
		active_box = .None
	}

	// Anything allocated using temp allocator is invalid after this.
	free_all(context.temp_allocator)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h))
}

shutdown :: proc() {

	rl.UnloadFont(g_font)

	rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			run = false
		}
	}

	return run
}