---
name: woodpecker-cli
description: Reference for the Woodpecker CI command-line tool. Use when working with Woodpecker CI pipelines, managing repositories, secrets, registries, organizations, or users via the CLI. Covers pipeline operations (start, stop, approve, logs), repository management, secret/registry configuration, and local pipeline execution.
---

# Woodpecker CLI Reference

## Global Options

All commands support these flags:

| Flag | Description |
|------|-------------|
| `--server, -s` | Server address |
| `--token, -t` | Authentication token |
| `--config, -c` | Path to config file |
| `--log-level` | Logging verbosity (default: info) |
| `--skip-verify` | Skip SSL verification |
| `--nocolor` | Disable colored output |

## Pipeline Commands

### List Pipelines
```bash
woodpecker-cli pipeline ls <owner/repo>
```

### Start Pipeline
```bash
woodpecker-cli pipeline start <owner/repo> [pipeline-number]
# With parameters:
woodpecker-cli pipeline start <owner/repo> --param KEY=VALUE
```

### Stop Pipeline
```bash
woodpecker-cli pipeline stop <owner/repo> <pipeline-number>
```

### Show Pipeline Details
```bash
woodpecker-cli pipeline show <owner/repo> <pipeline-number>
```

### View Logs
```bash
woodpecker-cli pipeline log show <owner/repo> <pipeline-number> [step-number]
```

### Approve/Decline Pipeline
```bash
woodpecker-cli pipeline approve <owner/repo> <pipeline-number>
woodpecker-cli pipeline decline <owner/repo> <pipeline-number>
```

### Last Pipeline
```bash
woodpecker-cli pipeline last <owner/repo>
# For specific branch:
woodpecker-cli pipeline last <owner/repo> --branch <branch-name>
```

### Create Pipeline
```bash
woodpecker-cli pipeline create <owner/repo> --branch <branch>
```

### Deploy
```bash
woodpecker-cli pipeline deploy <owner/repo> <pipeline-number> <environment>
```

## Repository Commands

### Add/Remove Repository
```bash
woodpecker-cli repo add <owner/repo>
woodpecker-cli repo rm <owner/repo>
```

### Sync Repositories
```bash
woodpecker-cli repo sync
```

### Update Repository Settings
```bash
woodpecker-cli repo update <owner/repo> --trusted
woodpecker-cli repo update <owner/repo> --visibility <public|private|internal>
```

### Repair Repository Webhook
```bash
woodpecker-cli repo repair <owner/repo>
```

## Secret Management

### Repository Secrets
```bash
# List secrets
woodpecker-cli secret ls <owner/repo>

# Add secret
woodpecker-cli secret add <owner/repo> \
  --name <secret-name> \
  --value <secret-value> \
  --event push,pull_request

# Show secret
woodpecker-cli secret show <owner/repo> <secret-name>

# Update secret
woodpecker-cli secret update <owner/repo> \
  --name <secret-name> \
  --value <new-value>

# Remove secret
woodpecker-cli secret rm <owner/repo> <secret-name>
```

### Organization Secrets
```bash
woodpecker-cli org secret ls <org>
woodpecker-cli org secret add <org> --name <name> --value <value>
woodpecker-cli org secret rm <org> <secret-name>
```

### Global Secrets (Admin)
```bash
woodpecker-cli admin secret ls
woodpecker-cli admin secret add --name <name> --value <value>
woodpecker-cli admin secret rm <secret-name>
```

## Registry Management

### Repository Registries
```bash
# List registries
woodpecker-cli registry ls <owner/repo>

# Add registry
woodpecker-cli registry add <owner/repo> \
  --hostname <registry-host> \
  --username <user> \
  --password <pass>

# Remove registry
woodpecker-cli registry rm <owner/repo> <hostname>
```

### Organization/Global Registries
```bash
# Org registries
woodpecker-cli org registry ls <org>
woodpecker-cli org registry add <org> --hostname <host> --username <user> --password <pass>

# Global registries (admin)
woodpecker-cli admin registry ls
woodpecker-cli admin registry add --hostname <host> --username <user> --password <pass>
```

## Cron Jobs

```bash
# List cron jobs
woodpecker-cli cron ls <owner/repo>

# Add cron job
woodpecker-cli cron add <owner/repo> \
  --name <job-name> \
  --schedule "0 0 * * *" \
  --branch <branch>

# Show cron job
woodpecker-cli cron show <owner/repo> <cron-id>

# Update cron job
woodpecker-cli cron update <owner/repo> <cron-id> --schedule "0 12 * * *"

# Remove cron job
woodpecker-cli cron rm <owner/repo> <cron-id>
```

## Local Execution

Execute pipelines locally for testing:

```bash
# Basic local execution
woodpecker-cli exec .woodpecker.yaml

# With specific backend
woodpecker-cli exec --backend docker .woodpecker.yaml
woodpecker-cli exec --backend local .woodpecker.yaml

# With environment variables
woodpecker-cli exec --env KEY=VALUE .woodpecker.yaml

# With specific pipeline metadata
woodpecker-cli exec \
  --commit-sha <sha> \
  --commit-branch <branch> \
  --commit-message "test" \
  .woodpecker.yaml
```

## User Management (Admin)

```bash
# List users
woodpecker-cli admin user ls

# Add user
woodpecker-cli admin user add <username>

# Show user
woodpecker-cli admin user show <username>

# Remove user
woodpecker-cli admin user rm <username>
```

## Organization Management (Admin)

```bash
woodpecker-cli admin org ls
```

## Utility Commands

### User Info
```bash
woodpecker-cli info
```

### Lint Pipeline Config
```bash
woodpecker-cli lint .woodpecker.yaml
woodpecker-cli lint --strict .woodpecker.yaml
```

### Setup CLI
```bash
woodpecker-cli setup
```

### Update CLI
```bash
woodpecker-cli update
```

### Server Log Level (Admin)
```bash
woodpecker-cli admin log-level
woodpecker-cli admin log-level --set debug
```

## Common Patterns

### Watch Pipeline Progress
```bash
# Get last pipeline and watch its logs
woodpecker-cli pipeline last <owner/repo> --output json | jq '.number'
woodpecker-cli pipeline log show <owner/repo> <number>
```

### Trigger Pipeline with Parameters
```bash
woodpecker-cli pipeline create <owner/repo> \
  --branch main \
  --param DEPLOY_ENV=staging \
  --param VERSION=1.2.3
```

### Output Formatting
```bash
# JSON output
woodpecker-cli pipeline ls <owner/repo> --output json

# Custom format
woodpecker-cli pipeline ls <owner/repo> --format "{{.Number}} {{.Status}}"
```
