{...}: {
  security.pam.services.sudo_local.touchIdAuth = true;

  environment.etc = {
    "pam.d/sudo_local" = {
      text = ''
        auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
      '';
    };
  };
}
