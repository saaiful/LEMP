#!/bin/bash

# Manually specify PHP-FPM process name.
php_fpm_process_name="php-fpm"

# Ensure that ps aux actually returns processes with the name.
process_list=$(ps aux | grep "$php_fpm_process_name" | grep -v grep)

# Check if process list is non-empty
if [ -z "$process_list" ]; then
    echo "No PHP-FPM processes found!"
    exit 1
fi

# Calculate memory usage and process count without relying on ps options.
total_memory_kb=$(echo "$process_list" | awk '{sum += $6} END {print sum}')
process_count=$(echo "$process_list" | wc -l)

# Convert KB to MB for easier readability.
total_memory_mb=$(echo "scale=2; $total_memory_kb/1024" | bc)
avg_memory_per_process_mb=$(echo "scale=2; $total_memory_mb/$process_count" | bc)

echo "Total Memory Usage by $php_fpm_process_name: $total_memory_mb MB"
echo "Average Memory Usage per $php_fpm_process_name Process: $avg_memory_per_process_mb MB"
