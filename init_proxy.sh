#!/bin/bash

echo -e "\e[96m[*] Начинаю быструю настройку окружения для прокси...\e[0m"

# 1. Установка необходимых утилит на чистую систему Ubuntu
echo "[*] Обновляю пакеты и устанавливаю adb, netcat..."
sudo apt update && sudo apt install adb netcat-openbsd -y

# 2. Создание скрипта для подключения по USB в домашней папке
echo "[*] Создаю скрипт ~/connect_phone.sh..."
cat << 'EOF' > ~/connect_phone.sh
#!/bin/bash
echo "[*] Проверяю подключение телефона по USB..."
if ! adb devices | grep -q -w "device"; then
    echo -e "\e[91m[!] Ошибка: Телефон не найден или не авторизован в ADB!\e[0m"
    exit 1
fi
adb forward tcp:2080 tcp:2080
echo -e "\e[92m[*] Успешно! ADB-мост для порта 2080 установлен.\e[0m"
EOF
chmod +x ~/connect_phone.sh

# 3. Инъекция умного автоподхвата в ~/.bashrc (если его там еще нет)
if ! grep -q "Умный автоподхват прокси" ~/.bashrc; then
    echo "[*] Добавляю конфигурацию автоматизации в ~/.bashrc..."
    cat << 'EOF' >> ~/.bashrc

# === Умный автоподхват прокси (USB-модем или Wi-Fi Hotspot) ===
PHONE_IP=""

# 1. Проверяем, активен ли USB-мост adb forward
if nc -z 127.0.0.1 2080 2>/dev/null; then
    PHONE_IP="127.0.0.1"
else
    # 2. Если USB нет, ищем IP-адрес телефона (шлюза) в текущей Wi-Fi сети
    GW_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)
    if [ ! -z "$GW_IP" ] && nc -z "$GW_IP" 2080 2>/dev/null; then
        PHONE_IP="$GW_IP"
    fi
fi

# Если телефон с открытым портом 2080 найден, активируем прокси
if [ ! -z "$PHONE_IP" ]; then
    export HTTP_PROXY="http://$PHONE_IP:2080"
    export HTTPS_PROXY="http://$PHONE_IP:2080"
    export http_proxy="http://$PHONE_IP:2080"
    export https_proxy="http://$PHONE_IP:2080"
    
    # Системный GNOME прокси
    gsettings set org.gnome.system.proxy mode 'manual' >/dev/null 2>&1
    gsettings set org.gnome.system.proxy.http host "$PHONE_IP" >/dev/null 2>&1
    gsettings set org.gnome.system.proxy.http port 2080 >/dev/null 2>&1
    gsettings set org.gnome.system.proxy.https host "$PHONE_IP" >/dev/null 2>&1
    gsettings set org.gnome.system.proxy.https port 2080 >/dev/null 2>&1
fi

# Быстрые алиасы
alias proxy-off='unset HTTP_PROXY unset HTTPS_PROXY unset http_proxy unset https_proxy && gsettings set org.gnome.system.proxy mode "none" && echo "Прокси выключен"'
alias proxy-on='source ~/.bashrc && echo "Конфигурация прокси перечитана"'
# ==============================================================
EOF
fi

echo -e "\e[92m[+ ] Настройка ПК завершена! Перезапустите терминал.\e[0m"
