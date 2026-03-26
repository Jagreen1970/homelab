# Task 03 — Initial configuration

## Status: TODO
## Priority: HIGH
## Prereqs: task-02

## Summary
Complete the Nexus first-run setup: change admin password, disable anonymous access,
and enable the Docker Bearer Token realm required for Docker push/pull authentication.

## Steps

### 1. Get the initial admin password
```bash
docker exec nexus cat /nexus-data/admin.password
```
Copy the output — it is a random UUID-format string.

### 2. Log in
- Open `http://zaphod-ip:18081`
- Username: `admin`, Password: output from step 1

### 3. Complete setup wizard
The wizard appears on first login:
1. **Change admin password** — choose a strong password, save it in your password manager
2. **Anonymous access** — select **Disable anonymous access** (recommended)
3. Finish wizard

### 4. Enable Docker Bearer Token Realm
This realm is required for `docker login` / `docker push` / `docker pull` to work:
- Administration → Security → Realms
- Move **Docker Bearer Token Realm** from Available to Active
- Click **Save**

### 5. Verify
- Log out and log back in with the new admin password
- Administration → Security → Realms: confirm Docker Bearer Token Realm is in Active list

## Notes
- Without the Docker Bearer Token Realm, Docker clients will get 401 errors even with
  correct credentials
- Anonymous access can be re-enabled per-repository if needed (task-04 covers this
  option for Docker repos)

## Acceptance criteria
- [ ] Admin password changed and stored in password manager
- [ ] Anonymous access disabled
- [ ] Docker Bearer Token Realm active
- [ ] Login with new password works
