-- embed.lua — neovim integration for the embed workflow
--
-- Drop this file at ~/.config/nvim/lua/embed.lua (or symlink from the
-- embed-workflow repo) and add ONE line to your init.lua:
--
--     require("embed").setup()
--
-- That's it. This doesn't pull in other plugins or touch your LSP config.
-- It just adds user commands and a few keymaps that send build/flash/debug
-- commands to the right tmux panes of your embed session.

local M = {}

-- ─── Utilities ──────────────────────────────────────────────────────────────

local function has_tmux()
  return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

-- Run a shell command and return its output (trimmed)
local function sh(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then return "" end
  local out = handle:read("*a") or ""
  handle:close()
  return (out:gsub("%s+$", ""))
end

-- Find the project root by walking up looking for .embed/ or Makefile
local function project_root()
  local path = vim.fn.expand("%:p:h")
  if path == "" then path = vim.fn.getcwd() end
  -- :h marker-backed find_root-ish
  local found = vim.fs.find({ ".embed", "Makefile", ".git" }, {
    path = path,
    upward = true,
    stop = vim.env.HOME,
  })[1]
  if found then
    return vim.fs.dirname(found)
  end
  return vim.fn.getcwd()
end

local function is_embed_project(root)
  return vim.fn.isdirectory(root .. "/.embed") == 1
end

-- Send a command string to a specific tmux target (e.g., "debug.1")
-- Opens a floating popup if the target doesn't exist (for shell/serial).
local function tmux_send(target, cmd, opts)
  opts = opts or {}
  if not has_tmux() then
    vim.notify("embed: not inside tmux — falling back to :terminal", vim.log.levels.WARN)
    vim.cmd("belowright split | terminal " .. cmd)
    return
  end

  local session = sh("tmux display -p '#S'")
  local full_target = session .. ":" .. target

  -- Check if target window/pane exists
  local exists = sh(string.format(
    "tmux list-panes -t %q -F '#{pane_id}' 2>/dev/null | head -1",
    full_target
  ))

  if exists ~= "" then
    -- Clear running cmd first (send C-c), then send new command
    if opts.clear then
      vim.fn.system(string.format("tmux send-keys -t %q C-c", full_target))
      vim.loop.sleep(50)
    end
    vim.fn.system(string.format(
      "tmux send-keys -t %q %s Enter",
      full_target, vim.fn.shellescape(cmd)
    ))
    if opts.switch then
      vim.fn.system(string.format("tmux select-window -t %q", full_target))
    end
  else
    -- Target doesn't exist — open as popup
    local popup_cmd = string.format(
      "tmux display-popup -E -w 90%% -h 80%% -d %q %s",
      project_root(),
      vim.fn.shellescape(cmd .. "; echo; echo '── press Enter to close ──'; read -r")
    )
    vim.fn.system(popup_cmd)
  end
end

-- ─── Commands ───────────────────────────────────────────────────────────────

local function make_target(target, opts)
  opts = opts or {}
  local root = project_root()
  if not is_embed_project(root) and vim.fn.filereadable(root .. "/Makefile") == 0 then
    vim.notify("embed: no Makefile in " .. root, vim.log.levels.ERROR)
    return
  end
  local cmd = string.format("cd %s && make %s", vim.fn.shellescape(root), target)
  if opts.pane then
    tmux_send(opts.pane, cmd, { clear = true, switch = opts.switch })
  else
    -- Default: popup
    tmux_send("__popup__", cmd)
  end
end

function M.build()    make_target("")                end  -- default target
function M.flash()    make_target("flash")           end
function M.erase()    make_target("erase")           end
function M.reset()    make_target("reset")           end
function M.size()     make_target("size")            end
function M.clean()    make_target("clean")           end
-- Regenerate compile_commands.json for clangd. Runs bear around a full
-- rebuild directly, so it works with any Makefile (including one you wrote
-- from scratch that has no `ccdb` target).
function M.ccdb()
  local root = project_root()
  local cmd = string.format(
    "cd %s && bear --output compile_commands.json -- make -B",
    vim.fn.shellescape(root))
  tmux_send("__popup__", cmd)
end

-- Debug: OpenOCD to top pane, GDB to bottom — both in 'debug' window.
-- Assignment projects have no `openocd`/`debug` targets until you write
-- them, so there we only jump to the debug window, where the raw commands
-- are already typed (press Enter in each pane).
function M.debug()
  if not has_tmux() then
    vim.notify("embed: :Debug requires tmux", vim.log.levels.ERROR)
    return
  end
  local pconf = project_root() .. "/.embed/project.conf"
  if vim.fn.filereadable(pconf) == 1 then
    for _, line in ipairs(vim.fn.readfile(pconf)) do
      if line == 'MODE="assignment"' then
        M.debug_window()
        vim.notify("embed: press Enter in the top pane (openocd), then the bottom (gdb)")
        return
      end
    end
  end
  make_target("openocd", { pane = "debug.0" })
  vim.defer_fn(function()
    make_target("debug", { pane = "debug.1", switch = true })
  end, 1500)  -- give OpenOCD time to start listening
end

function M.monitor()
  -- Serial monitor is easiest via the tmux popup binding (prefix+t),
  -- but :Monitor pops tio directly.
  local root = project_root()
  local serial_script = root .. "/.embed/serial.sh"
  if vim.fn.executable(serial_script) == 1 then
    tmux_send("__popup__", serial_script)
  else
    make_target("monitor")
  end
end

-- Jump to tmux debug window without running anything
function M.debug_window()
  if not has_tmux() then return end
  local session = sh("tmux display -p '#S'")
  vim.fn.system(string.format("tmux select-window -t %q", session .. ":debug"))
end

-- ─── Setup ──────────────────────────────────────────────────────────────────

function M.setup(opts)
  opts = opts or {}
  local set_keymaps = opts.keymaps ~= false  -- default true

  -- User commands
  vim.api.nvim_create_user_command("Build",   M.build,        {})
  vim.api.nvim_create_user_command("Flash",   M.flash,        {})
  vim.api.nvim_create_user_command("Erase",   M.erase,        {})
  vim.api.nvim_create_user_command("Reset",   M.reset,        {})
  vim.api.nvim_create_user_command("Debug",   M.debug,        {})
  vim.api.nvim_create_user_command("DebugWin",M.debug_window, {})
  vim.api.nvim_create_user_command("Monitor", M.monitor,      {})
  vim.api.nvim_create_user_command("Size",    M.size,         {})
  vim.api.nvim_create_user_command("Ccdb",    M.ccdb,         {})
  vim.api.nvim_create_user_command("EmbedClean", M.clean,     {})

  -- Default keymaps under <leader>m ("m" for make/embedded)
  -- Override by passing `keymaps = false` to setup().
  if set_keymaps then
    local map = vim.keymap.set
    local leader = "<leader>m"
    map("n", leader .. "b", M.build,        { desc = "Embed: build"    })
    map("n", leader .. "f", M.flash,        { desc = "Embed: flash"    })
    map("n", leader .. "d", M.debug,        { desc = "Embed: debug"    })
    map("n", leader .. "w", M.debug_window, { desc = "Embed: debug win"})
    map("n", leader .. "m", M.monitor,      { desc = "Embed: monitor"  })
    map("n", leader .. "s", M.size,         { desc = "Embed: size"     })
    map("n", leader .. "c", M.ccdb,         { desc = "Embed: ccdb"     })
    map("n", leader .. "e", M.erase,        { desc = "Embed: erase"    })
    map("n", leader .. "r", M.reset,        { desc = "Embed: reset"    })
  end
end

return M
