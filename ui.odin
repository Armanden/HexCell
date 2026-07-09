package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"


UI_Button :: struct {
	rect: rl.Rectangle,
	text: cstring,
}


ui_button :: proc(button: UI_Button) -> bool {


	mouse := rl.GetMousePosition()


	hover := rl.CheckCollisionPointRec(mouse, button.rect)


	color := rl.DARKGRAY


	if hover {
		color = rl.GRAY
	}


	rl.DrawRectangleRec(button.rect, color)


	text_width := rl.MeasureText(button.text, 24)


	rl.DrawText(
		button.text,
		i32(button.rect.x + button.rect.width / 2 - f32(text_width) / 2),
		i32(button.rect.y + button.rect.height / 2 - 12),
		24,
		rl.WHITE,
	)


	return hover && rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
}


// Main menu.

ui_draw_menu :: proc() -> bool {


	rl.ClearBackground(rl.BLACK)


	title_width := rl.MeasureText("HexCell", 50)


	rl.DrawText("HexCell", 360 - title_width / 2, 160, 50, rl.WHITE)


	start := UI_Button {
		rect = {250, 300, 220, 60},
		text = "Start Game",
	}


	quit := UI_Button {
		rect = {250, 390, 220, 60},
		text = "Quit",
	}


	if ui_button(start) {

		return true
	}


	if ui_button(quit) {

		rl.CloseWindow()
	}


	return false
}


// Win screen.

ui_draw_win :: proc() -> bool {


	rl.ClearBackground(rl.BLACK)


	width := rl.MeasureText("YOU WON", 50)


	rl.DrawText("YOU WON", 360 - width / 2, 170, 50, rl.GREEN)


	restart := UI_Button {
		rect = {250, 320, 220, 60},
		text = "Restart",
	}


	quit := UI_Button {
		rect = {250, 410, 220, 60},
		text = "Quit",
	}


	if ui_button(restart) {

		return true
	}


	if ui_button(quit) {

		rl.CloseWindow()
	}


	return false
}


// In-game information.

ui_draw_stats :: proc(player: ^Player, cells: int) {


	text := fmt.aprintf(
		"HP %d EN %d MASS %d CELLS %d",
		player.attributes.health,
		player.attributes.energy,
		player.attributes.mass,
		cells,
	)

	c_text := strings.clone_to_cstring(text)

	defer delete(c_text)

	rl.DrawText(c_text, 10, 10, 20, rl.WHITE)
}
