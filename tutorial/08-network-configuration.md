# Step 8: Network Configuration — Ingress Access and Internet Exposure

This tutorial covers how to make Kubernetes ingresses reachable by their `*.lab` FQDNs on your
LAN, and how to selectively expose services to the internet using OPNsense and Nginx Proxy Manager
(NPM) running on your Synology NAS.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [How MetalLB L2 Works with a Separate Subnet](#how-metallb-l2-works-with-a-separate-subnet)
3. [Prerequisites](#prerequisites)
4. [Step 1: Find the ingress-nginx LoadBalancer IP](#step-1-find-the-ingress-nginx-loadbalancer-ip)
5. [Step 2: OPNsense — Static Route for 10.1.1.0/24](#step-2-opnsense--static-route-for-1011024)
6. [Step 3: OPNsense Unbound — DNS for K8s Services](#step-3-opnsense-unbound--dns-for-k8s-services)
7. [Step 4: Internet Exposure — OPNsense Port Forwarding](#step-4-internet-exposure--opnsense-port-forwarding)
8. [Step 5: NPM — Add Proxy Hosts for Internet-Exposed Services](#step-5-npm--add-proxy-hosts-for-internet-exposed-services)
9. [Step 6: Public DNS](#step-6-public-dns)
10. [Step 7: Kubernetes Ingress — Add Public Hostname Rules](#step-7-kubernetes-ingress--add-public-hostname-rules)
11. [Verification](#verification)
12. [Troubleshooting](#troubleshooting) — full walkthrough of a real debugging session
    - [Trap 1: The Ping That Can Never Work](#trap-1-the-ping-that-can-never-work)
    - [Trap 2: The Wildcard That Kills Unbound](#trap-2-the-wildcard-that-kills-unbound)
    - [Trap 3: DNS Works, But the Browser Doesn't](#trap-3-dns-works-but-the-browser-doesnt)
13. [Full Diagnostic Checklist](#full-diagnostic-checklist)
14. [Next Steps](#next-steps)

---

## Architecture Overview

```
Internet
    │  (OPNsense forwards WAN:80/443 → zaphod:80/443)
    ▼
Nginx Proxy Manager on zaphod (192.168.1.207)
    │  Internet-exposed services only
    │  proxy_pass → 10.1.1.10 with correct Host: header
    ▼
ingress-nginx (MetalLB IP: 10.1.1.10)  ← routes ALL cluster services
    │  Routes by Host: header
    ▼
Kubernetes Service → Pod

LAN clients
    │  DNS: longhorn.lab → 10.1.1.10  (OPNsense Unbound host override)
    └──────────────────────────────────────────────────▶ ingress-nginx (direct)
```

**Key design decisions:**

- **Internal `*.lab` traffic never touches NPM.** LAN clients resolve service names (e.g.
  `longhorn.lab`) to the ingress-nginx MetalLB IP via Unbound host overrides and connect
  directly without going through zaphod.
- **NPM is the internet entry point only.** It acts as a selective reverse proxy for services
  you choose to expose publicly.
- **ingress-nginx is the single routing layer** for all cluster services, internal or external.
  NPM simply forwards with the correct `Host:` header; ingress-nginx does the actual routing.
- **`.lab` is a private TLD.** It will never resolve from the internet. Internet-exposed
  services must use a real public domain name.

---

## How MetalLB L2 Works with a Separate Subnet

MetalLB in L2 mode works by having one cluster node "claim" each LoadBalancer IP by responding
to ARP requests for it on the node's primary network interface. When a node claims `10.1.1.10`,
the MetalLB speaker:

1. Responds to ARP broadcasts for `10.1.1.10` on the node's NIC (e.g. `eth0` on `192.168.1.166`)
2. Adds a local route for `10.1.1.10` on that node
3. kube-proxy DNATs incoming packets to the correct pod

Our cluster nodes are on `192.168.1.0/24` but the MetalLB pool is `10.1.1.0/24`. These are
different subnets, so LAN clients can't reach `10.1.1.x` by default — their ARP queries would
never be answered.

**The fix:** Add a static route in OPNsense telling it to forward `10.1.1.0/24` traffic to
a cluster node IP (e.g. `192.168.1.166`). OPNsense will unicast the packet to that node, the
MetalLB-installed local route accepts it, and kube-proxy routes it to the right pod. This
works because OPNsense is on the same L2 segment as the nodes and can use normal IP routing.

Benefits of keeping MetalLB on a separate subnet:
- Clean separation between LAN devices and cluster virtual IPs
- Easy to identify cluster services in routing tables and firewall logs
- Room to expand the pool without conflicting with DHCP leases

---

## Prerequisites

Before configuring networking, ensure:

1. Kubernetes cluster is running (`kubectl get nodes` → all Ready)
2. MetalLB is deployed and the `10.1.1.0/24` pool is configured
   (`kubectl get ipaddresspool -n metallb-system`)
3. ingress-nginx is deployed as a `LoadBalancer` service
   (`kubectl get svc -n ingress-nginx`)
4. You have admin access to OPNsense
5. NPM is running on zaphod (`http://192.168.1.207:81` or your configured port)

---

## Step 1: Find the ingress-nginx LoadBalancer IP

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Expected output:
```
NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
ingress-nginx-controller   LoadBalancer   10.96.x.x      10.1.1.10     80:31xxx/TCP,443:32xxx/TCP
```

The `EXTERNAL-IP` column shows the MetalLB-assigned IP. Note this down — it is
`<INGRESS_IP>` throughout this tutorial (e.g. `10.1.1.10`).

> **If EXTERNAL-IP shows `<pending>`:** MetalLB has not assigned an IP yet. Check
> `kubectl describe svc -n ingress-nginx ingress-nginx-controller` for events, and verify
> the MetalLB pool is applied: `kubectl get ipaddresspool,l2advertisement -n metallb-system`.

---

## Step 2: OPNsense — Static Route for 10.1.1.0/24

LAN clients route all traffic through OPNsense. You need to tell OPNsense how to reach the
`10.1.1.0/24` MetalLB subnet by forwarding it to a cluster node.

**In OPNsense:**

1. Go to **System → Routes → Configuration**
2. Click **➕ Add**
3. Fill in:
   - **Destination network**: `10.1.1.0/24`
   - **Gateway**: `192.168.1.166` _(disasterarea — the most likely MetalLB speaker node)_
   - **Description**: `K8s MetalLB pool`
4. Click **Save**, then **Apply changes**

> **Note on gateway:** MetalLB can migrate an IP to a different node if a node fails (within
> a few seconds). In practice for a homelab, using the control plane node as the gateway is
> stable. If you need true HA routing, look into adding all node IPs as ECMP gateways or
> using BGP mode instead of L2.

**Verify the route is working** from a LAN client:
```bash
# Do NOT use ping — it won't work (see Troubleshooting section for why)
curl -s -o /dev/null -w "HTTP %{http_code}" http://10.1.1.10/
# Expected: HTTP 404 (means the network path works — 404 is ingress-nginx's default response)
```

---

## Step 3: OPNsense Unbound — DNS for K8s Services

OPNsense uses Unbound as its DNS resolver. Add host overrides so LAN clients can reach
K8s services by name (e.g. `longhorn.lab`) instead of by IP.

> **Warning — do NOT use a wildcard (`*`) host override** if you already have individual
> host overrides in the same domain (e.g. `disasterarea.lab`, `arthur.lab`). OPNsense
> implements wildcards as Unbound `redirect` zones, which are incompatible with individual
> records in the same zone. Adding a wildcard will break Unbound with:
> ```
> error: local-data in redirect zone must reside at top of zone
> fatal error: Could not set up local zones
> ```
> Use individual host overrides instead (one per service).

**In OPNsense:**

1. Go to **Services → Unbound DNS → Host Overrides**
2. For each K8s service that has an Ingress resource, click **➕ Add**:
   - **Host**: the service name (e.g. `longhorn`)
   - **Domain**: `lab`
   - **Type**: `A`
   - **IP**: `<INGRESS_IP>` (e.g. `10.1.1.10`)
   - **Description**: `K8s <service-name>`
3. Click **Save** after each entry
4. Click **Apply changes** when done

**Example entries** (all pointing to the same ingress-nginx MetalLB IP):

| Host | Domain | IP | Description |
|------|--------|----|-------------|
| `longhorn` | `lab` | `10.1.1.10` | K8s Longhorn UI |
| `grafana` | `lab` | `10.1.1.10` | K8s Grafana |
| `argocd` | `lab` | `10.1.1.10` | K8s ArgoCD |

Add a new entry each time you create a new Ingress resource. They all point to the same
`<INGRESS_IP>` — ingress-nginx uses the `Host:` header to route to the correct service.

**How it works:** A LAN client resolves `longhorn.lab` → `10.1.1.10`. The HTTP request
arrives at ingress-nginx with `Host: longhorn.lab`. ingress-nginx matches this to the
Longhorn Ingress resource and routes to the Longhorn pod.

**Verify DNS resolution** from any LAN client:
```bash
dig longhorn.lab @192.168.1.1    # replace 192.168.1.1 with your OPNsense IP
# Should return 10.1.1.10 (or your INGRESS_IP)

# Node entries should still resolve correctly:
dig disasterarea.lab @192.168.1.1
# Should return 192.168.1.166
```

---

## Step 4: Internet Exposure — OPNsense Port Forwarding

To expose services to the internet, route incoming WAN traffic to NPM on zaphod.
NPM will then selectively forward to the cluster.

> **Note:** Only services you explicitly add to NPM will be accessible from the internet.
> All other `*.lab` services remain LAN-only.

**In OPNsense — add two NAT port forward rules** (one for HTTP, one for HTTPS):

1. Go to **Firewall → NAT → Port Forward**
2. Click **➕ Add** for **HTTP (port 80)**:
   - **Interface**: WAN
   - **Protocol**: TCP
   - **Destination**: WAN address
   - **Destination port range**: `HTTP` (80)
   - **Redirect target IP**: `192.168.1.207` (zaphod)
   - **Redirect target port**: `HTTP` (80)
   - **Description**: `WAN HTTP → NPM`
3. Click **Save**

4. Click **➕ Add** for **HTTPS (port 443)**:
   - Same as above but **Destination port range**: `HTTPS` (443)
   - **Redirect target port**: `HTTPS` (443)
   - **Description**: `WAN HTTPS → NPM`
5. Click **Save**, then **Apply changes**

> **Firewall rule:** OPNsense usually creates the matching pass rule automatically when
> you add a port forward. Verify under **Firewall → Rules → WAN** that rules for ports
> 80 and 443 exist. If not, add them manually.

---

## Step 5: NPM — Add Proxy Hosts for Internet-Exposed Services

For each service you want to expose to the internet, add a proxy host in NPM.

**In NPM (http://192.168.1.207:81 or your port):**

1. Go to **Proxy Hosts → Add Proxy Host**
2. **Details tab:**
   - **Domain Names**: `myservice.yourdomain.com`
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `<INGRESS_IP>` (e.g. `10.1.1.10`)
   - **Forward Port**: `80`
   - **Block Common Exploits**: ✅ (recommended)
3. **Advanced tab** — paste this in the custom Nginx configuration box:
   ```nginx
   proxy_set_header Host myservice.yourdomain.com;
   ```
   This is **critical**: ingress-nginx uses the `Host:` header to route to the right service.
   Without it, NPM would forward the original host header which may not match any ingress rule.
4. **SSL tab** (recommended):
   - **SSL Certificate**: Request a Let's Encrypt certificate
   - **Force SSL**: ✅
   - **HTTP/2 Support**: ✅
5. Click **Save**

Repeat for each additional service you want to expose.

> **Split-horizon note:** You do not need to add `myservice.yourdomain.com` to OPNsense
> Unbound. LAN clients use `myservice.lab` to reach the service directly. The public domain
> is only used from the internet.

---

## Step 6: Public DNS

For each internet-exposed service, add a DNS record at your domain registrar or DNS provider:

```
myservice.yourdomain.com  →  A  →  <YOUR WAN IP>
```

If your ISP assigns a dynamic WAN IP, use a **Dynamic DNS (DDNS)** service:

- OPNsense has built-in DDNS support under **Services → Dynamic DNS**
- Popular providers: Cloudflare (free), DuckDNS (free), No-IP
- Cloudflare is recommended: it also provides DDoS protection and can proxy your traffic,
  hiding your WAN IP

**With Cloudflare DDNS in OPNsense:**
1. Services → Dynamic DNS → Add
2. Service: `Cloudflare`
3. Username: your Cloudflare email
4. Password: your Cloudflare API token (Zone:DNS:Edit permission)
5. Hostname: `myservice.yourdomain.com`

---

## Step 7: Kubernetes Ingress — Add Public Hostname Rules

For a service that should be reachable both internally (`myservice.lab`) and from the internet
(`myservice.yourdomain.com`), add both hostnames to the ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myservice
  namespace: myservice-namespace
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: myservice.lab             # LAN access via OPNsense Unbound
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myservice
                port:
                  number: 80
    - host: myservice.yourdomain.com  # Internet access via NPM
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myservice
                port:
                  number: 80
```

Both rules point to the same backend service. ingress-nginx will route the request correctly
regardless of whether it came from a LAN client or through NPM.

---

## Verification

### 1. DNS resolves correctly on LAN
```bash
dig longhorn.lab             # should return <INGRESS_IP>
dig argocd.home              # should return <INGRESS_IP>
```

### 2. Service is reachable on LAN
```bash
curl -H "Host: longhorn.lab" http://<INGRESS_IP>/
# Or just: curl http://longhorn.lab  (if your machine uses OPNsense DNS)
```

### 3. ingress-nginx is handling requests
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=20
# Look for lines showing the Host: header being routed
```

### 4. Internet-exposed service is reachable externally
```bash
# From outside your network (e.g. phone on mobile data):
curl -I https://myservice.yourdomain.com
# Should return HTTP 200 (or redirect to login)
```

### 5. NPM is proxying correctly
```bash
# Check NPM logs in its web UI, or from zaphod:
docker logs nginx-proxy-manager 2>&1 | tail -20
```

---

## Troubleshooting

> **Important: Do NOT use `ping` to test MetalLB connectivity.** Ping (ICMP) will always
> fail with MetalLB VIPs on a separate subnet — this is expected, not a bug. Read the
> walkthrough below to understand why, and always use `curl` instead.

This section is written as a narrative walkthrough of an actual troubleshooting session on
this cluster. It follows the exact path we took — including the wrong turns — so you can
learn the reasoning behind each step. If you just need a quick checklist, skip to
[Full Diagnostic Checklist](#full-diagnostic-checklist) at the end.

---

### The Symptom: "10.1.1.0/24 is not reachable"

After deploying MetalLB with the `10.1.1.10–10.1.1.250` pool and setting up the OPNsense
static route, we tried the obvious test:

```bash
ping 10.1.1.10
```

And got this:

```
PING 10.1.1.10 (10.1.1.10): 56 data bytes
Request timeout for icmp_seq 0
92 bytes from disasterarea.lab (192.168.1.166): Redirect Host(New addr: 192.168.1.1)
Request timeout for icmp_seq 1
92 bytes from disasterarea.lab (192.168.1.166): Redirect Host(New addr: 192.168.1.1)
```

Timeouts plus mysterious "Redirect Host" messages from disasterarea. The natural conclusion:
"the route is broken." **This conclusion was wrong.** Here's the full story of how we figured
that out and what was actually going on.

---

### Trap 1: The Ping That Can Never Work

This is the single most common mistake when debugging MetalLB on a separate subnet — and
it's easy to fall into repeatedly (we've done it more than once).

**Why ping fails — the full explanation:**

When you `ping 10.1.1.10` from a LAN client (e.g. your Mac at `192.168.1.208`), the packet
takes this path:

```
            Your Mac                    OPNsense                  disasterarea
          192.168.1.208              192.168.1.1                192.168.1.166
                │                        │                           │
  ping 10.1.1.10                         │                           │
  ──────────────►  static route:         │                           │
                   10.1.1.0/24           │                           │
                   via .166              │                           │
                   ──────────────────────►  ICMP packet arrives      │
                                            dst = 10.1.1.10         │
                                            │                        │
                                            │  kube-proxy checks     │
                                            │  iptables PREROUTING:  │
                                            │  "Is this TCP/UDP?"    │
                                            │  → NO (it's ICMP)      │
                                            │  → no DNAT rule fires  │
                                            │                        │
                                            │  kernel routing:       │
                                            │  "10.1.1.10? Not mine. │
                                            │   Default route is     │
                                            │   via 192.168.1.1"     │
                                            │                        │
                                            │  ICMP Redirect ◄───────│
                                            │  "Use 192.168.1.1      │
                                            │   instead of me"       │
```

Here's the crucial insight: **kube-proxy only creates iptables DNAT rules for TCP and UDP
traffic.** It has no rules for ICMP. When an ICMP ping packet arrives at the cluster node:

1. The `iptables PREROUTING` chain runs, but no rule matches (wrong protocol)
2. The kernel falls through to normal routing
3. The node has no local address `10.1.1.10` on any interface — it's a MetalLB virtual IP,
   not a real interface address
4. The kernel tries to forward the packet via the default route (`192.168.1.1`)
5. The kernel notices the source (your Mac, via OPNsense on `192.168.1.1`) and the next hop
   (`192.168.1.1`) are on the same network segment
6. It sends an **ICMP Redirect** — a message that says "don't send this through me, send it
   directly to `192.168.1.1`"

This creates a routing loop: OPNsense sends to disasterarea, disasterarea says go to
OPNsense, OPNsense sends to disasterarea again... The ping times out.

**For HTTP/HTTPS (TCP), the flow is completely different:**

```
  curl http://10.1.1.10    OPNsense          disasterarea           Pod
                │               │                  │                  │
  TCP SYN ──────►  route to     │                  │                  │
  dst=10.1.1.10    .166        ─►  iptables        │                  │
                                   PREROUTING:     │                  │
                                   "TCP dport 80   │                  │
                                    to 10.1.1.10?  │                  │
                                    YES → DNAT to  │                  │
                                    10.244.3.7:80" ─►  Pod receives   │
                                                       request        │
                                   ◄────────────────  HTTP response   │
                ◄────────────────                                     │
  HTTP 200!
```

kube-proxy's iptables DNAT rule fires **before** the routing decision. The destination is
rewritten from `10.1.1.10` to the pod IP (`10.244.3.7` on the Flannel overlay), and the
packet is forwarded normally through the cluster network. No ICMP Redirect, no routing loop.

**The lesson: always test MetalLB with `curl`, never with `ping`.**

```bash
# The CORRECT way to test MetalLB connectivity:
curl -s -o /dev/null -w "HTTP %{http_code}" http://10.1.1.10/
# HTTP 404 = network works! (404 is ingress-nginx saying "no Host header matched")

# Test a specific service:
curl -s -o /dev/null -w "HTTP %{http_code}" -H "Host: longhorn.lab" http://10.1.1.10/
# HTTP 200 = service is reachable!
```

---

### Step 1: Verify the K8s Side (Is MetalLB Actually Working?)

Once we stopped relying on ping and switched to systematic diagnostics, we checked the
Kubernetes layer first — because if MetalLB hasn't assigned an IP, nothing else matters.

**Check 1a: Are MetalLB pods running?**

```bash
kubectl get pods -n metallb-system -o wide
```
```
NAME                          READY   STATUS    RESTARTS   AGE   IP              NODE
controller-7499d4584d-w5gsd   1/1     Running   0          12h   10.244.2.125    ford
speaker-5hhpg                 1/1     Running   3          13h   192.168.1.24    arthur
speaker-jxm4q                 1/1     Running   3          13h   192.168.1.76    ford
speaker-m2gkt                 1/1     Running   0          13h   192.168.1.166   disasterarea
speaker-nvhcr                 1/1     Running   3          13h   192.168.1.67    trillian
```

**Why we checked this:** MetalLB has two components — the *controller* (assigns IPs to
services) and *speakers* (one per node, advertise IPs via ARP). If either is down, no IPs
get assigned or advertised. Here, all are Running.

**Check 1b: Is the IP pool configured?**

```bash
kubectl get ipaddresspool,l2advertisement -n metallb-system
```
```
NAME                                  AUTO ASSIGN   ADDRESSES
ipaddresspool.metallb.io/first-pool   true          ["10.1.1.10-10.1.1.250"]

NAME                                   IPADDRESSPOOLS
l2advertisement.metallb.io/l2-advert   ["first-pool"]
```

**Why we checked this:** MetalLB won't assign IPs without a configured pool, and won't
advertise them without an L2Advertisement (or BGPAdvertisement). Both are present.

**Check 1c: Does ingress-nginx have a MetalLB IP?**

```bash
kubectl get svc -n ingress-nginx
```
```
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)
ingress-nginx-controller             LoadBalancer   10.101.127.191   10.1.1.10     80:31140/TCP,443:31417/TCP
```

**Why we checked this:** The service must be type `LoadBalancer` (not `ClusterIP` or
`NodePort`) and the `EXTERNAL-IP` must show an actual IP (not `<pending>`). Here, MetalLB
has assigned `10.1.1.10`. If it showed `<pending>`, we'd check
`kubectl describe svc ingress-nginx-controller -n ingress-nginx` for events.

**Check 1d: Which node is the L2 speaker for this IP?**

```bash
# Check each speaker's logs for the "serviceAnnounced" event:
for pod in $(kubectl get pods -n metallb-system -l component=speaker -o name); do
  node=$(kubectl get -n metallb-system $pod -o jsonpath='{.spec.nodeName}')
  announced=$(kubectl logs -n metallb-system $pod 2>/dev/null \
    | grep "serviceAnnounced" | tail -1)
  if [ -n "$announced" ]; then
    echo ">>> $node is ANNOUNCING the VIP"
  else
    echo "    $node is standby"
  fi
done
```
```
    disasterarea is standby
    arthur is standby
    ford is standby
>>> trillian is ANNOUNCING the VIP
```

**Why we checked this:** MetalLB L2 mode elects ONE node to announce each VIP via ARP.
We found that **trillian** (192.168.1.67) was elected — not disasterarea (192.168.1.166)
which is the OPNsense static route target.

**Does this matter?** No! Because `externalTrafficPolicy: Cluster` is set on the service,
kube-proxy on **every** node has iptables DNAT rules for `10.1.1.10`. It doesn't matter
which node receives the TCP packet — any of them will DNAT it to the correct pod. The
static route can point to any node.

**Conclusion: The entire K8s side was healthy.** MetalLB running, IP assigned, speaker
announcing. The problem was elsewhere.

---

### Step 2: Test TCP Connectivity (The Moment of Truth)

With K8s confirmed healthy, we ran the actual test:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}" http://10.1.1.10/
```
```
HTTP 404
```

**HTTP 404!** This means the network path is working:
- The TCP packet left our Mac
- OPNsense routed it to disasterarea (via the static route)
- kube-proxy on disasterarea DNAT'd it to the ingress-nginx pod
- ingress-nginx responded with 404 (because we didn't send a `Host:` header)

```bash
curl -s -o /dev/null -w "HTTP %{http_code}" -H "Host: longhorn.lab" http://10.1.1.10/
```
```
HTTP 200
```

**HTTP 200!** The Longhorn UI is fully reachable via the MetalLB IP. The "unreachable subnet"
was reachable all along — we were just testing with the wrong tool (ping).

---

### Step 3: DNS Resolution (The Second Problem)

TCP works by IP, but we also need DNS so that browsers and `curl http://longhorn.lab` work:

```bash
dig +short longhorn.lab @192.168.1.1
# (empty — no result)
```

**Why this failed:** OPNsense Unbound had no host override for `longhorn.lab`. We needed to
add one pointing to `10.1.1.10`.

---

### Trap 2: The Wildcard That Kills Unbound

The intuitive approach is to add a wildcard — `*.lab → 10.1.1.10` — so every new service
automatically resolves. We tried this because the cluster nodes (`disasterarea.lab`,
`arthur.lab`, etc.) already had individual host overrides, and in standard DNS, specific
records take priority over wildcards.

**What happened:** Unbound crashed immediately:

```
error: local-data in redirect zone must reside at top of zone,
       not at arthur.lab IN A 192.168.1.24
fatal error: Could not set up local zones
```

**Why it broke:** OPNsense doesn't implement wildcards as standard DNS wildcards. Instead, it
creates an Unbound `redirect` zone for the domain. Redirect zones require ALL records to live
at the zone apex — you cannot have both `*.lab` (redirect zone) and `arthur.lab` (individual
record) in the same domain. They're fundamentally incompatible in Unbound's zone model.

**The fix:** Remove the wildcard immediately (`Services → Unbound DNS → Host Overrides →
delete the `*` entry → Apply changes`). Then add **individual** host overrides for each K8s
service:

| Host | Domain | IP | Description |
|------|--------|----|-------------|
| `longhorn` | `lab` | `10.1.1.10` | K8s Longhorn UI |
| `grafana` | `lab` | `10.1.1.10` | K8s Grafana (add when deployed) |
| `argocd` | `lab` | `10.1.1.10` | K8s ArgoCD (add when deployed) |

This coexists perfectly with the node entries (`disasterarea.lab → 192.168.1.166`, etc.).

**The trade-off:** You must add a new Unbound host override every time you create a new K8s
Ingress resource. For a homelab with a handful of services, this is fine.

After adding the `longhorn.lab` override, DNS resolved correctly:

```bash
dig +short longhorn.lab @192.168.1.1
# 10.1.1.10

dig +short disasterarea.lab @192.168.1.1
# 192.168.1.166 (node entries unaffected)
```

---

### Trap 3: DNS Works, But the Browser Doesn't

At this point, `curl http://longhorn.lab` returned HTTP 200 — but typing `longhorn.lab` in
the browser still didn't work. This had two causes:

**Cause A: macOS DNS cache**

macOS aggressively caches DNS results — including *negative* results (NXDOMAIN). When we
tried `longhorn.lab` earlier (before adding the Unbound override), macOS cached the "does not
exist" response. Even after Unbound was configured correctly, the Mac kept using its stale
cache.

**Fix:**
```bash
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
```

This clears the macOS DNS cache and restarts the mDNS responder. After flushing, the system
will query OPNsense again and get the correct answer.

**Cause B: Browser address bar interpretation**

Some browsers (especially Chrome) treat non-standard TLDs like `.lab` as search queries
rather than URLs. If you type just `longhorn.lab` in the address bar, Chrome may Google it
instead of navigating to it.

**Fix:** Always type the full URL with protocol:
```
http://longhorn.lab
```

---

### Summary: Three Traps and How to Avoid Them

| Trap | What happened | How to avoid |
|------|--------------|--------------|
| **Ping test** | `ping 10.1.1.10` fails with ICMP Redirect — kube-proxy only handles TCP/UDP, not ICMP | Always test MetalLB with `curl`, never `ping` |
| **Wildcard DNS** | `*.lab` override crashes Unbound when node entries exist in the same domain | Use individual host overrides per service, not wildcards |
| **Stale DNS cache** | macOS caches negative DNS results; browser sees "not found" even after Unbound is fixed | Run `sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder` and use `http://` prefix |

---

### Reference: Quick Fixes for Common Errors

#### `curl http://10.1.1.10/` → connection refused or timeout

TCP traffic is not reaching ingress-nginx. Walk through these checks in order:

1. **MetalLB pods running?** `kubectl get pods -n metallb-system -o wide`
   — all should show `Running`
2. **IP pool exists?** `kubectl get ipaddresspool,l2advertisement -n metallb-system`
   — should show `first-pool` and `l2-advert`
3. **External IP assigned?** `kubectl get svc -n ingress-nginx`
   — should show `10.1.1.10`, not `<pending>`
4. **Service type correct?** `kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}'`
   — must be `LoadBalancer`. Fix with:
   `kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'`
5. **OPNsense static route?** `System → Routes → Configuration` — must show `10.1.1.0/24` via `192.168.1.166`

#### `curl http://longhorn.lab` → can't resolve host

```bash
# 1. Test DNS directly against OPNsense:
dig +short longhorn.lab @192.168.1.1
# Empty? → Add host override in OPNsense (see Step 3 above)

# 2. Verify your machine uses OPNsense as DNS:
scutil --dns | head -10     # macOS
cat /etc/resolv.conf        # Linux
# Must show: nameserver 192.168.1.1

# 3. If dig works but browser/curl doesn't → flush DNS cache:
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder   # macOS
sudo systemd-resolve --flush-caches                                # Linux
```

#### `curl http://longhorn.lab` → 404 from nginx

ingress-nginx received the request but no Ingress rule matches that hostname:
```bash
kubectl get ingress -A
# Compare the HOSTS column with the hostname you're requesting
```
Common mismatches: `longhorn.lab` vs `longhorn.home`, trailing dots, typos in the Ingress
spec.

#### Internet request via NPM → 502 Bad Gateway

NPM on zaphod can't reach the MetalLB IP:
```bash
# Test from zaphod:
curl -s -o /dev/null -w "HTTP %{http_code}" http://10.1.1.10/
```
If this fails: check zaphod's default gateway routes through OPNsense, and that the
OPNsense static route is in place. Also verify the `proxy_set_header Host` directive in NPM.

#### MetalLB IP migrates to a different node (failover)

MetalLB L2 can migrate a VIP to a different node if the speaker goes down (within seconds).
Because `externalTrafficPolicy: Cluster`, kube-proxy on **any** node will DNAT correctly —
the OPNsense static route still works regardless of which node holds the VIP.

For extra resilience: add ECMP routes via all node IPs, or switch to BGP mode.

---

## Full Diagnostic Checklist

Run this sequence to diagnose any MetalLB/ingress issue end-to-end:

```bash
echo "=== 1. MetalLB pods ==="
kubectl get pods -n metallb-system -o wide

echo "=== 2. IP pool and L2 advertisement ==="
kubectl get ipaddresspool,l2advertisement -n metallb-system

echo "=== 3. ingress-nginx service ==="
kubectl get svc -n ingress-nginx

echo "=== 4. All ingress resources ==="
kubectl get ingress -A

echo "=== 5. MetalLB speaker election ==="
for pod in $(kubectl get pods -n metallb-system -l component=speaker -o name); do
  node=$(kubectl get -n metallb-system $pod -o jsonpath='{.spec.nodeName}')
  announced=$(kubectl logs -n metallb-system $pod 2>/dev/null \
    | grep "serviceAnnounced" | tail -1)
  if [ -n "$announced" ]; then
    echo "  >>> $node is ANNOUNCING"
  else
    echo "      $node is standby"
  fi
done

echo "=== 6. HTTP connectivity test (direct IP) ==="
code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://10.1.1.10/)
if [ "$code" = "404" ]; then
  echo "  HTTP $code — network path works (404 = no Host header matched, expected)"
elif [ "$code" = "000" ]; then
  echo "  HTTP $code — connection failed (check static route + MetalLB)"
else
  echo "  HTTP $code"
fi

echo "=== 7. DNS resolution test ==="
ip=$(dig +short longhorn.lab @192.168.1.1)
if [ -n "$ip" ]; then
  echo "  longhorn.lab → $ip"
else
  echo "  longhorn.lab → NOT RESOLVING (add Unbound host override)"
fi
```

---

## Next Steps

- [Step 9: Security Hardening](08-security-hardening.md) — SSH configuration, firewall rules
- Consider adding cert-manager TLS to your ingress resources for internal HTTPS
- For production-grade internet exposure, consider Cloudflare Tunnels (no port forwarding needed)
