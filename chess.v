module main

import glfw
import gg
import gx
import time
import freetype

const (
	BlockSize = 60 // pixels
	T_OffsetX = BlockSize / 4 // offset for text
	T_OffsetY = BlockSize / 2
	FieldHeight = 8
	FieldWidth = 8
	WinWidth = BlockSize * FieldWidth
	WinHeight = BlockSize * FieldHeight
	TimerPeriod = 250 // ms
	TextSize = 12

	// n for knight (k for king)
	pieces = {
		'kw': '♔',
		'qw': '♕',
		'rw': '♖',
		'bw': '♗',
		'nw': '♘',
		'pw': '♙',
		'kb': '♚',
		'qb': '♛',
		'rb': '♜',
		'bb': '♝',
		'nb': '♞',
		'pb': '♟'
	}

	text_cfg = gx.TextCfg{
		align: gx.ALIGN_LEFT
		size:  TextSize
		color: gx.rgb(0, 0, 0)
	}

	dark_white = gx.rgb(227, 225, 218)
	dark_grey  = gx.rgb(145, 144, 141)
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
		.black => { return gx.rgb(168, 173, 170)}
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

fn (s Square) equals(other Square) bool {
	return s.x == other.x && s.y == other.y
}

const (	
	click_off = Square{x: -1, y: -1}
)

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

	mouse_x f64
	mouse_y f64

	selected Square
	highlighted []Square
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

	g.selected = click_off
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
	mut color := to_color(s.color)
	mut _oy := T_OffsetY
	if s.equals(g.selected) {
		if s.color == .black {
			color = dark_grey
		} else {
			color = dark_white
		}
		_oy -= 5
	}
	g.gg.draw_rect((s.y) * BlockSize, (s.x) * BlockSize,
					BlockSize - 1, BlockSize - 1, color)
	g.ft.draw_text((s.y) * BlockSize + T_OffsetX, (s.x) * BlockSize + _oy, 
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
		glfw.post_empty_event() // force window redraw
		time.sleep_ms(TimerPeriod)
	}
}

fn (g Game) handle_select() {
	// TODO: add things to highlighted
}

fn on_move(wnd voidptr, x, y f64) {
	mut game := &Game(glfw.get_window_user_pointer(wnd))

	game.mouse_x = x
	game.mouse_y = y
}
/*
 Access click method
 :param click button (0: left, 1: right, etc)
 :param on 0 -> off, 1 -> on
*/
fn on_click(wnd voidptr, click, on int) {
	if on == 1 && click == 0 {
		mut game := &Game(glfw.get_window_user_pointer(wnd))

		box_y := int(game.mouse_x / BlockSize)
		box_x := int(game.mouse_y / BlockSize)

		if box_x != game.selected.x || box_y != game.selected.y {
			row := game.board[box_x] // no multiindexing (gh issue?)
			game.selected = row[box_y]
		} else {
			game.selected = click_off
		}
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
		font_size: 54
		scale: 2
	})

	game.gg.window.set_user_ptr(&game)
	game.initialize_game()

	game.gg.window.on_click(on_click)
	game.gg.window.onmousemove(on_move)

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