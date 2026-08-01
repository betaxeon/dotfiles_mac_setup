local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

local function file_exists(path)
  local f = io.open(path, "r")
  if f ~= nil then
    io.close(f)
    return true
  end
  return false
end

config.color_scheme = "rose-pine-moon"
config.max_fps = 120

config.font = wezterm.font("Hack Nerd Font")

config.window_frame = {
  font = wezterm.font_with_fallback({
    "Menlo",
    "Monaco",
  }),
}

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

config.inactive_pane_hsb = {
  saturation = 0.0,
  brightness = 0.5,
}

-- Since tmux manages windows/panes, hide WezTerm's tab bar.
config.enable_tab_bar = false

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.7
  config.window_frame.font_size = 10.0
end

if is_macos then
  config.window_background_opacity = 0.8
  config.macos_window_background_blur = 50
  config.font_size = 15.0
  config.window_frame.font_size = 13.0

  -- Auto-start or attach to tmux session named "main"
  if file_exists("/opt/homebrew/bin/tmux") then
    config.default_prog = {
      "/opt/homebrew/bin/tmux",
      "new-session",
      "-A",
      "-s",
      "main",
    }
  elseif file_exists("/usr/local/bin/tmux") then
    config.default_prog = {
      "/usr/local/bin/tmux",
      "new-session",
      "-A",
      "-s",
      "main",
    }
  else
    -- Fallback if tmux is found via PATH
    config.default_prog = {
      "tmux",
      "new-session",
      "-A",
      "-s",
      "main",
    }
  end
end

config.keys = {
  -- Cmd+Enter: fullscreen
  {
    key = "Enter",
    mods = "CMD",
    action = act.ToggleFullScreen,
  },

  -- Cmd+T: new tmux window, like a new tab
  {
    key = "t",
    mods = "CMD",
    action = act.SendString("\x02c"),
  },

  -- Cmd+D: split tmux pane left/right
  {
    key = "d",
    mods = "CMD",
    action = act.SendString("\x02%"),
  },

  -- Cmd+Shift+D: split tmux pane top/bottom
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = act.SendString('\x02"'),
  },

  -- Cmd+W: close the current tmux pane.
  -- If this is the last pane in the tmux window, tmux closes the window too.
  {
    key = "w",
    mods = "CMD",
    action = act.SendString("\x02x"),
  },

  -- Cmd+K: clear visible shell screen + tmux scrollback history
  {
    key = "k",
    mods = "CMD",
    action = act.Multiple({
      act.SendString("\x0c"),
      act.SendString("\x02:clear-history\r"),
    }),
  },

  -- Cmd+1..9: switch tmux windows
  {
    key = "1",
    mods = "CMD",
    action = act.SendString("\x021"),
  },
  {
    key = "2",
    mods = "CMD",
    action = act.SendString("\x022"),
  },
  {
    key = "3",
    mods = "CMD",
    action = act.SendString("\x023"),
  },
  {
    key = "4",
    mods = "CMD",
    action = act.SendString("\x024"),
  },
  {
    key = "5",
    mods = "CMD",
    action = act.SendString("\x025"),
  },
  {
    key = "6",
    mods = "CMD",
    action = act.SendString("\x026"),
  },
  {
    key = "7",
    mods = "CMD",
    action = act.SendString("\x027"),
  },
  {
    key = "8",
    mods = "CMD",
    action = act.SendString("\x028"),
  },
  {
    key = "9",
    mods = "CMD",
    action = act.SendString("\x029"),
  },

  -- Cmd+Shift+[ / Cmd+Shift+]: previous / next tmux window.
  -- Depending on keyboard event normalization, WezTerm may report these as
  -- either shifted brackets or shifted characters, so bind both forms.
  {
    key = "[",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02p"),
  },
  {
    key = "{",
    mods = "CMD",
    action = act.SendString("\x02p"),
  },
  {
    key = "{",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02p"),
  },
  {
    key = "]",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02n"),
  },
  {
    key = "}",
    mods = "CMD",
    action = act.SendString("\x02n"),
  },
  {
    key = "}",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02n"),
  },

  -- Cmd+[ / Cmd+]: previous / next tmux pane
  {
    key = "[",
    mods = "CMD",
    action = act.SendString("\x02;"),
  },
  {
    key = "]",
    mods = "CMD",
    action = act.SendString("\x02o"),
  },

  -- Cmd+Z: zoom/unzoom current tmux pane
  {
    key = "z",
    mods = "CMD",
    action = act.SendString("\x02z"),
  },

  -- Cmd+L: list tmux windows
  {
    key = "l",
    mods = "CMD",
    action = act.SendString("\x02w"),
  },

  -- Cmd+Shift+S: list tmux sessions
  {
    key = "s",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02s"),
  },
  -- Cmd+Shift+N: create a new tmux session using a WezTerm prompt
  {
    key = "n",
    mods = "CMD|SHIFT",
    action = act.PromptInputLine({
      description = "New tmux session name:",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          -- Keep session names safe: letters, numbers, underscore, dash, dot
          local session = line:gsub("[^%w_.-]", "_")

          if session ~= "" then
            window:perform_action(
              act.SendString("tmux new-session -d -s " .. session .. " \\; switch-client -t " .. session .. "\r"),
              pane
            )
          end
        end
      end),
    }),
  },
  -- Cmd+Shift+Q: detach from tmux.
  -- Because tmux is the main WezTerm process, this may close the WezTerm window.
  {
    key = "q",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02d"),
  },

  -- Cmd+Shift+Arrow: move between tmux panes
  {
    key = "LeftArrow",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02\x1b[D"),
  },
  {
    key = "RightArrow",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02\x1b[C"),
  },
  {
    key = "UpArrow",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02\x1b[A"),
  },
  {
    key = "DownArrow",
    mods = "CMD|SHIFT",
    action = act.SendString("\x02\x1b[B"),
  },
}

return config
