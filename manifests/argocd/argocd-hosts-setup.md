# Setting up Local DNS for ArgoCD

We've identified the issue with accessing ArgoCD UI. The SSL certificate has been successfully generated and the ingress is working correctly, but your machine can't resolve the hostname `argocd.local`.

## The Problem

In a homelab environment, `.local` domains don't automatically work without additional configuration.

The key issues are:
1. Your machine can't resolve `argocd.local` to the correct IP address (10.1.1.10)
2. This is necessary because browsers need to match the hostname in the URL with the hostname in the certificate

## Solution: Edit Your Hosts File

The simplest solution is to edit your hosts file to map `argocd.local` to the ingress controller's IP address.

### On macOS/Linux:

1. Open Terminal
2. Edit the hosts file with sudo:
   ```bash
   sudo nano /etc/hosts
   ```
3. Add this line at the end:
   ```
   10.1.1.10  argocd.local
   ```
4. Save and exit (Ctrl+O, Enter, Ctrl+X)
5. Flush DNS cache:
   ```bash
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   ```

### On Windows:

1. Open Notepad as Administrator
2. Open file: `C:\Windows\System32\drivers\etc\hosts`
3. Add this line at the end:
   ```
   10.1.1.10  argocd.local
   ```
4. Save the file
5. Flush DNS cache:
   ```
   ipconfig /flushdns
   ```

## Testing the Connection

After making these changes, try accessing https://argocd.local in your browser.

You'll still see a certificate warning because it's a self-signed certificate, but you can proceed anyway (click "Advanced" > "Proceed to argocd.local (unsafe)").

## Alternative Solution: Local DNS Server

For a more scalable solution in your homelab, consider setting up a local DNS server like Pi-hole or dnsmasq that can handle `.local` domains. This would eliminate the need to edit the hosts file on each device.

## Verification

To verify your hosts file is working correctly, run:

```bash
ping argocd.local
```

It should ping the IP address 10.1.1.10.