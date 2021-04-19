module main

// import glfw
import gg
import gx
import time
// import freetype

const (
	block_size   = 60 // pixels
	t_offset_x   = block_size / 4 // offset for text
	t_offset_y   = block_size / 2
	field_height = 8
	field_width  = 8
	win_width    = block_size * (field_width + 4)
	win_height   = block_size * field_height
	time_period  = 250 // ms
	text_size    = 12

	// n for knight (k for king)
	pieces       = map{
		'kw': '♔'
		'qw': '♕'
		'rw': '♖'
		'bw': '♗'
		'nw': '♘'
		'pw': '♙'
		'kb': '♚'
		'qb': '♛'
		'rb': '♜'
		'bb': '♝'
		'nb': '♞'
		'pb': '♟'
	}

	text_cfg     = gx.TextCfg{
		align: .left
		size: text_size
		color: gx.rgb(0, 0, 0)
	}

	dark_white   = gx.rgb(227, 225, 218)
	dark_grey    = gx.rgb(145, 144, 141)
	highlight    = gx.rgb(227, 230, 85)

	directions   = ['nn', 'ne', 'ee', 'se', 'ss', 'sw', 'ww', 'nw']

	rows         = 'abcdefgh'
)

/*
Utility to reverse a map, since int -> string maps
 aren't available.

 :param m map to reverse
 :param v value to get key for

 :return ?string string if key was found, error if key was not found
*/
fn rev_map(m map[string]int, v int) ?string {
	for k in m.keys() {
		if m[k] == v {
			return k
		}
	}
	return error('Key for value $v not found')
}

fn add(a []int, b []int) []int {
	return [a[0] + b[0], a[1] + b[1]]
}

/*
Simple enum to represent a color.
 This enum represents the color of squares and pieces.
 Note that this must be named Color_ to avoid conflicting
 with glfw.Color (https://github.com/vlang/v/issues/2416)
*/
enum Color_ {
	black
	white
}

/*
Flip a color (e.g. reverse its value; black -> white; white -> black)
 :param c color to flip
 :return Color flipped color
*/
fn flip(c Color_) Color_ {
	match c {
		.black { return .white }
		else { return .black }
	}
}

/*
Convert color to a string for output.
*/
fn str(c Color_) string {
	match c {
		.black { return ' ⬛ ' }
		else { return ' ⬜ ' }
	}
}

fn to_color(c Color_) gx.Color {
	match c {
		.black { return gx.rgb(168, 173, 170) }
		else { return gx.rgb(255, 255, 255) }
	}
}

/*
Describe a piece object.
*/
struct Piece {
mut:
	typ string
}

fn (p Piece) str() string {
	return ' ' + p.typ + ' '
}

fn (p Piece) color() Color_ {
	match p.typ[1].str() {
		'b' { return .black }
		else { return .white }
	}
}

/*
Represents a square on the board
*/
struct Square {
	x     int
	y     int
	color Color_
mut:
	piece Piece
}

fn (s Square) str() string {
	return rows[s.x].str() + s.y.str()
	// return str(s.color) + s.piece.str()
}

fn (s Square) equals(other Square) bool {
	return s.x == other.x && s.y == other.y
}

fn (a []Square) contains(s Square) bool {
	for i in a {
		if i.equals(s) {
			return true
		}
	}
	return false
}

fn (s Square) + (b Square) []int {
	// return add([s.x, s.y], b)
	return [s.x + b.x, s.y + b.y]
}

const (
	click_off = Square{
		x: -1
		y: -1
		piece: Piece{
			typ: ' '
		}
	}
)

struct Move {
	piece Piece
	from  Square
	to    Square
}

fn (m Move) str() string {
	return m.piece.typ[0].str() + m.to.str()
}

struct Game {
mut:
	gg &gg.Context = voidptr(0)
	// ft &freetype.Context
	
	board   [][]Square
	history []Move

	mouse_x f64
	mouse_y f64

	selected    Square
	highlighted []Square
}

fn (mut g Game) initialize_game() {
	mut board := map[string]string{}
	board['0'] = 'rnbqkbnr'
	board['1'] = 'pppppppp'
	board['6'] = 'pppppppp'
	board['7'] = 'rnbqkbnr'

	mut r_to_c := map[string]string{}
	r_to_c['0'] = 'b'
	r_to_c['1'] = 'b'
	r_to_c['6'] = 'w'
	r_to_c['7'] = 'w'

	mut color := Color_.white
	for x := 0; x < 8; x++ {
		g.board << []Square{}
		for y := 0; y < 8; y++ {
			mut p := Piece{
				typ: ' '
			}
			sx := x.str()
			if sx in board {
				p.typ = board[sx][y].str() + r_to_c[sx]
			}
			g.board[x] << Square{
				x: x
				y: y
				color: color
				piece: p
			}
			color = flip(color)
		}
		color = flip(color)
	}

	g.selected = click_off
	g.highlighted = []Square{}
}

fn (g Game) str() string {
	mut s := ''
	spacer := '-'.repeat(g.board.len * 8)
	for i := 0; i < g.board.len; i++ {
		s += spacer + '\n'
		for sq in g.board[i] {
			s += '| ' + pieces[sq.piece.typ] + ' '
		}
		s += '|\n'
	}
	s += spacer
	return s
}

fn (g Game) at(i []int) ?Square {
	if 0 <= i[0] && i[0] < 8 && 0 <= i[1] && i[1] < 8 {
		r := g.board[i[0]]
		return r[i[1]]
	}
	return error('$i out of bounds')
}

struct Position {
mut:
	x int
	y int
}

fn (p Position) str() string {
	return '($p.x, $p.y)'
}

fn of(i []int) Position {
	return Position{
		x: i[0]
		y: i[1]
	}
}

fn (g Game) moves(s Square) []Square {
	mut ret := []Square{}

	// String -> Array dictionaries don't work for some reason
	mut nn := []Position{}
	mut ne := []Position{}
	mut ee := []Position{}
	mut se := []Position{}
	mut ss := []Position{}
	mut sw := []Position{}
	mut ww := []Position{}
	mut nw := []Position{}

	match s.piece.typ[0].str() {
		' ' {
			return ret
		}
		'k' {
			nn << of([0, 1])
			ne << of([1, 1])
			ee << of([1, 0])
			se << of([1, -1])
			ss << of([0, -1])
			sw << of([-1, -1])
			ww << of([-1, 0])
			nw << of([-1, 1])
		}
		'q' {
			for i := 1; i < 8; i++ {
				nn << of([0, i])
				ne << of([i, i])
				ee << of([i, 0])
				se << of([i, -i])
				ss << of([0, -i])
				sw << of([-i, -i])
				ww << of([-i, 0])
				nw << of([-i, i])
			}
		}
		'r' {
			for i := 1; i < 8; i++ {
				nn << of([0, i])
				ee << of([i, 0])
				ss << of([0, -i])
				ww << of([-i, 0])
			}
		}
		'b' {
			for i := 1; i < 8; i++ {
				ne << of([i, i])
				se << of([i, -i])
				sw << of([-i, -i])
				nw << of([-i, i])
			}
		}
		'n' {
			ne << of([2, 1])
			nw << of([-2, 1])
			se << of([2, -1])
			sw << of([-2, -1])
		}
		'p' {
			// TODO: pawn caps
			if s.piece.color() == .white {
				nn << of([-1, 0])
				if s.x == 6 {
					nn << of([-2, 0])
				}
				hit := g.at([s.x - 1, s.y - 1]) or { panic(err) }
				if hit.piece.typ != ' ' {
					if hit.piece.color() != s.piece.color() {
						nw << of([-1, -1])
					}
				}

				hit2 := g.at([s.x - 1, s.y + 1]) or { panic(err) }
				if hit2.piece.typ != ' ' {
					if hit2.piece.color() != s.piece.color() {
						ne << of([-1, 1])
					}
				}
			} else {
				nn << of([1, 0])
				if s.x == 1 {
					nn << of([2, 0])
				}
				hit := g.at([s.x + 1, s.y - 1]) or { panic(err) }
				if hit.piece.typ != ' ' {
					if hit.piece.color() != s.piece.color() {
						nw << of([-1, -1])
					}
				}

				hit2 := g.at([s.x + 1, s.y + 1]) or { panic(err) }
				if hit2.piece.typ != ' ' {
					if hit2.piece.color() != s.piece.color() {
						ne << of([-1, 1])
					}
				}
			}
		}
		else {}
	}
	for i in [nn, ne, ee, se, ss, sw, ww, nw] {
		for m in i {
			hit := g.at([s.x + m.x, s.y + m.y]) or { break }
			if hit.piece.typ == ' ' {
				ret << hit
			} else if hit.piece.color() != s.piece.color() && !(s.piece.typ[0].str() == 'p'
				&& m.y == 0) {
				ret << hit
				break
			} else {
				break
			}
		}
	}

	return ret
}

fn (mut g Game) draw_square(s Square) {
	mut color := to_color(s.color)
	mut oy := t_offset_y
	if s.equals(g.selected) && s.piece.typ != ' ' {
		if s.color == .black {
			color = dark_grey
		} else {
			color = dark_white
		}
		oy -= 5
		g.moves(s)
	} else if s in g.highlighted {
		color = highlight
	}
	g.gg.draw_rect((s.y) * block_size, (s.x) * block_size, block_size - 1, block_size - 1,
		color)
	g.gg.draw_text((s.y) * block_size + t_offset_x, (s.x) * block_size + oy, pieces[s.piece.typ],
		text_cfg)
}

fn render(mut g Game) {
	for row in g.board {
		for sq in row {
			g.draw_square(sq)
		}
	}

	g.gg.draw_text(block_size * 8, block_size, 'Moves', text_cfg)

	mut i := 1
	for move in g.history {
		i += 1
		x := 8 + 2 * (i % 2)
		y := i / 2 + 1
		g.gg.draw_text(block_size * x, block_size * y, move.str(), text_cfg)
	}

	// g.gg.render()
}

fn (g Game) run() {
	for {
		// glfw.post_empty_event() // force window redraw
		time.sleep(time_period * time.millisecond)
	}
}

fn (mut g Game) handle_select() {
	if g.highlighted.len == 0 {
		g.highlighted = g.moves(g.selected)
	}
}

fn (mut game Game) on_move(x f64, y f64) {
	// mut game := &Game{gg: 0} // glfw.get_window_user_pointer(wnd))

	game.mouse_x = x
	game.mouse_y = y
}

/*
Access click method
 :param click button (0: left, 1: right, etc)
 :param on 0 -> off, 1 -> on
*/
fn (mut game Game) on_click(click int, on int) {
	if on == 1 && click == 0 {
		// mut game := &Game{gg: 0} // glfw.get_window_user_pointer(wnd))

		box_y := int(game.mouse_x / block_size)
		box_x := int(game.mouse_y / block_size)

		if box_x != game.selected.x || box_y != game.selected.y {
			hit := game.at([box_x, box_y]) or { panic(err) }
			if hit in game.highlighted {
				mut r := game.board[box_x]
				r[box_y].piece.typ = game.selected.piece.typ

				sx := game.selected.x
				sy := game.selected.y
				mut r2 := game.board[sx]
				r2[sy].piece.typ = ' '

				game.history << Move{
					piece: game.selected.piece
					from: r2[sy]
					to: r[box_y]
				}

				game.selected = click_off
				game.highlighted = []Square{}
			} else {
				row := game.board[box_x] // no multiindexing (gh issue?)
				game.highlighted = []Square{}
				game.selected = row[box_y]
			}
		} else {
			game.selected = click_off
			game.highlighted = []Square{}
		}

		game.handle_select()
	}
}

fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .touches_ended {
		if e.num_touches > 0 {
			touch_point := e.touches[0]
			game.on_click()
		}
	} else if e.typ == .touches_moved {
		game.on_move()
	}
}

fn main() {
	// glfw.init_glfw()

	mut game := Game{
		gg: 0
	}

	game.gg = gg.new_context(
		bg_color: gx.white
		width: win_width
		height: win_height
		use_ortho: true // This is needed for 2D drawing
		create_window: true
		window_title: 'V Chess'
		user_data: game
		frame_fn: render
		event_fn: on_event
		font_path: 'RobotoMono-Regular.ttf'
		// window_user_ptr: &game
	)

	// game.ft = freetype.new_context(gg.Cfg{
	// 	width: win_width
	// 	height: win_height
	// 	use_ortho: true
	// 	font_size: 54
	// 	scale: 2
	// })

	// game.gg.window.set_user_ptr(&game)
	game.initialize_game()

	// game.gg.window.on_click(on_click)
	// game.gg.window.onmousemove(on_move)

	go game.run()
	game.gg.run()

	// for {
	// 	gg.clear(gx.White)
	// 	game.render()
	// 	if game.gg.window.should_close() {
	// 		game.gg.window.destroy()
	// 		return
	// 	}
	// }

	return
}
