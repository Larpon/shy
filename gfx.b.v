// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import sokol.gfx

pub struct GFX {
mut:
	solid &Solid
	// sokol
	pass_action gfx.PassAction
}

pub fn (mut g GFX) init() ! {
	s := g.solid
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	mut gfx_desc := gfx.Desc{
		shader_pool_size: 4 * 512 // default 32, NOTE this number affects the prealloc_contexts in font_system.b.v...
		context_pool_size: 4 * 512 // default 4, NOTE this number affects the prealloc_contexts in font_system.b.v...
		pipeline_pool_size: 4 * 1024 // default 64, NOTE this number affects the prealloc_contexts in font_system.b.v...
	}
	gfx_desc.context.sample_count = s.config.render.msaa
	gfx.setup(&gfx_desc)
	assert gfx.is_valid() == true

	// Create a black color as a default pass (default window background color)
	color := s.config.window.color.as_f32()
	pass_action := gfx.create_clear_pass(color.r, color.g, color.b, color.a)
	g.pass_action = pass_action
}

pub fn (mut g GFX) shutdown() ! {
	gfx.shutdown()
}

pub fn (g GFX) commit() {
	gfx.end_pass()
	gfx.commit()
}

pub fn (mut g GFX) clear_screen() {
	s := g.solid
	mut win := s.wm.active_window()
	// TODO multi window support
	w, h := win.drawable_size()
	gfx.begin_default_pass(&g.pass_action, w, h)
}

pub fn (g GFX) swap() {
	g.commit()
	mut win := g.solid.wm.active_window()
	win.swap()
}