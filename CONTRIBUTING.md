# Contributing

Thank you for helping improve this infrastructure lab.

## Development workflow

1. Fork or clone the repository.
2. Create a focused branch from `main`.
3. Make a small, clearly explained change.
4. Run the local checks listed below.
5. Open a pull request describing the reason, implementation, and test result.

Use conventional commit prefixes where practical, for example `feat:`, `fix:`, `docs:`, `test:`, or `ci:`.

## Local checks

From Debian or WSL:

```bash
python3 scripts/check-markdown-links.py
python3 -m compileall -q application scripts/check-markdown-links.py
yamllint .
ansible-lint ansible

cd ansible
for playbook in *.yml; do
  ANSIBLE_CONFIG=../.github/ansible-ci.cfg ansible-playbook -i inventory/hosts.yml "$playbook" --syntax-check
done
```

The GitHub Actions workflow runs equivalent checks for each push and pull request.

## Safety rules

- Never commit passwords, private keys, Vault password files, database dumps, ISO images, or production inventory overrides.
- Do not run failure playbooks against systems outside this disposable lab.
- Keep playbooks idempotent whenever the operation itself is not an intentional test.
- Use `no_log: true` for tasks that may expose credentials.
- Add verification and recovery steps when introducing a disruptive operation.

## Pull requests

A pull request should explain:

- the problem or improvement;
- which hosts, roles, or playbooks are affected;
- how the change was tested;
- whether it changes security, availability, or recovery behavior.
