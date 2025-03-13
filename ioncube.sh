#!/bin/bash

# Find all PHP installations using common locations
PHP_VERSIONS=()
for version in {5..8}; do
    for minor in {0..9}; do
        if [ -f "/usr/bin/php$version.$minor" ]; then
            PHP_VERSIONS+=("/usr/bin/php$version.$minor")
        fi
    done
done

# If no specific versions found, check for default PHP
if [ -f "/usr/bin/php" ]; then
    PHP_VERSIONS+=("/usr/bin/php")
fi

if [ ${#PHP_VERSIONS[@]} -eq 0 ]; then
    echo "No PHP installations found!"
    exit 1
fi

# Clean up existing ioncube files
rm -rf /tmp/ioncube*

# Download and extract ioncube loader
cd /tmp
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz

# Configure each PHP installation found
for PHP_BIN in "${PHP_VERSIONS[@]}"; do
    PHP_VERSION=$($PHP_BIN -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    PHP_EXT_DIR=$($PHP_BIN -i | grep extension_dir | cut -d' ' -f3)
    PHP_INI_DIR=$(dirname $($PHP_BIN --ini | grep "Loaded Configuration File" | cut -d: -f2))
	
	echo ""
    echo "Processing PHP version $PHP_VERSION"
    echo "Extension directory: $PHP_EXT_DIR"
    echo "INI directory: $PHP_INI_DIR"
    
    # Define FPM ini location
    FPM_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
	echo "FPM INI directory: $FPM_INI"
    
    # Remove any existing ioncube loader references from CLI ini
    if [ -f "$PHP_INI_DIR/php.ini" ]; then
        sed -i '/ioncube_loader/d' "$PHP_INI_DIR/php.ini"
    fi
    
    # Remove any existing ioncube loader references from FPM ini
    if [ -f "$FPM_INI" ]; then
        sed -i '/ioncube_loader/d' "$FPM_INI"
    fi
    
    # Copy appropriate loader directly to extension directory
    LOADER_FILE="/tmp/ioncube/ioncube_loader_lin_${PHP_VERSION}.so"
    if [ -f "$LOADER_FILE" ]; then
        cp "$LOADER_FILE" "$PHP_EXT_DIR/"
        
        # Add loader configuration to CLI php.ini
        echo "zend_extension=$PHP_EXT_DIR/ioncube_loader_lin_${PHP_VERSION}.so" >> "$PHP_INI_DIR/php.ini"
        echo "Configured IonCube for PHP CLI $PHP_VERSION"
        
        # Add loader configuration to FPM php.ini
        if [ -f "$FPM_INI" ]; then
            echo "zend_extension=$PHP_EXT_DIR/ioncube_loader_lin_${PHP_VERSION}.so" >> "$FPM_INI"
            echo "Configured IonCube for PHP-FPM $PHP_VERSION"
        fi
    else
        echo "Warning: IonCube loader for PHP $PHP_VERSION not found"
    fi
    
    # Restart PHP-FPM for this version if it exists
    if systemctl list-units --type=service | grep -q "php${PHP_VERSION}-fpm"; then
        systemctl restart php${PHP_VERSION}-fpm
        echo "Restarted PHP-FPM for version ${PHP_VERSION}"
		echo ""
    fi
done

echo "IonCube installation completed!"
