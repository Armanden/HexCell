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
	rl.InitWindow(720, 720, "HexaCell")
	rl.SetTargetFPS(60)

	center := rl.Vector2{0, 0}

	camera := rl.Camera2D {
		offset   = {360, 360},
		target   = {0, 0},
		rotation = 0,
		zoom     = 1,
	}

	speed := f32(5)
	hexes: [50]Hex
	// Generate random hexagons
	for i in 0 ..< len(hexes) {
		hexes[i] = Hex {
			pos   = {f32(rand.int_range(-500, 500)), f32(rand.int_range(-500, 500))},
			vel   = {f32(rand.float64_range(-1, 1)), f32(rand.float64_range(-1, 1))},
			color = {
				u8(rand.int_range(50, 255)),
				u8(rand.int_range(50, 255)),
				u8(rand.int_range(50, 255)),
				255,
			},
		}
	}
	// got a rendering problem where the hexes only generate in the 720x720 screen space
	// they should be rendering according to the camera
	for !rl.WindowShouldClose() {

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
		// Move hexagons
		for &hex in hexes {
			hex.pos += hex.vel

			// Bounce around
			if hex.pos.x > 500 || hex.pos.x < -500 {
				hex.vel.x *= -1
			}

			if hex.pos.y > 500 || hex.pos.y < -500 {
				hex.vel.y *= -1
			}
		}
		// Keep the main hex centered under camera
		center = camera.target

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(camera)
		// Draw moving hexagons
		for hex in hexes {
			rl.DrawPoly(hex.pos, 6, 27, 0, hex.color)
		}

		//main drawing
		rl.DrawPoly(center, 6, 27, 0, rl.WHITE)
		rl.DrawCircle(0, 0, 5, rl.RED)

		rl.EndMode2D()

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
