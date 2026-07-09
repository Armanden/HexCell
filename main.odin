package main

import rl "vendor:raylib"


main :: proc() {


	rl.InitWindow(720, 720, "HexCell")


	rl.SetTargetFPS(60)


	game := game_create()


	for !rl.WindowShouldClose() {


		switch game.state {


		case .MENU:
			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {

				game.state = .PLAYING
			}


		case .PLAYING:
			game_update_playing(&game)


		case .WON:
			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {

				game_restart(&game)
			}
		}


		rl.BeginDrawing()


		switch game.state {


		case .MENU:
			ui_draw_menu()


		case .PLAYING:
			rl.ClearBackground(rl.BLACK)


			render_world(&game.player, &game.world, game.camera)


			ui_draw_stats(&game.player, player_cell_count(&game.player, &game.world))


		case .WON:
			ui_draw_win()
		}


		rl.EndDrawing()
	}


	game_destroy(&game)


	rl.CloseWindow()
}
