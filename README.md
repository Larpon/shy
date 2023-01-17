<img src="shy.svg" width="128"/>

# Shy

An intuitive, opinionated and solid foundation for game development and
creative coding written in V.

The `shy` project works both as a V module and a standalone CLI tool.

# Targets

Please note that export and developing/building/running from some
of these platforms are still work-in-progress, but we aim to support
a wide range of targets like the following:

Windows, macOS, Linux, Raspberry PI, Android, Web (WASM/emscripten) and likely more.

# Highlights

* Get your creative ideas quickly up and running.
* Rich examples directory.
* Live coding and runtime experimenting via V's `-live` flag.
* Neat animation and timer system - built right in.
* Easy timers with `shy.once(...)` or `shy.every(...)` (supports closures!).
* 2D shape drawing with several levels, layers of control and performance.
* 2D shape collision detection.
* 3D capable (via `sokol_gfx.h`)
* Multiple render modes (immediate, UI, step).
* Fairly sub-system agnostic. Bring your own ECS, physics engine etc.
* [WIP] Assets system for easy loading (and freeing) of all kinds of assets: binary blobs, images,
music, sounds etc.
* [WIP] Export to different platforms via the `shy export` command.
* [WIP] Intuitive Qt/Widgets/QML (scene graph) inspired `ui` module supporting *custom* UI items.
* [WIP] ... much more :)

# Install

## Dependencies

`shy`'s default backend, currently, depend on `sdl` and `vab` official V modules.

The `sdl` dependency will likely be moved to be part of another backend or opt-in
once `shy` matures - but for now you'll need SDL2 at build and runtime.

`vab` is only used by `shy`'s export functionality and *does not* require
you to have Java nor Android SDK/NDK installed.
If you do not intend to export to the Android platform the aforementioned
dependencies are thus only needed at *runtime* for `vab`, but the module code
still needs to be present when using the `shy` CLI tool.

```bash
v install sdl
v install vab
```

## Unix (Linux, macOS)
```bash
git clone git@github.com:Larpon/shy.git ~/.vmodules/shy
v ~/.vmodules/shy # Build the `shy` CLI tool
```

## Windows
```bash
git clone git@github.com:Larpon/shy.git %USERPROFILE%/.vmodules/shy
v %USERPROFILE%\.vmodules\shy # Build the `shy` CLI tool
```

## Symlink (optional)
You can symlink `shy` to your `$PATH` so it works as a global shell command.

```bash
sudo ln -s ~/.vmodules/shy/shy /usr/local/bin/shy
```

## Shell tab completion (optional)
You can install tab completions for your shell by [following the instructions
here](https://github.com/Larpon/shy/blob/fb26741/cmd/complete.v#L11-L38).
