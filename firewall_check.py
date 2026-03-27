#!/usr/bin/env python3
"""Script de configuração pós-deploy: abre firewall e verifica app."""
import os
import paramiko
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

HOST     = "177.44.248.116"
USER     = "univates"
PASSWORD = os.environ["VM_PASSWORD"]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, password=PASSWORD, timeout=30,
               look_for_keys=False, allow_agent=False)

cmds = [
    "sudo ufw allow 3000/tcp",
    "sudo ufw --force enable",
    "sudo ufw status",
    "pm2 list",
    "curl -s -X POST http://localhost:3000/api/auth/login -H 'Content-Type: application/json' -d '{\"login\":\"admin\",\"senha\":\"admin123\"}' | head -c 200",
]

for cmd in cmds:
    print(f"\n$ {cmd}")
    _, stdout, stderr = client.exec_command(cmd, timeout=30)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out:
        print(out)
    if err:
        print(f"[stderr] {err[:300]}")

client.close()
print("\nConcluido.")
