import glfw

enum Piece {
	// TODO
}

struct Square {
	x int
	y int
}

struct Move {
	piece Piece
	sq Square
}

struct Game {
	mut:
	board [][]int
	history []Move
}