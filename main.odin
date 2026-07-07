package main

import rl "vendor:raylib"

//okay so we need raygui for the title screen (probably dont even need raygui)
// math/random for the randomly spawning hexagons
// randomly spawining them in random positions on the screen and with different colours 14 colours i think is enough
// a system to merge hexagons and store their atributes
// and a way to check if the hexagon contains at minimum 16 other hexagons
import "core:math/rand"


Hex :: struct {
	pos:   rl.Vector2,
	vel:   rl.Vector2,
	color: rl.Color,
}

main :: proc() {
	rl.InitWindow(720, 720, "HexCell")
	rl.SetTargetFPS(60)

	camera := rl.Camera2D {
		offset = {360, 360},
		target = {0, 0},
		zoom   = 1,
	}

	speed := f32(5)

	hexes := make([dynamic]Hex)

	spawn_radius := f32(500)
	despawn_radius := f32(800)


	for !rl.WindowShouldClose() {

		// Camera movement
		if rl.IsKeyDown(rl.KeyboardKey.W) {
			camera.target.y -= speed
		}
		if rl.IsKeyDown(rl.KeyboardKey.S) {
			camera.target.y += speed
		}
		if rl.IsKeyDown(rl.KeyboardKey.A) {
			camera.target.x -= speed
		}
		if rl.IsKeyDown(rl.KeyboardKey.D) {
			camera.target.x += speed
		}


		if len(hexes) < 10 {
			for i in 0 ..< 1 {
				append(
					&hexes,
					Hex {
						pos = {
							camera.target.x + f32(rand.int_range(-500, 500)),
							camera.target.y + f32(rand.int_range(-500, 500)),
						},
						vel = rl.Vector2{f32(rand.int_range(-2, 2)), f32(rand.int_range(-2, 2))},
						color = {
							u8(rand.int_range(50, 255)),
							u8(rand.int_range(50, 255)),
							u8(rand.int_range(50, 255)),
							255,
						},
					},
				)
			}
		}

		// Move hexes
		for &hex in hexes {
			hex.pos.x += hex.vel.x
			hex.pos.y += hex.vel.y

			// keep them from drifting forever
			if hex.pos.x > camera.target.x + 500 || hex.pos.x < camera.target.x - 500 {
				hex.vel.x *= -1
			}

			if hex.pos.y > camera.target.y + 500 || hex.pos.y < camera.target.y - 500 {
				hex.vel.y *= -1
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(camera)


		for hex in hexes {
			rl.DrawPoly(hex.pos, 6, 27, 0, hex.color)
		}


		// Center cursor
		rl.DrawPoly(camera.target, 6, 27, 0, rl.WHITE)

		rl.EndMode2D()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
