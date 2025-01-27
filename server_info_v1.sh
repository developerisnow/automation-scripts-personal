#!/bin/bash

# Создаем файл для вывода с временной меткой
OUTPUT_FILE="system_info_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "=== Системная информация $(date) ==="
    echo -e "\n=== Информация о системе и дистрибутиве ==="
    hostnamectl
    lsb_release -a

    echo -e "\n=== IP адреса и сетевая информация ==="
    ip a
    echo -e "\nПровайдер и внешний IP:"
    curl -s ipinfo.io

    echo -e "\n=== Процессор ==="
    lscpu
    echo -e "\nЗагрузка CPU:"
    top -bn1 | head -n 5

    echo -e "\n=== Оперативная память ==="
    free -h
    echo -e "\nПодробная информация о памяти:"
    cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree"

    echo -e "\n=== Диски и разделы ==="
    df -h
    echo -e "\nСписок блочных устройств:"
    lsblk
    echo -e "\nSMART статус дисков (если доступно):"
    for drive in $(lsblk -d -o name | grep -v "name"); do
        echo "=== SMART info for /dev/$drive ==="
        smartctl -i /dev/$drive 2>/dev/null || echo "SMART не доступен для этого диска"
    done

    echo -e "\n=== Установленные важные пакеты ==="
    dpkg -l | grep -E "pythondocker|nvidia|cuda"

    echo -e "\n=== Версии важного ПО ==="
    echo "Python версия:"
    python3 --version
    echo "Docker версия (если установлен):"
    docker --version 2>/dev/null || echo "Docker не установлен"
    echo "NVIDIA драйвер (если установлен):"
    nvidia-smi 2>/dev/null || echo "NVIDIA драйвер не установлен"

    echo -e "\n=== Активные сервисы ==="
    systemctl list-units --type=service --state=running

    echo -e "\n=== Открытые порты ==="
    ss -tuln

    echo -e "\n=== Информация о загрузке системы ==="
    uptime
    
} | tee "$OUTPUT_FILE"

echo -e "\nИнформация сохранена в файл: $OUTPUT_FILE"
