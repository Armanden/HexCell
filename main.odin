package main

import rl "vendor:raylib"

// okay so we need raygui for the title screen (probably dont even need raygui)
// [x] math/random for the randomly spawning hexagons
// [x] randomly spawining them in random positions on the screen and with different colours 14 colours i think is enough
// a system to merge hexagons and store their atributes
// and a way to check if the hexagon contains at minimum 16 other hexagons
import "core:math/rand"

Attributes :: struct {
	health: int,
	energy: int,
	mass:   int,
}


Hex :: struct {
	pos:        rl.Vector2,
	vel:        rl.Vector2,
	color:      rl.Color,
	active:     bool,
	parent:     int,
	children:   [dynamic]int,
	attributes: Attributes,
}


Player :: struct {
	pos:        rl.Vector2,
	children:   [dynamic]int,
	attributes: Attributes,
}


GameState :: enum {
	MENU,
	PLAYING,
	WON,
}


merge_hexes :: proc(hexes: ^[dynamic]Hex, parent, child: int) {

	append(&hexes[parent].children, child)

	hexes[child].parent = parent
	hexes[child].active = false

	hexes[parent].attributes.health += hexes[child].attributes.health
	hexes[parent].attributes.energy += hexes[child].attributes.energy
	hexes[parent].attributes.mass += hexes[child].attributes.mass
}


attach_to_player :: proc(player: ^Player, hexes: ^[dynamic]Hex, index: int) {

	append(&player.children, index)

	hexes[index].parent = -2
	hexes[index].active = false

	player.attributes.health += hexes[index].attributes.health
	player.attributes.energy += hexes[index].attributes.energy
	player.attributes.mass += hexes[index].attributes.mass
}


resolve_collision :: proc(a, b: ^Hex) {

	distance := rl.Vector2Distance(a.pos, b.pos)
	min_distance := f32(54)

	if distance < min_distance && distance > 0 {

		direction := (b.pos - a.pos) / distance

		push := (min_distance - distance) / 2

		a.pos -= direction * push
		b.pos += direction * push
	}
}


main :: proc() {

	rl.InitWindow(720, 720, "HexCell")
	rl.SetTargetFPS(60)


	player := Player {
		pos = {0, 0},
		attributes = {health = 100, energy = 100, mass = 1},
	}


	camera := rl.Camera2D {
		offset = {360, 360},
		target = player.pos,
		zoom   = 1,
	}


	hexes := make([dynamic]Hex)


	speed := f32(5)
	despawn_radius := f32(900)


	state := GameState.MENU


	for !rl.WindowShouldClose() {


		switch state {


		case .MENU:
			rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)


			rl.DrawText("HexCell", 260, 180, 40, rl.WHITE)


			rl.DrawText("Press ENTER to Start", 220, 350, 25, rl.GRAY)


			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
				state = .PLAYING
			}


			rl.EndDrawing()


		case .PLAYING:
			// PLAYER MOVEMENT

			if rl.IsKeyDown(rl.KeyboardKey.W) {
				player.pos.y -= speed
			}

			if rl.IsKeyDown(rl.KeyboardKey.S) {
				player.pos.y += speed
			}

			if rl.IsKeyDown(rl.KeyboardKey.A) {
				player.pos.x -= speed
			}

			if rl.IsKeyDown(rl.KeyboardKey.D) {
				player.pos.x += speed
			}


			camera.target = player.pos


			// COUNT ACTIVE HEXES

			active_count := 0

			for hex in hexes {
				if hex.active {
					active_count += 1
				}
			}


			// SPAWN

			for active_count < 30 {


				pos := rl.Vector2 {
					player.pos.x + f32(rand.int_range(-500, 500)),
					player.pos.y + f32(rand.int_range(-500, 500)),
				}


				append(
					&hexes,
					Hex {
						pos = pos,
						vel = {f32(rand.int_range(-2, 2)), f32(rand.int_range(-2, 2))},
						color = {
							u8(rand.int_range(50, 255)),
							u8(rand.int_range(50, 255)),
							u8(rand.int_range(50, 255)),
							255,
						},
						active = true,
						parent = -1,
						attributes = {health = 1, energy = 1, mass = 1},
					},
				)


				active_count += 1
			}
			// MOVE HEXES

			for &hex in hexes {

				if !hex.active do continue

				hex.pos += hex.vel


				if rl.Vector2Distance(hex.pos, player.pos) > 500 {

					hex.vel *= -1
				}
			}


			// COLLISION WITH PLAYER

			for i := 0; i < len(hexes); i += 1 {

				if !hexes[i].active do continue


				if rl.Vector2Distance(hexes[i].pos, player.pos) < 54 {

					attach_to_player(&player, &hexes, i)
				}
			}


			// HEX COLLISION + MERGING

			for i := 0; i < len(hexes); i += 1 {

				if !hexes[i].active do continue


				for j := i + 1; j < len(hexes); j += 1 {

					if !hexes[j].active do continue


					distance := rl.Vector2Distance(hexes[i].pos, hexes[j].pos)


					if distance < 54 {

						resolve_collision(&hexes[i], &hexes[j])


						merge_hexes(&hexes, i, j)
					}
				}
			}


			// REMOVE FAR HEXES

			for i := len(hexes) - 1; i >= 0; i -= 1 {


				if !hexes[i].active {
					continue
				}


				if rl.Vector2Distance(hexes[i].pos, player.pos) > despawn_radius {


					unordered_remove(&hexes, i)
				}
			}


			// WIN CONDITION

			if len(player.children) >= 16 {

				state = .WON
			}


			// DRAW GAME

			rl.BeginDrawing()

			rl.ClearBackground(rl.BLACK)


			rl.BeginMode2D(camera)


			// FREE HEXES

			for hex in hexes {

				if !hex.active do continue


				rl.DrawPoly(hex.pos, 6, 27, 0, hex.color)
			}


			// PLAYER

			rl.DrawPoly(player.pos, 6, 35, 0, rl.WHITE)


			// ATTACHED HEXES

			for i, child in player.children {


				offset := rl.Vector2{f32(i % 5) * 35, f32(i / 5) * 35}


				rl.DrawPoly(player.pos + offset, 6, 27, 0, hexes[child].color)
			}


			rl.EndMode2D()


			rl.EndDrawing()


		case .WON:
			rl.BeginDrawing()

			rl.ClearBackground(rl.BLACK)


			rl.DrawText("YOU WON!", 250, 250, 50, rl.GREEN)


			rl.DrawText("Press ENTER to restart", 190, 350, 25, rl.WHITE)


			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {


				player.pos = {0, 0}


				clear(&player.children)


				player.attributes = {
					health = 100,
					energy = 100,
					mass   = 1,
				}


				clear(&hexes)


				camera.target = player.pos


				state = .PLAYING
			}


			rl.EndDrawing()
		}
	}


	rl.CloseWindow()
}
