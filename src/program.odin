package program

import rl "vendor:raylib"
import "core:log"
import "core:fmt"
import "core:c"
import "core:strconv"

_ :: log
_ :: strconv

DEFAULT_BOX_SIZE :: 100 //px
DEFAULT_RES      :: [2]i32{1920, 1080}
A4               :: [2]f32{297, 210}
A4_FRAME         :: [2]f32{260, 146.25}
A4_ANCH_POS      :: [2]f32{A4.x/2, A4.y*11/20}

g_font: rl.Font
g_run: bool
g_paused: bool

g_zoom_mod := f32(1)
g_dpi      := f32(150)
g_real_dpi := g_dpi * g_zoom_mod

g_dpi_field := i32(g_dpi)

g_boxes := Boxes{}
g_box_size := px_to_mm(DEFAULT_BOX_SIZE, g_real_dpi)

g_24fps_time := f64(0)
FRAMETIME_24FPS :: f64(1.0/24)

g_lang := Language(.ENG)

Boxes :: struct {
	arr:  #soa[32]Box,
	bufs: [32][255]byte,
	num:  i32,
}

Box :: struct {
	velocity: f32, // "mm per k" (24fps frame)
	time:     f32,
}


Language :: enum {
	JP,
	ENG,
}

ADD_BOX_STR := [Language]cstring{
	.ENG = "Add Box",
	.JP = "ボックス追加"
}

CHANGE_LANG_STR := [Language]cstring{
	.ENG = "日本語",
	.JP = "English"
}

TITLE_STR := [Language]cstring{
	.ENG = "Multiplane Previewer",
	.JP = "密着マルチプレビューア"
}

BOX_SIZE_STR := [Language]cstring{
	.ENG = "Box Size:",
	.JP = "ボックスサイズ"
}

PAUSE_STR := [Language]cstring{
	.ENG = "PAUSE",
	.JP = "一時停止"
}

RESET_STR := [Language]cstring{
	.ENG = "RESET",
	.JP = "リセット"
}

Active_Input_Box :: enum {
	None,
	Dpi,
	Box1 = 8,
	Box2, Box3, Box4, Box5, Box6, Box7, Box8, Box9, Box10, Box11, Box12, Box13, Box14, Box15, Box16,
}

g_active_box := Active_Input_Box{}

//rl.SetTextureFilter()

init :: proc() {
	g_run = true
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(expand_values(DEFAULT_RES), "Multiplane Previewer")

	text := #load("codepoints.txt", cstring)

	// Get codepoints from text
	codepointCount := i32(0)
	codepoints := rl.LoadCodepoints(text, &codepointCount)
	
	g_font = rl.LoadFontEx("assets/NotoSansJP-Regular.ttf", 36, codepoints, codepointCount)
	rl.UnloadCodepoints(codepoints)

	rl.GuiSetFont(g_font)
	rl.GuiSetStyle(.DEFAULT, cast(i32)rl.GuiDefaultProperty.TEXT_SIZE, 36)

}

update :: proc() {
	g_real_dpi = g_dpi * g_zoom_mod

	time := rl.GetTime()
	next_24fps_frame := false

	log.debug(FRAMETIME_24FPS)

	if time > (g_24fps_time + FRAMETIME_24FPS) {
		g_24fps_time = time
		next_24fps_frame = true
	}

	if g_paused {
		next_24fps_frame = false
	}

	rl.BeginDrawing()
	rl.ClearBackground({120, 120, 153, 255})

	// PAPER
	paper := rl.Rectangle{0, 0, mm_to_px(A4.x, g_real_dpi),  mm_to_px(A4.y, g_real_dpi)}
	rl.DrawRectangleRec(paper, {230, 230, 230, 255})

	A4_pos := A4_ANCH_POS - A4_FRAME/2
	paper_frame := rl.Rectangle{
		mm_to_px(A4_pos.x, g_real_dpi),
		mm_to_px(A4_pos.y, g_real_dpi),
		mm_to_px(A4_FRAME.x, g_real_dpi),
		mm_to_px(A4_FRAME.y, g_real_dpi),
	}
	rl.DrawRectangleLinesEx(paper_frame, 2, {0, 0, 0, 255})


	// DRAW BOXES
	{	
		//w := rl.GetScreenWidth()
		//h := rl.GetScreenHeight()

		//TODO: Antialsing/texture filtering

		start_pos := [2]f32{}

		start_pos = mm_to_px(30, g_real_dpi)
		box_dim  := mm_to_px(g_box_size, g_real_dpi)
		pad := box_dim + box_dim/5

		for i in 0..<g_boxes.num {
			box := &g_boxes.arr[i]

			if next_24fps_frame {
				box.time += 1
			}

			pos_x := mm_to_px(box.velocity * box.time, g_real_dpi) + start_pos.x
		
			rl.DrawRectangleV(
				{pos_x,  start_pos.y},
				{box_dim, box_dim},
				{35, 35, 35, 255},
			)



			start_pos.y += pad

			if pos_x > f32(rl.GetScreenWidth()) {
				box.time = 0
			}

		}

		

	}


	//GUI
	{

		BUTTON_SIZE :: [2]f32{350, 35}

		// crappy adhoc autolayout
		rect_pad  := [2]f32{15, 15}
		start_pos := [2]f32{f32(rl.GetScreenWidth()) - BUTTON_SIZE.x - 2*rect_pad.x, 0}
		pad_start := [2]f32{10, 10} 
		pad  := [2]f32{0, 10}
		start_pos += pad_start



		rl.DrawRectangleRec({
			start_pos.x - rect_pad.x,
			start_pos.y - rect_pad.y,
			BUTTON_SIZE.x + 2*rect_pad.x,
			f32(rl.GetScreenHeight())},
			rl.BLACK,
		)

		//TITLE
		rl.GuiLabelButton({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, TITLE_STR[g_lang])
		start_pos.y += pad.y + BUTTON_SIZE.y

		if rl.GuiButton(
			{start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y},
			CHANGE_LANG_STR[g_lang],
		) {
			g_lang = .JP if g_lang == .ENG else .ENG
		}
		start_pos.y += pad.y + BUTTON_SIZE.y
		

		//ADD BOX
		if rl.GuiButton({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, ADD_BOX_STR[g_lang]) {
			
			g_boxes.arr[g_boxes.num] = Box{
			}

			g_boxes.num += 1
		}
		start_pos.y += pad.y + BUTTON_SIZE.y

		
		//BOX SIZE
		rl.GuiLabel({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, BOX_SIZE_STR[g_lang])
		start_pos.y += pad.y + BUTTON_SIZE.y
		if rl.GuiSlider({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, {}, {}, &g_box_size, 0, 200) != 0 {
			//never seems to get hit? it doesn't return 1 even when changing
		}
		start_pos.y += pad.y + BUTTON_SIZE.y

		for i in 0..<g_boxes.num {
			box := &g_boxes.arr[i]
			curr_box_rect := rl.Rectangle{start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}
			if rl.CheckCollisionPointRec(rl.GetMousePosition(), curr_box_rect) && rl.IsMouseButtonDown(.LEFT) {
				g_active_box = Active_Input_Box(8+i)
			}
			if rl.GuiTextBox(curr_box_rect, cstring(&g_boxes.bufs[i][0]), 36, g_active_box == Active_Input_Box(8+i)) {
				box.velocity, _ = strconv.parse_f32(string(g_boxes.bufs[i][:]))
			}
			start_pos.y += pad.y + BUTTON_SIZE.y
		}
		
		//DPI
		rl.GuiLabel({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, "DPI:")
		start_pos.y += pad.y + BUTTON_SIZE.y
		dpi_field_rect := rl.Rectangle{start_pos.x, start_pos.y,BUTTON_SIZE.x, BUTTON_SIZE.y}
		if rl.CheckCollisionPointRec(rl.GetMousePosition(), dpi_field_rect) && rl.IsMouseButtonDown(.LEFT) {
			g_active_box = .Dpi
		}
		if rl.GuiValueBox(dpi_field_rect, {},  &g_dpi_field, 1, 1000, g_active_box == .Dpi) != 0 {
			//run = false
			g_dpi = f32(g_dpi_field)
		}
		start_pos.y += pad.y + BUTTON_SIZE.y + 100


		rl.GuiLabel(
			{start_pos.x, start_pos.y, BUTTON_SIZE.x, 100},
			//fmt.ctprintf("%.2f", strconv.atof(string(g_textbuf[:])))
			fmt.ctprintf("24fps: %.4f \n\n60fps: %.4f", g_24fps_time, time),
		)
		start_pos.y += pad.y + 100


		rl.GuiLabel(
			{start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y},
			fmt.ctprintf("ZOOM: %.2f %%", g_zoom_mod*100)
		)
		start_pos.y += pad.y + BUTTON_SIZE.y
		rl.GuiLabel(
			{start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y},
			"(LCTRL + MOUSEWHEEL)",
		)
		start_pos.y += pad.y + BUTTON_SIZE.y
		start_pos.y += pad.y + BUTTON_SIZE.y

		if rl.GuiButton({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, PAUSE_STR[g_lang]) {
			g_paused = !g_paused
		}
		start_pos.y += pad.y + BUTTON_SIZE.y

		if rl.GuiButton({start_pos.x, start_pos.y, BUTTON_SIZE.x, BUTTON_SIZE.y}, RESET_STR[g_lang]) {
			g_boxes.arr.time = 0
		}
		start_pos.y += pad.y + BUTTON_SIZE.y

	}

	rl.EndDrawing()

	mouse_delta: f32

	when ODIN_OS == .JS {
		mouse_delta = emc_get_mousewheel_delta()
	} else {
		mouse_delta = rl.GetMouseWheelMove()
	}
	
	
	if rl.IsKeyDown(.LEFT_CONTROL) && (mouse_delta != 0) {
		wheel_zoom := mouse_delta * 0.1
		g_zoom_mod += wheel_zoom
	}

	if rl.IsKeyDown(.ENTER) {
		g_active_box = .None
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
			g_run = false
		}
	}

	return g_run
}