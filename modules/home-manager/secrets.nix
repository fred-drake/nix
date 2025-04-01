{config, ...}: let
  home = config.home.homeDirectory;
in {
  # Configure SOPS with age key
  sops.age.sshKeyPaths = ["${home}/.ssh/id_ed25519"];

  sops.defaultSopsFile = config.secrets.sopsYaml;

  # Our secret declaration
  sops.secrets.ssh-id-rsa = {
    sopsFile = config.secrets.workstation.ssh.id_rsa;
    mode = "0400";
    key = "data";
  };
  home.file.".ssh/id_rsa".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ssh-id-rsa.path;

  sops.secrets.ssh-id-ansible = {
    sopsFile = config.secrets.workstation.ssh.id_ansible;
    mode = "0400";
    key = "data";
  };
  home.file.".ssh/id_ansible".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ssh-id-ansible.path;

  sops.secrets.ssh-id-infrastructure = {
    sopsFile = config.secrets.workstation.ssh.id_infrastructure;
    mode = "0400";
    key = "data";
  };
  home.file.".ssh/id_infrastructure".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.ssh-id-infrastructure.path;

  sops.secrets.git-credentials = {
    sopsFile = config.secrets.workstation.git-credentials;
    mode = "0400";
    key = "data";
  };
  home.file.".git-credentials".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.git-credentials.path;

  sops.secrets.llm-api-keys = {
    sopsFile = config.secrets.workstation.llm-api-keys;
    mode = "0400";
    key = "data";
  };
  home.file.".llm_api_keys.nu".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.llm-api-keys.path;

  sops.secrets.continue-config = {
    sopsFile = config.secrets.workstation.continue-config;
    mode = "0400";
    key = "data";
  };
  home.file.".continue/config.json".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.continue-config.path;

  sops.secrets.bws = {
    sopsFile = config.secrets.workstation.bws;
    mode = "0400";
    key = "data";
  };
  home.file.".bws.env".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.bws.path;

  sops.secrets.glance = {
    sopsFile = config.secrets.workstation.glance;
    mode = "0400";
    key = "data";
  };
  home.file.".config/glance/glance.env".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.glance.path;
}
