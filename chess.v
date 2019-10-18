module main

// import glfw
// import os

/* 
 Utility to reverse a map, since int -> string maps 
 aren't available.

 :param m map to reverse
 :param v value to get key for

 :return ?string string if key was found, error if key was not found
*/
fn rev_map(m map[string]int v int) ?string {
	for k in m.keys() {
		if m[k] == v {
			return k
		}
	}
	return error("Key for value $v not found")
}

/*
 Simple enum to represent a color.
 This enum represents the color of squares and pieces.
*/
enum Color { 
	black white
}

/*
 Flip a color (e.g. reverse its value; black -> white; white -> black)
 :param c color to flip
 :return Color flipped color
*/
fn flip(c Color) Color {
	match c {
		.black => { return .white }
		else   => { return .black }
	}
}

/*
 Convert color to a string for output.
*/
fn str(c Color) string {
	match c {
		.black => { return ' ⬛ '}
		else   => { return ' ⬜ '}
	}
}

/*
 Describe a piece object.
*/
struct Piece {
mut:
	typ int
	color Color
}

/*
 Since there are no globals, each Piece would have
 had to hold its own piece -> str map (inefficient),
 so we lose the "builtin" str method".
*/
fn (p Piece) str(p_map map[string]int) string {
	if p.typ == 0 { // no piece on square, render square beneath
		return p.color.str()
	}

	s := rev_map(p.p_map, p.typ) or {
		return ' ${p.typ.str()} ' // error happened here, show typ for debugging
	}

	return s
}


/*
 Represents a square on the board
*/
struct Square {
	x int
	y int
	color Color
mut:
	piece Piece
}

fn (s Square) str() string {
	return s.piece.str()
}

struct Move {
	piece int
	sq Square
}

struct Game {
	pieces map[string]int
mut:
	board [][]Square
	history []Move
	
}

fn (g mut Game) initialize_game(pieces [][]Piece) {
	mut color := Color.black
	for x := 0; x < 8; x++ {
		g.board << []Square
		for y := 0; y < 8; y++ {
			g.board[x] << Square{x: x, y: y, color: color}
			color = flip(color)
		}
		color = flip(color)
	}
}

fn (g Game) str() string {
	mut s := ''
	spacer := '-'.repeat(g.board.len * 5)
	for i := 0; i < g.board.len; i++ {
		s += spacer + '\n'
		for sq in g.board[i] {
			s += '|' + sq.str()
		}
		s += '|\n'
		// s += g.board[i].str() + "\n"
	}
	s += spacer
	return s
}


fn main() {

	mut game := Game{pieces: pieces}
	game.initialize_game()

	println(game)
	return
}