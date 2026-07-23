# spaced's rootless jailbreak repo

## Temporary macOS 15 runner over Tailscale SSH

The `macOS 15 Tailscale SSH` workflow creates an ephemeral GitHub-hosted Apple
Silicon runner and makes its regular OpenSSH server reachable over Tailscale on
port 2222. It accepts public-key authentication only and shuts down when the
selected session duration expires or the workflow is cancelled.

### One-time setup

1. In Tailscale, create the tag `tag:github-runner` and a federated identity
   limited to this GitHub repository. Give the identity the `auth_keys` scope
   and permission to create nodes with `tag:github-runner`.
2. Ensure your tailnet policy allows your Tailscale user/device to reach
   `tag:github-runner` on TCP port 2222. For example, add this grant (merge it
   into your existing policy rather than replacing the policy):

   ```json
   {
     "src": ["autogroup:member"],
     "dst": ["tag:github-runner"],
     "ip": ["tcp:2222"]
   }
   ```

3. Add these GitHub Actions repository secrets under **Settings → Secrets and
   variables → Actions**:

   - `TS_OAUTH_CLIENT_ID`: the federated identity client ID
   - `TS_AUDIENCE`: the federated identity audience
   - `SSH_PUBLIC_KEY`: one complete public key line, such as the contents of
     `~/.ssh/id_ed25519.pub`

### Start and connect

Open **Actions → macOS 15 Tailscale SSH → Run workflow**, choose the session
length, and start it. When setup finishes, open the workflow run's job summary
and copy the displayed command. It resembles:

```sh
ssh -p 2222 runner@gh-macos15-RUN_ID-RUN_ATTEMPT.YOUR-TAILNET.ts.net
```

The connecting computer must already be signed in to the same tailnet. Cancel
the workflow run when finished; macOS GitHub-hosted runner minutes are billable
for private repositories.
