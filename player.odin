package main

import rl "vendor:raylib"


PLAYER_START_HEALTH :: 100
PLAYER_START_ENERGY :: 100
PLAYER_START_MASS :: 1


Player :: struct {
	position:      rl.Vector2,
	root_children: [dynamic]Hex_ID,
	attributes:    Attributes,
	radius:        f32,
}


player_create :: proc() -> Player {

	return Player {
		position = {0, 0},
		root_children = make([dynamic]Hex_ID),
		attributes = {
			health = PLAYER_START_HEALTH,
			energy = PLAYER_START_ENERGY,
			mass = PLAYER_START_MASS,
		},
		radius = 35,
	}
}


player_reset :: proc(player: ^Player) {


	player.position = {0, 0}


	clear(&player.root_children)


	player.attributes = Attributes {
		health = PLAYER_START_HEALTH,
		energy = PLAYER_START_ENERGY,
		mass   = PLAYER_START_MASS,
	}


	player.radius = 35
}


player_add_attributes :: proc(player: ^Player, hex: ^Hex) {


	player.attributes.health += hex.attributes.health


	player.attributes.energy += hex.attributes.energy


	player.attributes.mass += hex.attributes.mass


	player.radius += f32(hex.attributes.mass) * 0.15
}


player_remove_attributes :: proc(player: ^Player, hex: ^Hex) {


	player.attributes.health -= hex.attributes.health


	player.attributes.energy -= hex.attributes.energy


	player.attributes.mass -= hex.attributes.mass
}


// Returns whether a socket can accept a child.

player_socket_free :: proc(parent: ^Hex, socket: int) -> bool {


	return !parent.socket_used[socket]
}


// Finds the closest open socket recursively.

player_find_socket_recursive :: proc(
	world: ^World,
	id: Hex_ID,
	best_id: ^Hex_ID,
	best_socket: ^int,
	best_distance: ^f32,
	target: rl.Vector2,
) {


	h := world_get_hex(world, id)


	if h == nil {
		return
	}


	for socket := 0; socket < 6; socket += 1 {


		if !player_socket_free(h, socket) {
			continue
		}


		position := hex_socket_position(h, socket)


		distance := rl.Vector2Distance(position, target)


		if distance < best_distance^ {

			best_distance^ = distance

			best_id^ = h.id

			best_socket^ = socket
		}


		for child in h.children {

			player_find_socket_recursive(world, child, best_id, best_socket, best_distance, target)
		}
	}


	// Finds attachment location.

	player_find_attachment :: proc(
		player: ^Player,
		world: ^World,
		target: rl.Vector2,
	) -> (
		Hex_ID,
		int,
	) {


		best_id := INVALID_HEX_ID

		best_socket := -1

		best_distance := f32(999999)


		for child in player.root_children {


			player_find_socket_recursive(
				world,
				child,
				&best_id,
				&best_socket,
				&best_distance,
				target,
			)
		}


		return best_id, best_socket
	}


	// Attach a new hex organically.

	player_attach_hex :: proc(player: ^Player, world: ^World, id: Hex_ID) {

		hex := world_get_hex(world, id)

		if hex == nil {
			return
		}

		parent_id, socket := player_find_attachment(player, world, hex.world_position)


		if parent_id == INVALID_HEX_ID {

			socket = len(player.root_children) % 6

			append(&player.root_children, id)

			hex.local_position = HEX_SOCKET_OFFSETS[socket]

		} else {

			parent := world_get_hex(world, parent_id)

			if parent == nil {
				return
			}

			append(&parent.children, id)

			parent.socket_used[socket] = true

			hex.parent = parent.id

			hex.local_position = HEX_SOCKET_OFFSETS[socket]
		}


		parent := world_get_hex(world, parent_id)


		if parent == nil {
			return
		}


		append(&parent.children, id)


		parent.socket_used[socket] = true


		hex.parent = parent.id


		hex.local_position = HEX_SOCKET_OFFSETS[socket]


		hex.active = false

		hex.attached = true


		player_add_attributes(player, hex)
	}
}


// Recursively updates attached positions.

player_update_hex_positions :: proc(world: ^World, id: Hex_ID, parent_position: rl.Vector2) {


	h := world_get_hex(world, id)


	if h == nil {
		return
	}


	h.world_position = parent_position + h.local_position


	for child in h.children {

		player_update_hex_positions(world, child, h.world_position)
	}
}


player_update_organism :: proc(player: ^Player, world: ^World) {


	for child in player.root_children {


		player_update_hex_positions(world, child, player.position)
	}
}


// Removes a complete branch.

player_destroy_branch :: proc(player: ^Player, world: ^World, id: Hex_ID) {


	h := world_get_hex(world, id)


	if h == nil {
		return
	}


	for child in h.children {

		player_destroy_branch(player, world, child)
	}


	player_remove_attributes(player, h)


	world_remove_hex(world, id)
}


// Count organism size.

player_count_cells_recursive :: proc(world: ^World, id: Hex_ID) -> int {


	h := world_get_hex(world, id)


	if h == nil {
		return 0
	}


	total := 1


	for child in h.children {

		total += player_count_cells_recursive(world, child)
	}


	return total
}


player_cell_count :: proc(player: ^Player, world: ^World) -> int {


	total := 0


	for id in player.root_children {

		total += player_count_cells_recursive(world, id)
	}


	return total
}
