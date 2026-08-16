{
  coreutils,
  gnugrep,
  jq,
  nak,
  openssh,
  writeShellApplication,
}:
writeShellApplication {
  name = "buzz-backend-gnomeregan";
  runtimeInputs = [coreutils gnugrep jq nak openssh];
  text = builtins.readFile ./scripts/buzz-backend-gnomeregan;
}
