#!/usr/bin/env python3

import json
import subprocess
from pathlib import Path

INVENTORY_FILE = Path("hosts.ini")

def terraform_outputs():
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            check=True,
            capture_output=True,
            text=True,
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        raise RuntimeError("Failed to read terraform outputs") from e


def main():
    outputs = terraform_outputs()

    frontend_ip = outputs["frontend_public_ip"]["value"]
    backend_ip = outputs["backend_private_ip"]["value"]

    inventory = f"""
[frontend]
frontend ansible_host={frontend_ip}

[backend]
backend ansible_host={backend_ip}

[all:vars]
ansible_user=ec2-user
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
"""

    INVENTORY_FILE.write_text(inventory.strip() + "\n")
    print(f"✔ Ansible inventory written to {INVENTORY_FILE}")


if __name__ == "__main__":
    main()
