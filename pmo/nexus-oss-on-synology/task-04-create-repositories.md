# Task 04 — Create repositories

## Status: DONE
## Priority: HIGH
## Prereqs: task-03

## Summary
Create all required Nexus repositories: Docker Hub pull-through proxy, local Docker
hosted repo, Helm hosted repo, generic raw repo, and optionally a Go module proxy.

## Navigation
Administration → Repository → Repositories → **Create repository**

## Repositories to create

### 1. `docker-hub-proxy` (Docker pull-through cache)
- Recipe: **docker (proxy)**
- HTTP connector port: **18082**
- HTTPS connector: leave blank (HAProxy handles TLS termination)
- Remote storage URL: `https://registry-1.docker.io`
- Docker Index: **Use Docker Hub**
- Allow anonymous docker pull: enable if you want unauthenticated pulls (optional)
- Blob store: default

### 2. `docker-lab` (local image storage)
- Recipe: **docker (hosted)**
- HTTP connector port: **18083**
- HTTPS connector: leave blank
- Deployment policy: Allow redeploy (useful for `latest` tag overwrites in development)
- Allow anonymous docker pull: your choice
- Blob store: default

### 3. `helm-lab` (Helm chart repository)
- Recipe: **helm (hosted)**
- Deployment policy: Allow redeploy
- Blob store: default

### 4. `generic-lab` (raw/generic artifacts)
- Recipe: **raw (hosted)**
- Deployment policy: Allow redeploy
- Blob store: default

### 5. `go-proxy` (Go module proxy) — OPTIONAL
- Recipe: **go (proxy)**
- Remote storage URL: `https://goproxy.io`
- Blob store: default

## Verify each repository
After creating each repo:
- Administration → Repository → Repositories → click repo name → **Browse**
- It should show an empty (or healthy) repo view

## Notes
- Docker repos MUST have their HTTP port set at creation time; it cannot be changed
  after saving without deleting and recreating the repo
- Port 18082 and 18083 must match what is exposed in the Docker Compose file (task-02)
- HAProxy in task-05 will terminate HTTPS externally; Nexus itself serves plain HTTP on
  these ports — this is intentional

## Acceptance criteria
- [ ] `docker-hub-proxy` created, port 18082
- [ ] `docker-lab` created, port 18083
- [ ] `helm-lab` created
- [ ] `generic-lab` created
- [ ] `go-proxy` created (optional)
- [ ] All repos browsable in Nexus UI
