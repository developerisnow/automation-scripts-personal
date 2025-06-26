# 🎯 iTerm2 + TMUX Setup Guide

## 🔧 Fix 1: Cmd+A для TMUX (не Select All)

### В iTerm2:
1. **Preferences** → **Keys** → **Key Bindings**
2. Найди "Select All" с Cmd+A
3. Удали или переназначь на Option+Cmd+A
4. Добавь новый:
   ```
   Shortcut: ⌘A
   Action: Send Hex Code
   Value: 0x01
   ```

## 📋 Fix 2: Копирование в TMUX

### Способ 1: Мышкой (рекомендую!)
```bash
# Зажми Option и выделяй мышкой
# Потом Cmd+C как обычно
```

### Способ 2: TMUX copy mode
1. `Ctrl+Space` + `[` - войти в copy mode
2. Навигация стрелками или hjkl
3. `Space` - начать выделение
4. `Enter` - скопировать
5. `Ctrl+Space` + `]` - вставить

### Способ 3: Настрой TMUX для macOS clipboard
```bash
# Добавь в ~/.tmux.conf:
set-option -g set-clipboard on
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
```

## 🎮 Рекомендуемые Hotkeys

| Действие | Комбинация | Что делает |
|----------|------------|------------|
| TMUX Prefix | `Ctrl+Space` | Активация tmux |
| Select All (если нужно) | `Option+Cmd+A` | Выделить все |
| Copy с Option | `Option+Mouse` → `Cmd+C` | Копировать из tmux |
| Paste | `Cmd+V` | Вставить |
| TMUX Copy Mode | `Ctrl+Space` + `[` | Режим копирования |

## 💡 Pro Tip: Настрой профиль для TMUX

В iTerm2 создай отдельный профиль "TMUX":
1. Profiles → New Profile → "TMUX"
2. Keys → Presets → "Natural Text Editing"
3. Terminal → "Enable mouse reporting" = OFF
4. Используй этот профиль для tmux сессий
