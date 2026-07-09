package main

import rl "vendor:raylib"


Game_State :: enum {
	MENU,
	PLAYING,
	WON,
}


WIN_REQUIRED_CELLS :: 32


Game :: struct {
	state:      Game_State,
	player:     Player,
	world:      World,
	camera:     rl.Camera2D,
	move_speed: f32,
}


// Create game.

game_create :: proc() -> Game {


	player := player_create()


	return Game {
		state = .MENU,
		player = player,
		world = world_create(),
		camera = rl.Camera2D {
			offset = {360, 360},
			target = player.position,
			rotation = 0,
			zoom = 1,
		},
		move_speed = 5,
	}
}


// Free resources.

game_destroy :: proc(game: ^Game) {

	world_destroy(&game.world)
}


// Restart.

game_restart :: proc(game: ^Game) {


	player_reset(&game.player)


	world_destroy(&game.world)


	game.world = world_create()


	game.camera.target = game.player.position


	game.state = .PLAYING
}


// Input.

game_update_player :: proc(game: ^Game) {


	if rl.IsKeyDown(rl.KeyboardKey.W) {

		game.player.position.y -= game.move_speed
	}


	if rl.IsKeyDown(rl.KeyboardKey.S) {

		game.player.position.y += game.move_speed
	}


	if rl.IsKeyDown(rl.KeyboardKey.A) {

		game.player.position.x -= game.move_speed
	}


	if rl.IsKeyDown(rl.KeyboardKey.D) {

		game.player.position.x += game.move_speed
	}
}


// Update gameplay.

game_update_playing :: proc(game: ^Game) {


	game_update_player(game)


	world_update_spawning(&game.world, game.player.position)


	world_update_movement(&game.world)


	world_update_collisions(&game.world, &game.player)


	world_cleanup(&game.world, game.player.position)


	player_update_organism(&game.player, &game.world)


	game.camera.target = game.player.position


	if player_cell_count(&game.player, &game.world) >= WIN_REQUIRED_CELLS {


		game.state = .WON
	}
}


// Main update.

game_update :: proc(game: ^Game) {


	switch game.state {


	case .MENU:
		if ui_draw_menu() {

			game.state = .PLAYING
		}


	case .PLAYING:
		game_update_playing(game)


	case .WON:
		if ui_draw_win() {

			game_restart(game)
		}
	}
}


// Render.

game_render :: proc(game: ^Game) {


	switch game.state {


	case .MENU:
		rl.BeginDrawing()

		ui_draw_menu()

		rl.EndDrawing()


	case .PLAYING:
		rl.BeginDrawing()


		rl.ClearBackground(rl.BLACK)


		render_world(&game.player, &game.world, game.camera)


		ui_draw_stats(&game.player, player_cell_count(&game.player, &game.world))


		rl.EndDrawing()


	case .WON:
		rl.BeginDrawing()

		ui_draw_win()

		rl.EndDrawing()
	}
}
