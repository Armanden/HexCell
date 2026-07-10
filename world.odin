package main

import "core:math/rand"
import rl "vendor:raylib"


WORLD_MAX_FREE_HEXES :: 40

WORLD_SPAWN_RADIUS :: 700.0
WORLD_DESPAWN_RADIUS :: 1400.0


World :: struct {
	hexes:          map[Hex_ID]^Hex,
	next_id:        Hex_ID,
	despawn_radius: f32,
}


world_create :: proc() -> World {

	return World {
		hexes = make(map[Hex_ID]^Hex),
		next_id = Hex_ID(1),
		despawn_radius = WORLD_DESPAWN_RADIUS,
	}
}


world_destroy :: proc(world: ^World) {

	delete(world.hexes)
}


world_get_hex :: proc(world: ^World, id: Hex_ID) -> ^Hex {


	if id == INVALID_HEX_ID {
		return nil
	}


	hex, ok := world.hexes[id]


	if !ok {
		return nil
	}


	return hex
}


world_add_hex :: proc(world: ^World, position: rl.Vector2, t: Hex_Type) -> Hex_ID {


	id := world.next_id

	world.next_id += 1


	hex := new(Hex)
	hex^ = hex_create(id, position, t)

	world.hexes[id] = hex


	return id
}


world_remove_hex :: proc(world: ^World, id: Hex_ID) {

	delete_key(&world.hexes, id)
}


world_free_hex_count :: proc(world: ^World) -> int {


	count := 0


	for _, h in world.hexes {

		if h.active {
			count += 1
		}
	}


	return count
}


world_random_type :: proc() -> Hex_Type {

	value := rand.int_range(0, 100)


	if value < 10 {
		return .POISON
	}


	if value < 15 {
		return .PARASITE
	}


	if value < 45 {
		return .HEALTH
	}


	if value < 70 {
		return .ENERGY
	}


	return .MASS
}


world_spawn_hex :: proc(world: ^World, player_position: rl.Vector2) {


	angle_x := f32(rand.int_range(-int(WORLD_SPAWN_RADIUS), int(WORLD_SPAWN_RADIUS)))


	angle_y := f32(rand.int_range(-int(WORLD_SPAWN_RADIUS), int(WORLD_SPAWN_RADIUS)))


	position := player_position + rl.Vector2{angle_x, angle_y}


	world_add_hex(world, position, world_random_type())
}


world_update_spawning :: proc(world: ^World, player_position: rl.Vector2) {


	for world_free_hex_count(world) < WORLD_MAX_FREE_HEXES {


		world_spawn_hex(world, player_position)
	}
}


resolve_collision :: proc(a: ^Hex, b: ^Hex) {


	distance := rl.Vector2Distance(a.world_position, b.world_position)


	if distance <= 0 {
		return
	}


	min_distance: f32 = 54.0


	if distance < min_distance {


		direction := (b.world_position - a.world_position) / distance


		push := (min_distance - distance) / 2


		a.world_position -= direction * push


		b.world_position += direction * push
	}
}

world_update_movement :: proc(world: ^World) {

	for _, h in world.hexes {

		if h == nil {
			continue
		}

		if !h.active {
			continue
		}

		h.world_position += h.velocity

		if rl.GetRandomValue(0, 1000) < 5 {
			h.velocity.x *= -1
			h.velocity.y *= -1
		}
	}
}


world_try_merge :: proc(world: ^World, a_id: Hex_ID, b_id: Hex_ID) {


	a := world_get_hex(world, a_id)


	b := world_get_hex(world, b_id)


	if a == nil || b == nil {
		return
	}


	if !hex_can_merge(a, b) {

		resolve_collision(a, b)

		return
	}


	append(&a.children, b.id)


	b.parent = a.id

	b.attached = true

	b.active = false


	a.attributes.health += b.attributes.health

	a.attributes.energy += b.attributes.energy

	a.attributes.mass += b.attributes.mass
}


world_update_collisions :: proc(world: ^World, player: ^Player) {


	ids := make([dynamic]Hex_ID)

	defer delete(ids)


	for id, _ in world.hexes {

		append(&ids, id)
	}


	// Player collects nearby hexes

	for id in ids {


		h := world_get_hex(world, id)


		if h == nil {
			continue
		}


		if !h.active {
			continue
		}


		distance := rl.Vector2Distance(h.world_position, player.position)


		if distance < 54 {


			player_attach_hex(player, world, h.id)


			continue
		}
	}


	// Hex-to-hex collision and merging

	for i := 0; i < len(ids); i += 1 {


		for j := i + 1; j < len(ids); j += 1 {


			a := world_get_hex(world, ids[i])


			b := world_get_hex(world, ids[j])


			if a == nil || b == nil {
				continue
			}


			if !a.active || !b.active {
				continue
			}


			distance := rl.Vector2Distance(a.world_position, b.world_position)


			if distance < 54 {


				resolve_collision(a, b)


				world_try_merge(world, a.id, b.id)
			}
		}
	}
}
world_cleanup :: proc(world: ^World, player_position: rl.Vector2) {


	to_remove := make([dynamic]Hex_ID)

	defer delete(to_remove)


	for id, h in world.hexes {


		if !h.active {
			continue
		}


		distance := rl.Vector2Distance(h.world_position, player_position)


		if distance > world.despawn_radius {

			append(&to_remove, id)
		}
	}


	for id in to_remove {

		delete_key(&world.hexes, id)
	}
}
