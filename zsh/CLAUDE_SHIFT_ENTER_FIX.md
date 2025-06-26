# 🎯 iTerm2 + TMUX + Claude Code: Shift+Enter Fix

## 🔧 Метод 1: Quick Fix в TMUX

```bash
# Запусти это прямо сейчас в tmux:
tmux unbind -n S-Enter
tmux unbind S-Enter
```

## 🖥️ Метод 2: Настройка iTerm2

### 1. **Создай новый Key Mapping**
1. iTerm2 → Preferences → Keys → Key Bindings
2. Нажми `+` (добавить)
3. Настрой:
   - **Keyboard Shortcut**: `Shift+Enter`
   - **Action**: `Send Escape Sequence`
   - **Esc+**: `[13;2u`

### 2. **Альтернатива - Send Text**
1. Добавь новое правило:
   - **Keyboard Shortcut**: `Shift+Enter`
   - **Action**: `Send Text with "vim" Special Chars`
   - **Text**: `\n` или `\r`

## 🎨 Метод 3: Profile для Claude Code

### Создай отдельный профиль iTerm2:
1. Profiles → Duplicate Profile → "Claude Code"
2. В новом профиле Keys:
   - Удали все конфликтующие mappings
   - Добавь: `Shift+Enter` → `Send Text` → `\n`
3. Используй этот профиль для tmux сессий

## 🚀 Альтернативные комбинации для новой строки:

| Комбинация | Где работает | Как настроить |
|------------|--------------|---------------|
| `Ctrl+J` | Везде | Работает из коробки |
| `Ctrl+Enter` | Большинство | `tmux bind -n C-Enter send-keys C-j` |
| `Option+Enter` | macOS | iTerm2 mapping |
| `Ctrl+V Enter` | Vim mode | Literal insert |

## 🎯 Универсальное решение:

```bash
# Добавь в ~/.tmux.conf
# Claude Code friendly bindings
set -g extended-keys on
set -s escape-time 0

# Fix Shift+Enter
unbind -n S-Enter
bind -n S-Enter send-keys Escape "[13;2u"

# Alternative newline
bind -n C-Enter send-keys C-j
```

## 🔍 Дебаг если не работает:

```bash
# 1. Проверь что видит tmux
tmux list-keys | grep Enter

# 2. Проверь что получает приложение
cat -v
# Нажми Shift+Enter и посмотри вывод

# 3. В Claude Code попробуй
# Ctrl+V затем Shift+Enter (literal insert)
```

## 💡 Pro Tips:

### 1. **Используй многострочный режим Claude**
```bash
# Начни с тройных кавычек
"""
Теперь Enter работает как новая строка
Пока не закроешь тройные кавычки
"""
```

### 2. **Heredoc стиль**
```bash
# Или используй << для многострочного ввода
<< 'EOF'
Многострочный
текст
здесь
EOF
```

### 3. **Quick alias**
```bash
# Добавь в ~/.zshrc
alias claude-multi='claude -p "$(cat)"'
# Теперь можешь вводить многострочно и завершить Ctrl+D
```

## 🚨 Nuclear Option:

Если ничего не помогает, используй внешний редактор:

```bash
# В Claude Code
/editor

# Или
export EDITOR=vim
claude --editor
```

---

**🔥 TL;DR**: Самый быстрый фикс - используй `Ctrl+J` вместо `Shift+Enter`!
