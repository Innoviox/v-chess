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
	mut: typ string
}

fn (p Piece) str() string {
	return ' ' + p.typ + ' '
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
	// if s.piece.typ != '' {
		// return 
	// }
	return str(s.color) + s.piece.str()
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

fn (g mut Game) initialize_game() {
	mut pieces := map[string]string
	pieces['kw'] = '♔'
	pieces['qw'] = '♕'
	pieces['rw'] = '♖'
	pieces['bw'] = '♗'
	pieces['nw'] = '♘' // n for knight (k for king)
	pieces['pw'] = '♙'

	pieces['kb'] = '♚'
	pieces['qb'] = '♛'
	pieces['rb'] = '♜'
	pieces['bb'] = '♝'
	pieces['nb'] = '♞' 
	pieces['pb'] = '♟'

	mut board := map[string]string
	board['0'] = 'rnbqkbnr'
	board['1'] = 'pppppppp'
	board['6'] = 'pppppppp'
	board['7'] = 'rnbqkbnr'

	mut r_to_c := map[string]string
	r_to_c['0'] = 'b'
	r_to_c['1'] = 'b'
	r_to_c['6'] = 'w'
	r_to_c['7'] = 'w'

	mut color := Color.white
	for x := 0; x < 8; x++ {
		g.board << []Square
		for y := 0; y < 8; y++ {
			mut p := Piece{typ: ' '}
			sx := x.str()
			if sx in board {
				p.typ = pieces[board[sx][y].str() + r_to_c[sx]]
			}
			g.board[x] << Square{x: x, y: y, color: color, piece: p}
			color = flip(color)
		}
		color = flip(color)
	}
}

fn (g Game) str() string {
	mut s := ''
	spacer := '-'.repeat(g.board.len * 8)
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
	mut game := Game{}
	game.initialize_game()

	println(game)
	return
}