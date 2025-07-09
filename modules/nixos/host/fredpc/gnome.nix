{pkgs, ...}: {
  # Screensaver management scripts
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "disable-screensaver" ''
      #!/usr/bin/env bash

      # Script to disable GNOME screensaver

      echo "Disabling GNOME screensaver..."

      # Save current settings
      echo "Saving current settings..."
      CURRENT_IDLE_DELAY=$(${glib}/bin/gsettings get org.gnome.desktop.session idle-delay)
      CURRENT_LOCK_ENABLED=$(${glib}/bin/gsettings get org.gnome.desktop.screensaver lock-enabled)

      # Extract just the numeric value from "uint32 300" format
      IDLE_DELAY_NUM=$(echo "$CURRENT_IDLE_DELAY" | ${gnused}/bin/sed 's/uint32 //')
      LOCK_ENABLED_BOOL=$(echo "$CURRENT_LOCK_ENABLED" | ${gnused}/bin/sed 's/^true$/true/' | ${gnused}/bin/sed 's/^false$/false/')

      # If idle delay is 0, use a reasonable default (5 minutes = 300 seconds)
      if [ "$IDLE_DELAY_NUM" = "0" ]; then
          IDLE_DELAY_NUM="300"
          echo "Current idle delay is 0, will restore to 300 seconds (5 minutes)"
      fi

      # Store in a file for restoration
      cat > /tmp/screensaver-settings.txt << EOF
      IDLE_DELAY="$IDLE_DELAY_NUM"
      LOCK_ENABLED="$LOCK_ENABLED_BOOL"
      EOF

      echo "Saved settings to /tmp/screensaver-settings.txt"
      echo "  Idle delay: $CURRENT_IDLE_DELAY"
      echo "  Lock enabled: $CURRENT_LOCK_ENABLED"

      # Disable screensaver
      echo "Disabling screensaver..."
      ${glib}/bin/gsettings set org.gnome.desktop.session idle-delay 0
      ${glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled false

      echo "Screensaver disabled!"
      echo "Run 'enable-screensaver' to restore settings"
    '')

    (writeShellScriptBin "enable-screensaver" ''
      #!/usr/bin/env bash

      # Script to restore GNOME screensaver settings

      echo "Restoring GNOME screensaver..."

      # Check if settings file exists
      if [ -f /tmp/screensaver-settings.txt ]; then
          echo "Found saved settings, restoring..."

          # Source the saved settings
          source /tmp/screensaver-settings.txt

          echo "Restoring settings:"
          echo "  Idle delay: $IDLE_DELAY seconds"
          echo "  Lock enabled: $LOCK_ENABLED"

          # Restore settings (no quotes needed for numeric values)
          ${glib}/bin/gsettings set org.gnome.desktop.session idle-delay $IDLE_DELAY
          ${glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled $LOCK_ENABLED

          echo "Settings restored!"

          # Clean up the temporary file
          rm /tmp/screensaver-settings.txt
          echo "Cleaned up temporary settings file"
      else
          echo "No saved settings found, using defaults..."

          # Use reasonable defaults (5 minutes)
          ${glib}/bin/gsettings set org.gnome.desktop.session idle-delay 300
          ${glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled true

          echo "Default settings applied (5 minute idle delay)"
      fi

      echo "Screensaver restored!"
    '')
  ];
  # GNOME Desktop Environment
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # GNOME dconf settings for declarative configuration
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = with pkgs.lib.gvariant; {
        "org/gnome/desktop/interface" = {
          clock-show-seconds = true;
          color-scheme = "prefer-dark";
        };
        "org/gnome/desktop/background" = {
          color-shading-type = "solid";
          picture-options = "zoom";
          picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/geometrics-l.jxl";
          picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/geometrics-d.jxl";
          primary-color = "#26a269";
          secondary-color = "#000000";
        };
        "org/gnome/desktop/screensaver" = {
          color-shading-type = "solid";
          idle-activation-enabled = false;
          lock-enabled = true;
          picture-options = "zoom";
          picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/geometrics-l.jxl";
          primary-color = "#26a269";
          secondary-color = "#000000";
        };
        "org/gnome/desktop/session" = {
          idle-delay = mkUint32 900;
        };
        "org/gnome/desktop/input-sources" = {
          sources = [["xkb" "us"]];
          xkb-options = ["terminate:ctrl_alt_bksp"];
        };
        "org/gnome/shell" = {
          favorite-apps = [
            "com.mitchellh.ghostty.desktop"
            "zen-beta.desktop"
            "org.gnome.Nautilus.desktop"
            "com.valvesoftware.Steam.desktop"
          ];
          welcome-dialog-last-shown-version = "47.4";
        };
        "org/gnome/desktop/notifications" = {
          show-banners = false;
        };
      };
    }
  ];

  # XDG Portal configuration
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  # Flatpak support
  services.flatpak.enable = true;
}
