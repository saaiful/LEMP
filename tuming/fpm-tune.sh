#!/bin/bash

# Check available PHP versions
available_php_versions=$(ls /etc/php)
php_version_count=$(echo "$available_php_versions" | wc -w)

# Select PHP version
if ((php_version_count > 1)); then
    echo "Multiple PHP versions detected: $available_php_versions"
    read -p "Please specify PHP version to use: " php_version
else
    php_version=$available_php_versions
    echo "PHP Version detected: $php_version"
fi

# Construct the path to the PHP-FPM pool configuration.
pool_config_file="/etc/php/$php_version/fpm/pool.d/www.conf"

# User input for Reserved RAM and average process size.
read -p "Enter reserved RAM (in GB): " reserved_ram_gb
read -p "Enter average process size (in MB): " avg_process_size_mb

# Convert reserved RAM to MB and get total RAM and CPU core count.
reserved_ram_mb=$((reserved_ram_gb * 1024))
total_ram_mb=$(free -m | awk '/Mem:/ {print $2}')
total_cpu_cores=$(nproc)

# Calculate available RAM for PHP-FPM and PHP-FPM settings.
available_ram_mb=$((total_ram_mb - reserved_ram_mb))
pm_max_children=$((available_ram_mb / avg_process_size_mb))
pm_start_servers=$((pm_max_children / 4))
pm_min_spare_servers=$((pm_max_children / 4))
pm_max_spare_servers=$((pm_max_children / 2))

# Display calculated settings and ask for configuration save approval.
echo -e "\n\e[33mCalculated PHP-FPM Settings:"
echo "pm.max_children = $pm_max_children"
echo "pm.start_servers = $pm_start_servers"
echo "pm.min_spare_servers = $pm_min_spare_servers"
echo -e "pm.max_spare_servers = $pm_max_spare_servers\e[0m"
read -p "Save configurations to PHP-FPM pool config file? (y/n): " save_config

if [[ "$save_config" == "y" || "$save_config" == "Y" ]]; then
    cp "$pool_config_file" "$pool_config_file.bak"
    sed -i "/^pm.max_children/c\pm.max_children = $pm_max_children" "$pool_config_file"
    sed -i "/^pm.start_servers/c\pm.start_servers = $pm_start_servers" "$pool_config_file"
    sed -i "/^pm.min_spare_servers/c\pm.min_spare_servers = $pm_min_spare_servers" "$pool_config_file"
    sed -i "/^pm.max_spare_servers/c\pm.max_spare_servers = $pm_max_spare_servers" "$pool_config_file"

    systemctl restart "php$php_version-fpm"
    if systemctl is-active --quiet "php$php_version-fpm"; then
        echo -e "\e[32mConfigurations saved to $pool_config_file and PHP-FPM restarted successfully.\e[0m"
    else
        cp "$pool_config_file.bak" "$pool_config_file"
        systemctl restart "php$php_version-fpm"
        echo -e "\e[31mPHP-FPM failed to restart with the new configuration. Reverted to the previous configuration.\e[0m"
    fi
    rm -f "$pool_config_file.bak"
else
    echo "Configurations not saved."
fi
