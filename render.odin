package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

// Draw a single hex cell.

draw_hex :: proc(h: ^Hex) {


	rl.DrawPoly(h.world_position, 6, HEX_RADIUS, 0, h.color)
}


// Recursively render organism branches.

draw_hex_branch :: proc(world: ^World, id: Hex_ID) {


	h := world_get_hex(world, id)


	if h == nil {
		return
	}


	draw_hex(h)


	for child in h.children {

		draw_hex_branch(world, child)
	}
}


// Draw free cells.

draw_world_hexes :: proc(world: ^World) {


	for id in world.hexes {


		h := world_get_hex(world, id)


		if h == nil {
			continue
		}


		if h.active {

			draw_hex(h)
		}
	}
}


// Draw player body and attached cells.

draw_player :: proc(player: ^Player, world: ^World) {


	rl.DrawPoly(player.position, 6, 40, 0, rl.WHITE)


	for id in player.root_children {


		draw_hex_branch(world, id)
	}
}


// World renderer.

render_world :: proc(player: ^Player, world: ^World, camera: rl.Camera2D) {


	rl.BeginMode2D(camera)


	draw_world_hexes(world)


	draw_player(player, world)


	rl.EndMode2D()
}


// Draw HUD.

render_hud :: proc(player: ^Player, cells: int) {


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
