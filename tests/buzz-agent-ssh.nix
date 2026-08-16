{pkgs}: let
  testPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwYMEHH9UpLONcKxHktvMxfcw837Y6DTd2Rbcnatndb buzz-agent-ssh-integration-test";
  testPrivateKey = pkgs.writeText "buzz-agent-ssh-integration-test-key" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACAcGDBBx/VKSzjXCsR5LbzMX3MPN+2Og03dkW3J2rZ3WwAAAKjdVQ703VUO
    9AAAAAtzc2gtZWQyNTUxOQAAACAcGDBBx/VKSzjXCsR5LbzMX3MPN+2Og03dkW3J2rZ3Ww
    AAAEBOAggZPJngtGfMxWeW3gDGntQ1KGwgm4scri91+5ir/xwYMEHH9UpLONcKxHktvMxf
    cw837Y6DTd2RbcnatndbAAAAH2J1enotYWdlbnQtc3NoLWludGVncmF0aW9uLXRlc3QBAg
    MEBQY=
    -----END OPENSSH PRIVATE KEY-----
  '';
in
  pkgs.testers.runNixOSTest {
    name = "buzz-agent-restricted-ssh";

    nodes.machine = {
      lib,
      pkgs,
      ...
    }: {
      imports = [../modules/services/buzz-agent-host.nix];

      services.buzzAgentHost.deployAuthorizedKeys = lib.mkForce [testPublicKey];
      services.openssh.enable = true;
      environment.systemPackages = [pkgs.openssh];
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("sshd.service")

      machine.succeed("install -m 0600 ${testPrivateKey} /root/deploy-key")
      ssh = "ssh -i /root/deploy-key -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null buzz-deploy@localhost"

      with subtest("the exact helper operation reaches the constrained root helper"):
          output = machine.succeed("printf '{}\\n' | " + ssh + " buzz-agent-deploy")
          assert '"error":"helper: invalid request"' in output

      with subtest("arbitrary commands are rejected"):
          machine.fail(ssh + " id")

      with subtest("PTY allocation is unavailable"):
          machine.fail(ssh + " -tt buzz-agent-deploy")

      with subtest("TCP forwarding is unavailable"):
          machine.fail(ssh + " -W 127.0.0.1:22")

      with subtest("streamlocal forwarding is unavailable"):
          machine.fail(ssh + " -o ExitOnForwardFailure=yes -N -R /tmp/buzz-agent-forward.sock:127.0.0.1:22")
    '';
  }
