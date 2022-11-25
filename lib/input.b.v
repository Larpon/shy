// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import sdl
// import manymouse as mm

// TODO move
pub struct Gamepad {
	ShyStruct
	id int
mut:
	name      string
	handle    &sdl.GameController
	is_haptic bool
}

pub fn (mut gp Gamepad) init() ! {
	gp.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	s := gp.shy
	// Open the device
	haptic := sdl.haptic_open_from_joystick(sdl.game_controller_get_joystick(gp.handle))
	if haptic == sdl.null {
		// error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gdebug('${@STRUCT}.${@FN}', 'controller ${gp.id} (${gp.name}) does not seem to have haptic features')
	} else {
		// See if it can do sine waves
		if (sdl.haptic_query(haptic) & u32(sdl.haptic_sine)) == 0 {
			s.log.gdebug('${@STRUCT}.${@FN}', 'controller ${gp.id} (${gp.name}) does not seem to support haptic SINE effects')
		} else {
			gp.is_haptic = true
			/*
			// Create the effect
			mut effect := sdl.HapticEffect{}
			unsafe {
				vmemset( &effect, 0, int(sizeof(effect)) ) // 0 is safe default
			}

			effect.@type = u16(sdl.haptic_sine)
			effect.periodic.direction.@type = u8(sdl.haptic_polar) // Polar coordinates
			effect.periodic.direction.dir[0] = 18000 // Force comes from south
			effect.periodic.period = 1000 // 1000 ms
			effect.periodic.magnitude = 20000 // 20000/32767 strength
			effect.periodic.length = 5000 // 5 seconds long
			effect.periodic.attack_length = 1000 // Takes 1 second to get max strength
			effect.periodic.fade_length = 1000 // Takes 1 second to fade away

			// Upload the effect
			effect_id := sdl.haptic_new_effect( haptic, &effect )

			// Test the effect
			sdl.haptic_run_effect( haptic, effect_id, 1 )
			sdl.delay( 5000) // Wait for the effect to finish

			// We destroy the effect, although closing the device also does this
			sdl.haptic_destroy_effect( haptic, effect_id )
			*/
		}
	}
	// Close the device
	sdl.haptic_close(haptic)
}

// scan scans for new input devices.
pub fn (mut ip Input) scan() ! {
	// TODO
}

// init initializes input systems (keyboard, mouse etc.)
pub fn (mut ip Input) init() ! {
	ip.shy.assert_api_init()
	ip.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	s := ip.shy

	// mut mice_support := s.config.input.mice
	// if mice_support {
	// 	available_mice := mm.reinit()
	// 	s.log.gdebug('${@STRUCT}.${@FN}', 'enabling support for multiple mice. $available_mice is currently available')
	// 	if available_mice < 0 {
	// 		mm.quit()
	// 		s.log.gerror('${@STRUCT}.${@FN}', 'error initializing ManyMouse. Falling back to unified mouse input')
	// 	} else {
	// 		driver_name := unsafe { cstring_to_vstring(mm.driver_name()) }
	// 		s.log.gdebug('${@STRUCT}.${@FN}', 'ManyMouse driver: $driver_name')

	// 		if available_mice == 0 {
	// 			mm.quit()
	// 			s.log.gerror('${@STRUCT}.${@FN}', 'no mice detected.')
	// 		} else {
	// 			// TODO expose ManyMouse max (default is 256)!
	// 			for i := u8(0); i < available_mice; i++ {
	// 				device_name := unsafe { cstring_to_vstring(mm.device_name(i)) }
	// 				s.log.gdebug('${@STRUCT}.${@FN}', 'ManyMouse device $i / $device_name')
	// 				mut mouse := &Mouse{
	// 					shy: s
	// 					id: i
	// 				}
	// 				mouse.init()!
	// 				ip.mice[i] = mouse // TODO NOTE see process_events also
	// 			}
	// 		}
	// 	}
	// } else {
	mut mouse := &Mouse{
		shy: s
		id: default_mouse_id
	}
	mouse.init()!
	ip.mice[default_mouse_id] = mouse // TODO NOTE see process_events also
	// }

	// NOTE multiple keyboards is apparently a near impossible thing??
	// It's problems rooted deep in the underlying OS layers and device driver levels:
	// https://discourse.libsdl.org/t/sdl-x-org-and-multiple-mice/12298/15
	mut keyboard := &Keyboard{
		shy: s
	}
	keyboard.init()!
	ip.keyboards[0] = keyboard // TODO NOTE see process_events also

	ip.init_input()!
}

pub fn (mut ip Input) shutdown() ! {
	ip.shy.assert_api_shutdown()
	ip.shy.log.gdebug('${@STRUCT}.${@FN}', '')
}

fn (mut ip Input) init_input() ! {
	mut s := ip.shy
	// Check for joysticks/game controllers
	if sdl.num_joysticks() < 1 {
		s.log.gdebug('${@STRUCT}.${@FN}', 'no joysticks or game controllers connected')
	} else {
		// Load joystick(s) / controller(s)
		for i in 0 .. 5 {
			/*
			controller = sdl.joystick_open(i)
			if isnil(game_controller) {
				error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				println('Warning: Unable to open controller $i SDL Error: $error_msg' )
				continue
			}*/
			if sdl.is_game_controller(i) {
				controller := sdl.game_controller_open(i)
				if controller == sdl.null {
					error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
					s.log.gerror('${@STRUCT}.${@FN}', 'unable to open controller ${i}:\n${error_msg}')
					continue
				}
				controller_name := unsafe { cstring_to_vstring(sdl.game_controller_name_for_index(i)) }
				s.log.gdebug('${@STRUCT}.${@FN}', 'detected controller ${i} as "${controller_name}"')

				mut pad := &Gamepad{
					id: i
					shy: s
					name: controller_name
					handle: controller
				}
				pad.init()!
				ip.pads << pad
				// s.api.controllers[i] = controller
			} else {
				// sdl.joystick_close(i)
				// eprintln('Warning: Not adding controller $i - not a game controller' )
				continue
			}
		}
	}
}

fn (mut ip Input) poll_event() ?Event {
	s := ip.shy
	// TODO set mouse positions in each mouse in input.mice
	// is_multi_mice := s.api.input.mice.len > 1
	mut shy_event := Event(UnkownEvent{
		timestamp: s.ticks()
	})

	evt := sdl.Event{}
	if 0 < sdl.poll_event(&evt) {
		match evt.@type {
			.windowevent {
				// if sdl.WindowEventID(int(evt.window.event)) == .focus_lost {
				//	s.shutdown = true
				//}
				wevid := unsafe { sdl.WindowEventID(int(evt.window.event)) }
				win := s.active_window()
				if wevid == .resized {
					shy_event = WindowEvent{
						timestamp: s.ticks()
						kind: .resized
						window: win // TODO multi-window support
					}
				}
			}
			.quit {
				shy_event = QuitEvent{
					timestamp: s.ticks()
				}
			}
			.keyup {
				shy_key_code := map_sdl_to_shy_keycode(evt.key.keysym.sym)
				shy_event = KeyEvent{
					timestamp: s.ticks()
					state: .up
					key_code: shy_key_code
				}
			}
			.keydown {
				shy_key_code := map_sdl_to_shy_keycode(evt.key.keysym.sym)
				shy_event = KeyEvent{
					timestamp: s.ticks()
					state: .down
					key_code: unsafe { KeyCode(int(shy_key_code)) }
				}
			}
			.mousemotion {
				// if !is_multi_mice {
				buttons := map_sdl_button_mask_to_shy_mouse_buttons(evt.motion.state)
				win := s.active_window()

				which := default_mouse_id
				// mut mouse := s.api.input.mouse(which) or { panic(err) }
				// mouse.x = evt.motion.x
				// mouse.y = evt.motion.y
				// mouse.set_button_state(event.button, event.state)

				shy_event = MouseMotionEvent{
					timestamp: s.ticks()
					window_id: win.id // TODO multi-window support
					which: which // evt.motion.which // TODO use own ID system??
					buttons: buttons
					x: evt.motion.x
					y: evt.motion.y
					rel_x: evt.motion.xrel
					rel_y: evt.motion.yrel
				}
				// }
			}
			.mousebuttonup, .mousebuttondown {
				// if !is_multi_mice {
				mut state := ButtonState.down
				state = if evt.button.state == u8(sdl.pressed) { .down } else { .up }
				button := map_sdl_button_to_shy_mouse_button(evt.button.button)
				win := s.active_window()
				shy_event = MouseButtonEvent{
					timestamp: s.ticks()
					window_id: win.id // TODO
					which: default_mouse_id // evt.button.which // TODO use own ID system??
					button: button
					state: state
					clicks: evt.button.clicks
					x: evt.button.x
					y: evt.button.y
				}
				// }
			}
			.mousewheel {
				// if !is_multi_mice {
				mut dir := MouseWheelDirection.normal
				dir = if evt.wheel.direction == u32(sdl.MouseWheelDirection.normal) {
					.normal
				} else {
					.flipped
				}
				win := s.active_window()
				shy_event = MouseWheelEvent{
					timestamp: s.ticks()
					window_id: win.id // TODO
					which: default_mouse_id // evt.wheel.which // TODO use own ID system??
					x: evt.wheel.x
					y: evt.wheel.y
					direction: dir
				}
				// }
			}
			else {
				shy_event = UnkownEvent{
					timestamp: s.ticks()
				}
			}
		}
	}

	// Important
	if shy_event is UnkownEvent {
		return none
	}

	match shy_event {
		MouseMotionEvent {
			event := shy_event as MouseMotionEvent
			m_id := u8(event.which) // TODO see input handling
			if mut mouse := s.api.input.mouse(m_id) {
				mouse.x = event.x
				mouse.y = event.y
			}
		}
		MouseButtonEvent {
			event := shy_event as MouseButtonEvent
			m_id := u8(event.which) // TODO see input handling
			if mut mouse := s.api.input.mouse(m_id) {
				mouse.set_button_state(event.button, event.state)
			}
		}
		KeyEvent {
			event := shy_event as KeyEvent
			k_id := u8(event.which) // TODO see input handling
			if mut kb := s.api.input.keyboard(k_id) {
				kb.set_key_state(event.key_code, event.state)
			}
		}
		else {}
	}

	// TODO find out what coordinate positions that ManyMouse actually uses?
	/*
	if is_multi_mice {
		mut event := mm.Event{}
		if mm.poll_event(&event) > 0 {
			// xy := if event.item == 0 { 'x' } else { 'y' }
			match event.@type {
				.relmotion {
					// println('Mouse #$event.device relative motion $xy $event.value')
					which := u8(event.device)
					mut mouse := s.api.input.mouse(which) or { panic(err) }
					match event.item {
						0 {
							mouse.x += event.value
						}
						1 {
							mouse.y += event.value
						}
						else{}
					}
					win := s.active_window()
					return MouseMotionEvent{
						timestamp: s.ticks()
						window_id: win.id // TODO multi-window support
						which: which
						// buttons: buttons
						x: mouse.x
						y: mouse.y
						rel_x: if event.item == 0 {event.value } else {0}
						rel_y: if event.item != 0 {event.value } else {0}
					}
				}
				.absmotion {
					// println('Mouse #$event.device absolute motion $xy $event.value')
					win := s.active_window()
					which := u8(event.device)

					val := f32(event.value - event.minval)
					max_val := f32(event.maxval - event.minval)
					mut mouse := s.api.input.mouse(which) or { panic(err) }
					match event.item {
						0 {
							mouse.x = int(val / max_val) //event.value
						}
						1 {
							mouse.y = int(val / max_val) //event.value
						}
						else{}
					}
					return MouseMotionEvent{
						timestamp: s.ticks()
						window_id: win.id // TODO multi-window support
						which: which // evt.motion.which // TODO use own ID system??
						// buttons: buttons
						x: mouse.x //if event.item == 0 {event.value } else {0}
						y: mouse.y //if event.item != 0 {event.value } else {0}

						//rel_x: evt.motion.xrel
						//rel_y: evt.motion.yrel
					}
				}
				.button {
					// direction := if event.value == 0 { 'up' } else { 'down' }
					//println('Mouse #$event.device button $event.item $direction')
					mut state := ButtonState.down
					state = if event.value == 0 { .up } else { .down }
					//button := map_sdl_button_to_shy_mouse_button(evt.button.button)
					win := s.active_window()
					return MouseButtonEvent{
						timestamp: s.ticks()
						window_id: win.id // TODO
						which: u16(event.device) // evt.button.which // TODO use own ID system??
						// button: button
						state: state
						//clicks: evt.button.clicks
						//x: evt.button.x
						//y: evt.button.y
					}
				}
				.scroll {
					wheel := if event.item == 0 { 'vertical' } else { 'horizontal' }
					mut direction := if event.value < 0 { 'down' } else { 'up' }
					if event.item != 0 {
						direction = if event.value < 0 { 'right' } else { 'left' }
					}
					return UnkownEvent{
						timestamp: s.ticks()
					}
					// println('Mouse #$event.device wheel $wheel $direction')
				}
				.disconnect {
					// println('Mouse #$event.device disconnected')
					return UnkownEvent{
						timestamp: s.ticks()
					}
				}
				else {
					// println('Mouse #$event.device unhandled event type $event.value')
					return UnkownEvent{
						timestamp: s.ticks()
					}
				}
			}
		}
	}
	*/
	return shy_event
	// return none
}

fn map_sdl_to_shy_keycode(kc sdl.Keycode) KeyCode {
	return match unsafe { sdl.KeyCode(int(kc)) } {
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
		// .audiofastforward { .audiofastforward }
		// TODO Done this way to be able to compile for newer SDL versions
		// that adds to this enum, V will complain it's not exhaustive
		else { .audiofastforward }
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
