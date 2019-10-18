module main

import glfw
import gg
import gx
import time
import freetype

const (
	BlockSize = 20 // pixels
	Offset = BlockSize / 4
	FieldHeight = 8
	FieldWidth = 8
	WinWidth = BlockSize * FieldWidth
	WinHeight = BlockSize * FieldHeight
	TimerPeriod = 250 // ms
	TextSize = 12

	// n for knight (k for king)
	pieces = {
		'kb': '♔',
		'qb': '♕',
		'rb': '♖',
		'bb': '♗',
		'nb': '♘',
		'pb': '♙',
		'kw': '♚',
		'qw': '♛',
		'rw': '♜',
		'bw': '♝',
		'nw': '♞',
		'pw': '♟'
	}

	text_cfg = gx.TextCfg{
		align: gx.ALIGN_LEFT
		size:  TextSize
		color: gx.rgb(0, 0, 0)
	}
)

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
 Note that this must be named Color_ to avoid conflicting
 with glfw.Color (https://github.com/vlang/v/issues/2416)
*/
enum Color_ { 
	black white
}

/*
 Flip a color (e.g. reverse its value; black -> white; white -> black)
 :param c color to flip
 :return Color flipped color
*/
fn flip(c Color_) Color_ {
	match c {
		.black => { return .white }
		else   => { return .black }
	}
}

/*
 Convert color to a string for output.
*/
fn str(c Color_) string {
	match c {
		.black => { return ' ⬛ '}
		else   => { return ' ⬜ '}
	}
}

fn to_color(c Color_) gx.Color {
	match c {
		.black => { return gx.rgb(0, 0, 0)}
		else   => { return gx.rgb(255, 255, 255)}
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
	color Color_
mut:
	piece Piece
}

fn (s Square) str() string {
	return str(s.color) + s.piece.str()
}

struct Move {
	piece int
	sq Square
}

struct Game {	
	gg &gg.GG
mut:
	ft &freetype.Context
	board [][]Square
	history []Move
}

fn (g mut Game) initialize_game() {
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

	mut color := Color_.white
	for x := 0; x < 8; x++ {
		g.board << []Square
		for y := 0; y < 8; y++ {
			mut p := Piece{typ: ''}
			sx := x.str()
			if sx in board {
				p.typ = board[sx][y].str() + r_to_c[sx]
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
	}
	s += spacer
	return s
}

fn (g mut Game) draw_square(s Square) {
	g.gg.draw_rect((s.y - 1) * BlockSize, (s.x - 1) * BlockSize,
					BlockSize - 1, BlockSize - 1, to_color(s.color))
	g.ft.draw_text((s.y - 1) * BlockSize + Offset, (s.x - 1) * BlockSize + Offset, 
					pieces[s.piece.typ], text_cfg)
}

fn (g mut Game) render() {
	for row in g.board {
		for sq in row {
			g.draw_square(sq)
		}
	}
	g.gg.render()
}
 
fn (g Game) run() {
	for {
		// if g.state == .running {
		// 	g.move_tetro()
		// 	g.delete_completed_lines()
		// }
		glfw.post_empty_event() // force window redraw
		time.sleep_ms(TimerPeriod)
	}
}

fn main() {
	glfw.init_glfw()

	mut game := Game{
		gg: gg.new_context(gg.Cfg {
			width: WinWidth
			height: WinHeight
			use_ortho: true // This is needed for 2D drawing
			create_window: true
			window_title: 'V Chess'
			// window_user_ptr: &game
		})
	}

	game.ft = freetype.new_context(gg.Cfg{
		width: WinWidth
		height: WinHeight
		use_ortho: true
		font_size: 18
		scale: 2
	})

	game.gg.window.set_user_ptr(&game)
	game.initialize_game()

	go game.run()

	for {
		gg.clear(gx.White)
		game.render()
		if game.gg.window.should_close() {
			game.gg.window.destroy()
			return
		}
	}

	return
}