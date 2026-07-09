

package main

import rl "vendor:raylib"


Hex_ID :: distinct u64

INVALID_HEX_ID :: Hex_ID(0)


Hex_Type :: enum {
	HEALTH,
	ENERGY,
	MASS,
	POISON,
	PARASITE,
}


Attributes :: struct {
	health: int,
	energy: int,
	mass:   int,
}


Hex :: struct {
	id:             Hex_ID,
	parent:         Hex_ID,
	children:       [dynamic]Hex_ID,
	attached:       bool,
	local_position: rl.Vector2,
	world_position: rl.Vector2,
	velocity:       rl.Vector2,
	color:          rl.Color,
	attributes:     Attributes,
	type:           Hex_Type,
	active:         bool,
	socket_used:    [6]bool,
}


HEX_RADIUS: f32 = 32


HEX_SOCKET_OFFSETS: [6]rl.Vector2 = {{0, -55}, {48, -28}, {48, 28}, {0, 55}, {-48, 28}, {-48, -28}}


hex_get_color :: proc(t: Hex_Type) -> rl.Color {

	switch t {

	case .HEALTH:
		return rl.GREEN

	case .ENERGY:
		return rl.YELLOW

	case .MASS:
		return rl.BLUE

	case .POISON:
		return rl.RED

	case .PARASITE:
		return rl.PURPLE
	}

	return rl.WHITE
}


hex_get_attributes :: proc(t: Hex_Type) -> Attributes {

	switch t {

	case .HEALTH:
		return Attributes{health = 10, energy = 0, mass = 1}


	case .ENERGY:
		return Attributes{health = 0, energy = 10, mass = 1}


	case .MASS:
		return Attributes{health = 0, energy = 0, mass = 10}


	case .POISON:
		return Attributes{health = -20, energy = -5, mass = 0}


	case .PARASITE:
		return Attributes{health = -5, energy = -20, mass = 0}
	}

	return {}
}


hex_is_negative :: proc(h: ^Hex) -> bool {

	return h.type == .POISON || h.type == .PARASITE
}


hex_can_merge :: proc(a: ^Hex, b: ^Hex) -> bool {

	if hex_is_negative(a) || hex_is_negative(b) {
		return false
	}


	// Same resource cells merge naturally.

	return a.type == b.type
}


hex_socket_position :: proc(parent: ^Hex, socket: int) -> rl.Vector2 {

	return parent.world_position + HEX_SOCKET_OFFSETS[socket]
}


hex_create :: proc(id: Hex_ID, position: rl.Vector2, t: Hex_Type) -> Hex {


	return Hex {
		id = id,
		parent = INVALID_HEX_ID,
		children = make([dynamic]Hex_ID),
		attached = false,
		local_position = {},
		world_position = position,
		velocity = {f32(rl.GetRandomValue(-2, 2)), f32(rl.GetRandomValue(-2, 2))},
		color = hex_get_color(t),
		attributes = hex_get_attributes(t),
		type = t,
		active = true,
		socket_used = {},
	}
}
