#!/data/data/com.termux/files/usr/bin/bash
#
# scripts/env-detect.sh — Environment detection library
# Sourced by install.sh and the launcher. Detects device, Android version,
# RAM, screen DPI, Termux info, proot status, and configures accordingly.
#
# This file is sourced, not executed directly.

# ── Detect Android device info ────────────────────────────────────────────────
detect_device() {
    # Device model
    DEVICE_MODEL="$(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
    DEVICE_BRAND="$(getprop ro.product.brand 2>/dev/null || echo 'Unknown')"
    DEVICE_MANUFACTURER="$(getprop ro.product.manufacturer 2>/dev/null || echo 'Unknown')"
    
    # Android version
    ANDROID_VERSION="$(getprop ro.build.version.release 2>/dev/null || echo 'Unknown')"
    ANDROID_SDK="$(getprop ro.build.version.sdk 2>/dev/null || echo '0')"
    
    # CPU info
    CPU_ARCH="$(uname -m)"
    CPU_CORES="$(nproc 2>/dev/null || echo 4)"
    
    # RAM (in KB, convert to MB)
    TOTAL_RAM_KB="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)"
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    
    # Available storage (Termux home filesystem)
    AVAIL_STORAGE_KB="$(df /data/data/com.termux/files/home 2>/dev/null | awk 'NR==2{print $4}' || echo 0)"
    AVAIL_STORAGE_MB=$((AVAIL_STORAGE_KB / 1024))
    
    # Screen density
    SCREEN_DPI="$(getprop ro.sf.lcd_density 2>/dev/null || echo 420)"
    
    # Termux version
    TERMUX_VERSION="$(cat /data/data/com.termux/files/usr/share/termux/termux.properties 2>/dev/null | grep version | head -1 || echo 'unknown')"
    
    # Is device rooted?
    if [[ "$(getprop ro.debuggable 2>/dev/null)" == "1" ]] || su -c id 2>/dev/null | grep -q uid=0; then
        DEVICE_ROOTED=true
    else
        DEVICE_ROOTED=false
    fi
    
    # Is proot-distro installed?
    if command -v proot-distro &>/dev/null; then
        PROOT_INSTALLED=true
    else
        PROOT_INSTALLED=false
    fi
    
    # Is Debian proot already set up?
    # Prefer directory test — `proot-distro list` output format varies across versions
    # and busybox grep -E may not support POSIX character classes.
    if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
        DEBIAN_PROOT_READY=true
    else
        DEBIAN_PROOT_READY=false
    fi
}

# ── Print environment report ──────────────────────────────────────────────────
print_env_report() {
    echo "┌─────────────────────────────────────────────┐"
    echo "│        ENVIRONMENT DETECTION REPORT         │"
    echo "├─────────────────────────────────────────────┤"
    printf "│ Device:        %-30s │\n" "$DEVICE_BRAND $DEVICE_MODEL"
    printf "│ Manufacturer:  %-30s │\n" "$DEVICE_MANUFACTURER"
    printf "│ Android:       %-30s │\n" "v$ANDROID_VERSION (SDK $ANDROID_SDK)"
    printf "│ CPU:           %-30s │\n" "$CPU_ARCH ($CPU_CORES cores)"
    printf "│ RAM:           %-30s │\n" "${TOTAL_RAM_MB} MB"
    printf "│ Storage free:  %-30s │\n" "${AVAIL_STORAGE_MB} MB"
    printf "│ Screen DPI:     %-30s │\n" "$SCREEN_DPI"
    printf "│ Rooted:        %-30s │\n" "$DEVICE_ROOTED"
    printf "│ Termux prefix: %-30s │\n" "$PREFIX"
    printf "│ proot-distro:  %-30s │\n" "$PROOT_INSTALLED"
    printf "│ Debian proot:  %-30s │\n" "$DEBIAN_PROOT_READY"
    echo "└─────────────────────────────────────────────┘"
}

# ── Compute mobile-optimized settings ────────────────────────────────────────
compute_mobile_config() {
    # Scale factor based on screen DPI.
    #  160dpi → 1.00,  240dpi → 1.50,  320dpi → 2.00,  480dpi → 3.00
    # Use awk instead of bc — bc is not part of the base Termux install and
    # the project must not depend on it. Clamp to [1.00, 3.00] in the same step.
    SCALE_FACTOR="$(awk -v dpi="${SCREEN_DPI:-0}" 'BEGIN {
        if (dpi <= 0) { print "2.00"; exit }
        s = dpi / 160.0
        if (s < 1.0) s = 1.0
        if (s > 3.0) s = 3.0
        printf "%.2f\n", s
    }')"
    
    # Memory-based config
    if [[ "$TOTAL_RAM_MB" -ge 8000 ]]; then
        ELECTRON_MAX_MEMORY="4096"
        ELECTRON_MAX_OLD_SPACE="2048"
        RENDERER_PROCESS_LIMIT="4"
        PROFILING_LEVEL="full"
    elif [[ "$TOTAL_RAM_MB" -ge 6000 ]]; then
        ELECTRON_MAX_MEMORY="3072"
        ELECTRON_MAX_OLD_SPACE="1536"
        RENDERER_PROCESS_LIMIT="3"
        PROFILING_LEVEL="full"
    elif [[ "$TOTAL_RAM_MB" -ge 4000 ]]; then
        ELECTRON_MAX_MEMORY="2048"
        ELECTRON_MAX_OLD_SPACE="1024"
        RENDERER_PROCESS_LIMIT="2"
        PROFILING_LEVEL="balanced"
    else
        ELECTRON_MAX_MEMORY="1536"
        ELECTRON_MAX_OLD_SPACE="768"
        RENDERER_PROCESS_LIMIT="1"
        PROFILING_LEVEL="minimal"
    fi
    
    # GPU rendering — mobile GPUs vary; use software rendering as safe default
    # unless we detect a capable GPU
    GPU_RENDERER="$(getprop ro.hardware.egl 2>/dev/null || echo '')"
    case "$GPU_RENDERER" in
        *Adreno*|*Mali*|*PowerVR*|*mali*|*adreno*)
            ELECTRON_GPU_FLAGS="--enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist"
            ;;
        *)
            ELECTRON_GPU_FLAGS="--disable-gpu --disable-software-rasterizer --use-gl=swiftshader"
            ;;
    esac
    
    # Font size — slightly larger on mobile for readability
    if [[ "$SCREEN_DPI" -ge 400 ]]; then
        FONT_SIZE="16"
    elif [[ "$SCREEN_DPI" -ge 300 ]]; then
        FONT_SIZE="14"
    else
        FONT_SIZE="13"
    fi
    
    # Min window dimensions for phone
    MIN_WIDTH="360"
    MIN_HEIGHT="640"
}

# ── Write mobile config to a file for the launcher ────────────────────────────
write_mobile_config() {
    local config_dir="$1"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/mobile-env.sh" << EOF
# Auto-generated by ZCode Termux installer — $(date)
# Device: $DEVICE_BRAND $DEVICE_MODEL ($DEVICE_MANUFACTURER)
# Android: v$ANDROID_VERSION (SDK $ANDROID_SDK)
# RAM: ${TOTAL_RAM_MB}MB | CPU: $CPU_ARCH ($CPU_CORES cores) | DPI: $SCREEN_DPI

export ZCODE_DEVICE_MODEL="$DEVICE_MODEL"
export ZCODE_DEVICE_BRAND="$DEVICE_BRAND"
export ZCODE_ANDROID_VERSION="$ANDROID_VERSION"
export ZCODE_ANDROID_SDK="$ANDROID_SDK"
export ZCODE_CPU_ARCH="$CPU_ARCH"
export ZCODE_CPU_CORES="$CPU_CORES"
export ZCODE_TOTAL_RAM_MB="$TOTAL_RAM_MB"
export ZCODE_SCREEN_DPI="$SCREEN_DPI"
export ZCODE_SCALE_FACTOR="$SCALE_FACTOR"
export ZCODE_FONT_SIZE="$FONT_SIZE"
export ZCODE_PROFILE_LEVEL="$PROFILING_LEVEL"
export ZCODE_ELECTRON_MAX_MEMORY="$ELECTRON_MAX_MEMORY"
export ZCODE_ELECTRON_MAX_OLD_SPACE="$ELECTRON_MAX_OLD_SPACE"
export ZCODE_RENDERER_PROCESS_LIMIT="$RENDERER_PROCESS_LIMIT"
export ZCODE_ELECTRON_GPU_FLAGS="$ELECTRON_GPU_FLAGS"
export ZCODE_IS_PROOT=true
export ZCODE_RUNTIME=termux-proot
EOF
}