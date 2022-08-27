// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import sdl

fn (mut s Shy) quit_requested() bool {
	return sdl.quit_requested()
}

fn (mut s Shy) poll_event() ?Event {
	evt := sdl.Event{}
	if 0 < sdl.poll_event(&evt) {
		match evt.@type {
			.windowevent {
				// if sdl.WindowEventID(int(evt.window.event)) == .focus_lost {
				//	s.shutdown = true
				//}
				wevid := sdl.WindowEventID(int(evt.window.event))
				win := s.active_window()
				if wevid == .resized {
					return WindowEvent{
						timestamp: s.ticks()
						kind: .resized
						window: win // TODO multi-window support
					}
				}
			}
			.quit {
				return QuitEvent{
					timestamp: s.ticks()
				}
			}
			.keyup {
				shy_key_code := map_sdl_to_shy_keycode(evt.key.keysym.sym)
				return KeyEvent{
					timestamp: s.ticks()
					state: .up
					key_code: shy_key_code
				}
			}
			.keydown {
				shy_key_code := map_sdl_to_shy_keycode(evt.key.keysym.sym)
				return KeyEvent{
					timestamp: s.ticks()
					state: .down
					key_code: KeyCode(int(shy_key_code))
				}
			}
			.mousemotion {
				buttons := map_sdl_button_mask_to_shy_mouse_buttons(evt.motion.state)
				win := s.active_window()
				return MouseMotionEvent{
					timestamp: s.ticks()
					window_id: win.id // TODO multi-window support
					which: evt.motion.which // TODO use own ID system??
					buttons: buttons
					x: evt.motion.x
					y: evt.motion.y
					rel_x: evt.motion.xrel
					rel_y: evt.motion.yrel
				}
			}
			.mousebuttonup, .mousebuttondown {
				mut state := ButtonState.down
				state = if evt.button.state == u8(sdl.pressed) { .down } else { .up }
				button := map_sdl_button_to_shy_mouse_button(evt.button.button)
				win := s.active_window()
				return MouseButtonEvent{
					timestamp: s.ticks()
					window_id: win.id // TODO
					which: evt.button.which // TODO use own ID system??
					button: button
					state: state
					clicks: evt.button.clicks
					x: evt.button.x
					y: evt.button.y
				}
			}
			.mousewheel {
				mut dir := MouseWheelDirection.normal
				dir = if evt.wheel.direction == u32(sdl.MouseWheelDirection.normal) {
					.normal
				} else {
					.flipped
				}
				win := s.active_window()
				return MouseWheelEvent{
					timestamp: s.ticks()
					window_id: win.id // TODO
					which: evt.wheel.which // TODO use own ID system??
					x: evt.wheel.x
					y: evt.wheel.y
					direction: dir
				}
			}
			else {
				return UnkownEvent{
					timestamp: s.ticks()
				}
			}
		}

		/*
		$if debug {
			t := evt.@type
			match t {
				.mousemotion {
					s.log.gln(.event | .flood, 'passing $t')
				}
				.keyup, .keydown {
					shy_key_code := sdl.KeyCode(evt.key.keysym.sym)
					s.log.gln(.event | .input, 'passing $t ($shy_key_code)')
				}
				else {
					s.log.pln(.event, 'passing $t')
				}
			}
		}*/

		return none // Event(evt)
	}
	return none
}

fn map_sdl_to_shy_keycode(kc sdl.Keycode) KeyCode {
	return match sdl.KeyCode(int(kc)) {
		.unknown { .unknown }
		.@return { .@return }
		.escape { .escape }
		.backspace { .backspace }
		.tab { .tab } // '\t'
		.space { .space } // ' '
		.exclaim { .exclaim } // '!'
		.quotedbl { .quotedbl } // '"'
		.hash { .hash } // '#'
		.percent { .percent } // '%'
		.dollar { .dollar } // '$'
		.ampersand { .ampersand } // '&'
		.quote { .quote } // '\''
		.leftparen { .leftparen } // '('
		.rightparen { .rightparen } // ')'
		.asterisk { .asterisk } // '*'
		.plus { .plus } // '+'
		.comma { .comma } // ','
		.minus { .minus } // '-'
		.period { .period } // '.'
		.slash { .slash } // '/'
		._0 { ._0 } // '0'
		._1 { ._1 } // '1'
		._2 { ._2 } // '2'
		._3 { ._3 } // '3'
		._4 { ._4 } // '4'
		._5 { ._5 } // '5'
		._6 { ._6 } // '6'
		._7 { ._7 } // '7'
		._8 { ._8 } // '8'
		._9 { ._9 } // '9'
		.colon { .colon } // ':'
		.semicolon { .semicolon } // ';'
		.less { .less } // '<'
		.equals { .equals } // '='
		.greater { .greater } // '>'
		.question { .question } // '?'
		.at { .at } // '@'
		.leftbracket { .leftbracket } // '['
		.backslash { .backslash } // '\\'
		.rightbracket { .rightbracket } // ']'
		.caret { .caret } // '^'
		.underscore { .underscore } // '_'
		.backquote { .backquote } // '`'
		.a { .a } // 'a'
		.b { .b } // 'b'
		.c { .c } // 'c'
		.d { .d } // 'd'
		.e { .e } // 'e'
		.f { .f } // 'f'
		.g { .g } // 'g'
		.h { .h } // 'h'
		.i { .i } // 'i'
		.j { .j } // 'j'
		.k { .k } // 'k'
		.l { .l } // 'l'
		.m { .m } // 'm'
		.n { .n } // 'n'
		.o { .o } // 'o'
		.p { .p } // 'p'
		.q { .q } // 'q'
		.r { .r } // 'r'
		.s { .s } // 's'
		.t { .t } // 't'
		.u { .u } // 'u'
		.v { .v } // 'v'
		.w { .w } // 'w'
		.x { .x } // 'x'
		.y { .y } // 'y'
		.z { .z } // 'z'
		//
		.capslock { .capslock }
		//
		.f1 { .f1 }
		.f2 { .f2 }
		.f3 { .f3 }
		.f4 { .f4 }
		.f5 { .f5 }
		.f6 { .f6 }
		.f7 { .f7 }
		.f8 { .f8 }
		.f9 { .f9 }
		.f10 { .f10 }
		.f11 { .f11 }
		.f12 { .f12 }
		//
		.printscreen { .printscreen }
		.scrolllock { .scrolllock }
		.pause { .pause }
		.insert { .insert }
		.home { .home }
		.pageup { .pageup }
		.delete { .delete } // '\177'
		.end { .end }
		.pagedown { .pagedown }
		.right { .right }
		.left { .left }
		.down { .down }
		.up { .up }
		//
		.numlockclear { .numlockclear }
		.divide { .divide }
		.kp_multiply { .kp_multiply }
		.kp_minus { .kp_minus }
		.kp_plus { .kp_plus }
		.kp_enter { .kp_enter }
		.kp_1 { .kp_1 }
		.kp_2 { .kp_2 }
		.kp_3 { .kp_3 }
		.kp_4 { .kp_4 }
		.kp_5 { .kp_5 }
		.kp_6 { .kp_6 }
		.kp_7 { .kp_7 }
		.kp_8 { .kp_8 }
		.kp_9 { .kp_9 }
		.kp_0 { .kp_0 }
		.kp_period { .kp_period }
		//
		.application { .application }
		.power { .power }
		.kp_equals { .kp_equals }
		.f13 { .f13 }
		.f14 { .f14 }
		.f15 { .f15 }
		.f16 { .f16 }
		.f17 { .f17 }
		.f18 { .f18 }
		.f19 { .f19 }
		.f20 { .f20 }
		.f21 { .f21 }
		.f22 { .f22 }
		.f23 { .f23 }
		.f24 { .f24 }
		.execute { .execute }
		.help { .help }
		.menu { .menu }
		.@select { .@select }
		.stop { .stop }
		.again { .again }
		.undo { .undo }
		.cut { .cut }
		.copy { .copy }
		.paste { .paste }
		.find { .find }
		.mute { .mute }
		.volumeup { .volumeup }
		.volumedown { .volumedown }
		.kp_comma { .kp_comma }
		.equalsas400 { .equalsas400 }
		//
		.alterase { .alterase }
		.sysreq { .sysreq }
		.cancel { .cancel }
		.clear { .clear }
		.prior { .prior }
		.return2 { .return2 }
		.separator { .separator }
		.out { .out }
		.oper { .oper }
		.clearagain { .clearagain }
		.crsel { .crsel }
		.exsel { .exsel }
		//
		.kp_00 { .kp_00 }
		.kp_000 { .kp_000 }
		.thousandsseparator { .thousandsseparator }
		.decimalseparator { .decimalseparator }
		.currencyunit { .currencyunit }
		.currencysubunit { .currencysubunit }
		.kp_leftparen { .kp_leftparen }
		.kp_rightparen { .kp_rightparen }
		.kp_leftbrace { .kp_leftbrace }
		.kp_rightbrace { .kp_rightbrace }
		.kp_tab { .kp_tab }
		.kp_backspace { .kp_backspace }
		.kp_a { .kp_a }
		.kp_b { .kp_b }
		.kp_c { .kp_c }
		.kp_d { .kp_d }
		.kp_e { .kp_e }
		.kp_f { .kp_f }
		.kp_xor { .kp_xor }
		.kp_power { .kp_power }
		.kp_percent { .kp_percent }
		.kp_less { .kp_less }
		.kp_greater { .kp_greater }
		.kp_ampersand { .kp_ampersand }
		.kp_dblampersand { .kp_dblampersand }
		.kp_verticalbar { .kp_verticalbar }
		.kp_dblverticalbar { .kp_dblverticalbar }
		.kp_colon { .kp_colon }
		.kp_hash { .kp_hash }
		.kp_space { .kp_space }
		.kp_at { .kp_at }
		.kp_exclam { .kp_exclam }
		.kp_memstore { .kp_memstore }
		.kp_memrecall { .kp_memrecall }
		.kp_memclear { .kp_memclear }
		.kp_memadd { .kp_memadd }
		.kp_memsubtract { .kp_memsubtract }
		.kp_memmultiply { .kp_memmultiply }
		.kp_memdivide { .kp_memdivide }
		.kp_plusminus { .kp_plusminus }
		.kp_clear { .kp_clear }
		.kp_clearentry { .kp_clearentry }
		.kp_binary { .kp_binary }
		.kp_octal { .kp_octal }
		.kp_decimal { .kp_decimal }
		.kp_hexadecimal { .kp_hexadecimal }
		.lctrl { .lctrl }
		.lshift { .lshift }
		.lalt { .lalt }
		.lgui { .lgui }
		.rctrl { .rctrl }
		.rshift { .rshift }
		.ralt { .ralt }
		.rgui { .rgui }
		//
		.mode { .mode }
		//
		.audionext { .audionext }
		.audioprev { .audioprev }
		.audiostop { .audiostop }
		.audioplay { .audioplay }
		.audiomute { .audiomute }
		.mediaselect { .mediaselect }
		.www { .www }
		.mail { .mail }
		.calculator { .calculator }
		.computer { .computer }
		.ac_search { .ac_search }
		.ac_home { .ac_home }
		.ac_back { .ac_back }
		.ac_forward { .ac_forward }
		.ac_stop { .ac_stop }
		.ac_refresh { .ac_refresh }
		.ac_bookmarks { .ac_bookmarks }
		//
		.brightnessdown { .brightnessdown }
		.brightnessup { .brightnessup }
		.displayswitch { .displayswitch }
		.kbdillumtoggle { .kbdillumtoggle }
		.kbdillumdown { .kbdillumdown }
		.kbdillumup { .kbdillumup }
		.eject { .eject }
		.sleep { .sleep }
		.app1 { .app1 }
		.app2 { .app2 }
		.audiorewind { .audiorewind }
		.audiofastforward { .audiofastforward }
	}
}

fn map_sdl_button_mask_to_shy_mouse_buttons(mask u32) MouseButtons {
	mut buttons := MouseButtons{}

	if mask & u32(sdl.button(sdl.button_left)) == sdl.button_lmask {
		buttons.set(.left)
	}
	if mask & u32(sdl.button(sdl.button_middle)) == sdl.button_mmask {
		buttons.set(.middle)
	}
	if mask & u32(sdl.button(sdl.button_right)) == sdl.button_rmask {
		buttons.set(.right)
	}
	if mask & u32(sdl.button(sdl.button_x1)) == sdl.button_x1mask {
		buttons.set(.x1)
	}
	if mask & u32(sdl.button(sdl.button_x2)) == sdl.button_x2mask {
		buttons.set(.x2)
	}
	return buttons
}

fn map_sdl_button_to_shy_mouse_button(sdl_button byte) MouseButton {
	mut button := MouseButton{}

	if sdl_button == sdl.button_left {
		button = .left
	}
	if sdl_button == sdl.button_middle {
		button = .middle
	}
	if sdl_button == sdl.button_right {
		button = .right
	}
	if sdl_button == sdl.button_x1 {
		button = .x1
	}
	if sdl_button == sdl.button_x2 {
		button = .x2
	}
	return button
}