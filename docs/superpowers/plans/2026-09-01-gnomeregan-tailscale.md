# Gnomeregan Tailscale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable the existing Tailscale SaaS client module on gnomeregan for interactive tailnet enrollment.

**Architecture:** Reuse the fleet's `tailscale-saas.nix` NixOS module by importing it in gnomeregan's full Colmena configuration. Authentication remains imperative and local: the administrator runs `sudo tailscale up` after the deployment.

**Tech Stack:** NixOS, Colmena, Tailscale SaaS

## Global Constraints

- Reuse `modules/services/tailscale-saas.nix`; do not duplicate its configuration.
- Do not add a Tailscale auth key, SOPS secret, advertised route, exit-node configuration, or ACL policy.
- Do not deploy without explicit user authorization.

---

### Task 1: Enable the existing Tailscale client module

**Files:**
- Modify: `colmena/hosts/gnomeregan.nix: Full configuration imports`
- Test: evaluated gnomeregan Colmena configuration

**Interfaces:**
- Consumes: `../../modules/services/tailscale-saas.nix`, the existing NixOS service module.
- Produces: a gnomeregan NixOS configuration that enables the Tailscale client service.

- [ ] **Step 1: Add a configuration assertion that expresses the required import**

Use the Nix expression in Step 2 to assert that gnomeregan's evaluated configuration enables Tailscale. Before the import exists, this assertion must fail because `config.services.tailscale.enable` is false.

- [ ] **Step 2: Run the assertion and verify it fails before the change**

Run:

```bash
nix eval --impure --raw .#colmena.gnomeregan.config.services.tailscale.enable
```

Expected: output is `false` (or evaluation fails because the module has not been imported), proving the required client is absent.

- [ ] **Step 3: Add the existing SaaS module to gnomeregan's full configuration**

In the `"gnomeregan"` `imports` list in `colmena/hosts/gnomeregan.nix`, add this exact entry alongside the existing service modules:

```nix
../../modules/services/tailscale-saas.nix
```

Do not change `gnomeregan-init`; it is intentionally minimal and not the deployed full configuration.

- [ ] **Step 4: Re-run the evaluation assertion**

Run:

```bash
nix eval --impure --raw .#colmena.gnomeregan.config.services.tailscale.enable
```

Expected: output is `true`.

- [ ] **Step 5: Build the host without deploying**

Run:

```bash
colmena build --on gnomeregan --impure
```

Expected: exit status 0 and a completed gnomeregan build. Do not run `colmena apply` unless explicitly authorized.

- [ ] **Step 6: Commit the configuration and planning documents**

```bash
git add colmena/hosts/gnomeregan.nix \
  docs/superpowers/specs/2026-09-01-gnomeregan-tailscale-design.md \
  docs/superpowers/plans/2026-09-01-gnomeregan-tailscale.md
git commit -m "feat(gnomeregan): enable tailscale"
```

### Task 2: Enroll the deployed node interactively

**Files:**
- Modify: none
- Test: `tailscale status` on gnomeregan

**Interfaces:**
- Consumes: the deployed, enabled `tailscaled` service from Task 1.
- Produces: a persisted gnomeregan node registered in the existing Tailscale tailnet.

- [ ] **Step 1: Deploy only after explicit authorization**

Use the single-host Colmena deployment workflow for gnomeregan. Do not deploy the entire fleet.

- [ ] **Step 2: Authenticate locally on gnomeregan**

Run on gnomeregan:

```bash
sudo tailscale up
```

Open the URL printed by the command and sign in to the existing Tailscale tailnet.

- [ ] **Step 3: Confirm the node is connected**

Run on gnomeregan:

```bash
tailscale status
```

Expected: gnomeregan appears as the local connected node. No advertised routes or exit-node flags should be present.
