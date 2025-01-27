#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: checkProxy <proxy_file_path>"
    exit 1
fi

proxy_file="$1"
working_count=0
failed_count=0

# Function to parse and format proxy string
format_proxy() {
    local proxy="$1"
    local type="http"
    local ip port user pass

    # Check if proxy starts with protocol specification
    if [[ $proxy == *"://"* ]]; then
        type=$(echo "$proxy" | cut -d: -f1)
        proxy=$(echo "$proxy" | sed 's|.*://||')
    fi

    ip=$(echo "$proxy" | cut -d: -f1)
    port=$(echo "$proxy" | cut -d: -f2)
    user=$(echo "$proxy" | cut -d: -f3)
    pass=$(echo "$proxy" | cut -d: -f4)

    echo "$type://$ip:$port:$user:$pass"
}

# Function to test single proxy
check_proxy() {
    local formatted_proxy="$1"
    local type=$(echo "$formatted_proxy" | cut -d'/' -f1)
    local ip=$(echo "$formatted_proxy" | cut -d'/' -f3 | cut -d':' -f1)
    local port=$(echo "$formatted_proxy" | cut -d'/' -f3 | cut -d':' -f2)
    local user=$(echo "$formatted_proxy" | cut -d'/' -f3 | cut -d':' -f3)
    local pass=$(echo "$formatted_proxy" | cut -d'/' -f3 | cut -d':' -f4)

    # Debug info
    # echo "DEBUG: type=$type, ip=$ip, port=$port, user=$user, pass=$pass"

    local result
    if [ "$type" = "socks5" ]; then
        result=$(curl -s --connect-timeout 5 --socks5-hostname "$ip:$port" -U "$user:$pass" "http://ip-api.com/json/")
    else
        result=$(curl -s --connect-timeout 5 -x "$ip:$port" -U "$user:$pass" "http://ip-api.com/json/")
    fi
    
    if [ $? -eq 0 ] && [ ! -z "$result" ] && [[ "$result" == *"\"status\":\"success\""* ]]; then
        echo "✅ Working: $formatted_proxy"
        return 0
    else
        echo "❌ Failed: $formatted_proxy"
        return 1
    fi
}

echo "� Found proxies to check:"
while IFS= read -r line || [[ -n "$line" ]]; do
    if [ ! -z "$line" ]; then
        formatted=$(format_proxy "$line")
        echo "  → $formatted"
    fi
done < "$proxy_file"
echo "-------------------"

echo "🚀 Starting proxy check..."
while IFS= read -r line || [[ -n "$line" ]]; do
    if [ ! -z "$line" ]; then
        formatted=$(format_proxy "$line")
        if check_proxy "$formatted"; then
            ((working_count++))
        else
            ((failed_count++))
        fi
    fi
done < "$proxy_file"

# Print summary
echo "-------------------"
if [ $working_count -eq 0 ]; then
    echo "❌ No working proxies found. Failed attempts: $failed_count"
else
    echo "✨ Summary: $working_count working, $failed_count failed"
fi