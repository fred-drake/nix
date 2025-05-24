# Nix Configuration Tasks

This file tracks active tasks, backlog, and milestones for the Nix configuration repository.

## Active Tasks

_No active tasks at the moment_

## High Priority Backlog

### Code Refactoring

- [ ] Extract NGINX/ACME boilerplate into `lib/mk-nginx-proxy.nix` helper function
  - Affects: prometheus, grafana, jellyseerr, gitea, uptime-kuma, prowlarr, n8n
  - Benefits: DRY principle, easier SSL management, consistent proxy configuration
- [ ] Create `lib/mk-container-service.nix` for standardized container management
  - Add health checks, restart policies, resource limits
  - Standardize container network configuration
- [ ] Extract common user configuration into shared module
  - Deduplicate `extraGroups` across all NixOS hosts
  - Centralize SSH key management

### Security Improvements

- [ ] Enable firewall on all hosts (currently disabled on some)
- [ ] Implement fail2ban for SSH and web services
- [ ] Add intrusion detection system (Suricata/Snort)
- [ ] Create centralized security policy module
- [ ] Implement automated secret rotation
- [ ] Add security scanning for containers
- [ ] Configure SELinux/AppArmor policies

### Monitoring & Observability

- [ ] Set up Loki for log aggregation
- [ ] Deploy Promtail on all hosts
- [ ] Add disk space monitoring and alerts
- [ ] Implement container health monitoring
- [ ] Create service dependency dashboard
- [ ] Add backup status monitoring
- [ ] Set up alerting for certificate expiration
- [ ] Monitor Nix store disk usage

### Infrastructure Hardening

- [ ] Centralize network configuration in soft-secrets
  - Remove hardcoded IPs from configuration files
  - Create network topology documentation
- [ ] Implement automated backup strategy
  - Configure restic/borg for critical data
  - Set up backup monitoring
  - Create restore procedures
  - Test backup restoration regularly
- [ ] Create disaster recovery runbook
- [ ] Implement service health checks and dependencies
  - Add systemd dependency ordering
  - Create startup health checks
  - Implement circuit breakers

## Medium Priority Backlog

### Development Experience

- [ ] Set up pre-commit hooks for Nix formatting (alejandra)
- [ ] Create CI/CD pipeline for configuration validation
- [ ] Add automated testing for Nix configurations
- [ ] Implement better error handling for Colmena deployments
- [ ] Create development environment documentation
- [ ] Add configuration drift detection

### Service Improvements

- [ ] Standardize service port allocation
- [ ] Create service mesh for better observability
- [ ] Implement blue-green deployments for critical services
- [ ] Add service auto-discovery
- [ ] Create unified ingress configuration

### Container Management

- [ ] Implement container image vulnerability scanning
- [ ] Add automatic container update notifications
- [ ] Create container resource usage dashboard
- [ ] Implement container network policies
- [ ] Add container backup strategies

## Low Priority Backlog

### Documentation

- [ ] Document each module's purpose and options
- [ ] Create architecture decision records (ADRs)
- [ ] Add troubleshooting guide
- [ ] Document secret management procedures
- [ ] Create network topology diagram

### Performance Optimization

- [ ] Optimize Nix evaluation time
- [ ] Implement build caching strategies
- [ ] Reduce container image sizes
- [ ] Optimize systemd service startup times

### Future Enhancements

- [ ] Implement GitOps workflow
- [ ] Add Kubernetes integration for container orchestration
- [ ] Create multi-region backup strategy
- [ ] Implement zero-downtime deployment strategies
- [ ] Add cost tracking for cloud resources

## Technical Debt

- [x] Fix Touch ID configuration in `darwin/default.nix` (currently commented out)
- [ ] Standardize nixpkgs channel usage across all hosts
- [ ] Clean up deprecated configurations
- [ ] Refactor legacy module structures
- [ ] Remove unused dependencies

## Completed Tasks

### Infrastructure

- [x] Set up Prometheus monitoring
- [x] Configure Grafana dashboards
- [x] Implement backup solutions (partial - needs improvement)

### Development Environment

- [x] Standardize development shells
- [x] Configure language servers
- [x] Create CLAUDE.md for AI assistance

### Documentation

- [x] Document Nix configuration structure
- [x] Add setup instructions for new developers
- [x] Document common workflows

## Notes

Tasks are prioritized based on:
1. **Security impact** - Vulnerabilities and security improvements
2. **Reliability impact** - Monitoring, backups, and stability
3. **Developer experience** - Reducing friction and improving productivity
4. **Technical debt** - Long-term maintainability

Each completed task should be tested on a non-critical system before rolling out to production.