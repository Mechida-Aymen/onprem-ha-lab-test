# Secrets and safe publishing

## Files that must remain local

- `ansible/group_vars/vault.yml`
- the Vault password file, normally `~/.ansible-vault-password` inside WSL
- SSH private keys
- database dumps
- local inventory overrides and generated VM passwords

These paths are excluded by `.gitignore`. The active encrypted Vault file is also excluded: encrypted production credentials should not be published when a safe example is sufficient.

## Create local secrets

```bash
cd ansible
cp examples/vault.yml.example group_vars/vault.yml
```

Replace both example values with different random strings containing at least 32 characters, then encrypt the file:

```bash
ansible-vault encrypt group_vars/vault.yml
```

Create a controller-only password file if you do not want to enter the Vault password for every run:

```bash
install -m 0600 /dev/null ~/.ansible-vault-password
```

Enter the password using a text editor. Do not put the value directly in shell history. The repository's `ansible.cfg` expects this path.

## Verify before publishing

```bash
git status --short
git check-ignore -v ansible/group_vars/vault.yml
git grep -n -i -E 'password|secret|private.key'
```

The last command finds both unsafe values and legitimate variable names, so review every match. GitHub Actions also scans committed history with Gitleaks.

If a real secret is ever committed, rotate it first and then remove it from the entire Git history. A later deletion commit does not erase it from previous commits.
