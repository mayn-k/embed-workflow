# embed-workflow

One-command embedded project launcher + tmux/nvim integration.
Type `embed new blink nucleo-l476rg` — land in a fully wired dev environment.

## What's in the box

```
embed-workflow/
├── bin/
│   └── embed                      ← the CLI (new / open / list / flash)
├── boards/
│   └── nucleo-l476rg.conf         ← board manifest (add more here)
├── templates/
│   ├── bare-metal/                ← pure-register template + minimal regs header
│   └── freertos/                  ← + FreeRTOS V11.1.0 kernel (pinned)
├── tmux/
│   ├── embed-session.sh           ← builds session layout on launch
│   └── embed.tmux.conf            ← popup bindings (sourced from ~/.tmux.conf)
├── nvim/
│   └── embed.lua                  ← :Build :Flash :Debug :Monitor commands
├── install.sh                     ← wires everything up
└── README.md
```

## Install

```sh
# Put this repo somewhere (e.g. ~/work/embedded_systems/embed-workflow)
cd ~/work/embedded_systems/embed-workflow
./install.sh
```

The installer symlinks `embed` into `~/.local/bin`, appends a `source-file` line
to `~/.tmux.conf`, symlinks `embed.lua` into `~/.config/nvim/lua/`, and checks
for required tools.

Then add one line to your `init.lua`:

```lua
require("embed").setup()
```

## Usage

```sh
embed list boards
embed new blink nucleo-l476rg                  # bare-metal (default)
embed new rtos-demo nucleo-l476rg --os=freertos
embed open blink                               # reopen an existing project
embed list projects
```

Each `embed new` creates a project under `~/work/embedded_systems/projects/<name>/`
with working Makefile, linker script, startup code, blinky source, README, and
a `.embed/` directory holding the board manifest + helper scripts.

A tmux session named after the project spawns with:

- **editor** window — nvim
- **debug** window — OpenOCD (top) + GDB (bottom), pre-typed

Popups from any window (prefix = `C-s`):

- `prefix + g` — shell
- `prefix + t` — tio serial monitor (uses the project's board manifest)
- `prefix + B` — build
- `prefix + F` — flash
- `prefix + E` — erase (confirms first)
- `prefix + S` — fuzzy-pick an embed project to switch to

## Assignment mode

```sh
embed new lab3-stm32 stm32f411e-disco --assignment --course="ECEN 5613"
```

Creates `src/ inc/ drivers/ startup/ linker/` and four files that contain only
a comment header (file, project, board, author, course, date, honor pledge):
`Makefile`, `linker/linker.ld`, `startup/startup.s`, `src/main.c`. No code.

The popups and nvim commands still work because they call `make <target>`.
Give your Makefile these targets: `all`, `flash`, `erase`, `openocd`, `debug`,
`clean`. Until `openocd`/`debug` exist, the debug window has raw `openocd` and
`gdb` commands pre-typed. `<leader>mc` runs `bear -- make -B` directly, so
clangd works with any Makefile.

Boards marked `TEMPLATES="assignment"` in their conf (e.g. the F411E-Discovery)
refuse the full template, since the bundled register header is STM32L4-only.

## Adding a new board

Drop a new `.conf` file in `boards/`. Example minimum:

```sh
BOARD_ID="bluepill"
BOARD_NAME="STM32F103 Blue Pill"
MCU="STM32F103C8"
CPU="cortex-m3"
FPU="none"
FLOAT_ABI="soft"
FLASH_ORIGIN="0x08000000"
FLASH_SIZE="64K"
RAM_ORIGIN="0x20000000"
RAM_SIZE="20K"
TOOLCHAIN_PREFIX="arm-none-eabi-"
OPENOCD_CFG="board/st_nucleo_f103rb.cfg"
OPENOCD_CHIP_FAMILY="stm32f1x"
SERIAL_PORT="/dev/ttyUSB0"
SERIAL_BAUD="115200"
USER_LED_PORT="C"
USER_LED_PIN="13"
```

That's it. `embed new myproj bluepill` will work immediately.

> Note: the bundled `inc/stm32l476_regs.h` is L4-specific. For other MCUs either
> extend that file, write a new one for the MCU, or drop in the CMSIS device
> header from ST. Update the bare-metal template's `inc/` accordingly.

## Tool dependencies

Required: `tmux`, `nvim`, `arm-none-eabi-gcc`, `arm-none-eabi-gdb` (or `gdb-multiarch`), `openocd`, `tio`, `git`.
Optional: `bear` (for `compile_commands.json`), `fzf` (nicer project picker), `stlink-tools` (alternative flasher + udev rules).

The installer checks for all of these and tells you what's missing.
