# CLAUDE.md - Guidelines for Ansible Homelab Project

## Commands
- Run a playbook: `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml`
- Run with sudo prompt: `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml -K`
- Syntax check: `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml --syntax-check`
- Check mode (dry run): `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml --check`
- Run on specific host: `ansible-playbook -i inventory.yml -l <hostname> playbooks/<playbook_name>.yml`
- Lint playbooks: `ansible-lint playbooks/*.yml`
- Validate YAML: `yamllint playbooks/*.yml`
- Test a task: `ansible -i inventory.yml <hostname> -m <module_name> -a "<module_arguments>"`

## Style Guidelines
- **Naming**: Use snake_case for variables, tasks, and file names
- **YAML Formatting**: Use 2 spaces for indentation
- **Tasks**: Each task should have a clear, descriptive name
- **Variables**: 
  - Use admin_vars.yml for centralized admin settings
  - Reference variables with `{{ variable_name }}`
- **Module Names**: Use fully qualified module names (e.g., `ansible.builtin.ping`, `ansible.posix.authorized_key`)
- **Organization**: 
  - Group related tasks in the same playbook
  - Use paired up/down playbooks for symmetric operations (e.g., prepare.up.yml and prepare.down.yml)
- **Error Handling**: Use the `failed_when` directive for custom failure conditions

## Project Structure
- Keep inventory file at root level
- Store all playbooks in the playbooks/ directory
- Use todo.txt and done.txt for task tracking