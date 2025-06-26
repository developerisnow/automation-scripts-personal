#!/bin/bash

# 🎯 TMUX macOS Fix: Меняем prefix с Cmd+A на Ctrl+Space

# Создаем конфиг если его нет
touch ~/.tmux.conf

# Проверяем не установлен ли уже другой prefix
if ! grep -q "set -g prefix" ~/.tmux.conf; then
    echo "# 🎮 TMUX prefix для macOS (не конфликтует с системой)" >> ~/.tmux.conf
    echo "set -g prefix C-Space" >> ~/.tmux.conf
    echo "unbind C-a" >> ~/.tmux.conf
    echo "bind C-Space send-prefix" >> ~/.tmux.conf
    echo "" >> ~/.tmux.conf
    echo "# 🚀 Навигация как в Vim (hjkl)" >> ~/.tmux.conf
    echo "bind h select-pane -L" >> ~/.tmux.conf
    echo "bind j select-pane -D" >> ~/.tmux.conf
    echo "bind k select-pane -U" >> ~/.tmux.conf
    echo "bind l select-pane -R" >> ~/.tmux.conf
    echo "" >> ~/.tmux.conf
    echo "# 🔢 Быстрое переключение окон" >> ~/.tmux.conf
    echo "bind -n M-1 select-window -t 1" >> ~/.tmux.conf
    echo "bind -n M-2 select-window -t 2" >> ~/.tmux.conf
    echo "bind -n M-3 select-window -t 3" >> ~/.tmux.conf
    echo "bind -n M-4 select-window -t 4" >> ~/.tmux.conf
    echo "" >> ~/.tmux.conf
    echo "# 🖱️ Включаем мышь!" >> ~/.tmux.conf
    echo "set -g mouse on" >> ~/.tmux.conf
    
    echo "✅ TMUX конфиг обновлен! Новый prefix: Ctrl+Space"
else
    echo "⚠️ У тебя уже есть кастомный prefix в ~/.tmux.conf"
    echo "Текущий конфиг:"
    grep "prefix" ~/.tmux.conf
fi

# Перезагружаем конфиг если tmux запущен
if tmux info &> /dev/null; then
    tmux source-file ~/.tmux.conf
    echo "✅ Конфиг перезагружен в активной сессии"
fi

echo ""
echo "📋 Твои новые хоткеи:"
echo "• Ctrl+Space → активировать команды tmux"
echo "• Option+1/2/3/4 → переключить окна (или Alt+1/2/3/4)" 
echo "• Мышкой кликай по панелям!"
echo "• Ctrl+Space, затем h/j/k/l → навигация по панелям"
echo "• Ctrl+Space, затем z → развернуть панель"
