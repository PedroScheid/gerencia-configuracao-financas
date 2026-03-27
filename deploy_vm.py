#!/usr/bin/env python3
"""
deploy_vm.py — Implantação automática na VM usando paramiko (SSH)
VM: univates@177.44.248.116
"""
import os
import sys
import tarfile
import tempfile
import paramiko
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

HOST     = "177.44.248.116"
USER     = "univates"
PASSWORD = os.environ["VM_PASSWORD"]
REMOTE   = "/home/univates/financas"

BASE = Path(__file__).parent.resolve()

# ──────────────────────────────────────────────
def make_client() -> paramiko.SSHClient:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        # Tenta password auth padrão
        client.connect(HOST, username=USER, password=PASSWORD, timeout=30,
                       look_for_keys=False, allow_agent=False)
    except paramiko.ssh_exception.AuthenticationException:
        # Fallback: keyboard-interactive
        transport = paramiko.Transport((HOST, 22))
        transport.connect()
        transport.auth_interactive(USER, lambda title, instructions, fields: [PASSWORD] * len(fields))
        client._transport = transport
    return client

def run(client: paramiko.SSHClient, cmd: str, check: bool = True) -> str:
    print(f"  $ {cmd}")
    _, stdout, stderr = client.exec_command(cmd, timeout=300)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    if out:
        print(f"    {out}")
    if err:
        print(f"    [stderr] {err}", file=sys.stderr)
    if check and stdout.channel.recv_exit_status() != 0:
        raise RuntimeError(f"Comando falhou: {cmd}\n{err}")
    return out

def upload_dir(sftp: paramiko.SFTPClient, local: Path, remote: str):
    """Cria um tar localmente e faz upload + extração na VM."""
    print(f"  Compactando {local.name}/ ...")
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as tmp:
        tmp_path = tmp.name

    with tarfile.open(tmp_path, "w:gz") as tar:
        tar.add(str(local), arcname=local.name)

    remote_tar = f"/tmp/{local.name}.tar.gz"
    print(f"  Enviando {local.name}.tar.gz → {remote_tar} ...")
    sftp.put(tmp_path, remote_tar)
    os.unlink(tmp_path)
    return remote_tar

# ──────────────────────────────────────────────
def main():
    print("\n=== Deploy FinançasPessoais → VM ===\n")

    # 1) Conecta
    print("[1/6] Conectando na VM...")
    client = make_client()
    sftp   = client.open_sftp()
    print(f"  Conectado como {USER}@{HOST}")

    # 2) Verifica / instala Node.js
    print("\n[2/6] Verificando Node.js...")
    node_version = run(client, "node --version 2>/dev/null || echo MISSING", check=False)
    if "MISSING" in node_version or not node_version.startswith("v"):
        print("  Node.js não encontrado – instalando v20 ...")
        run(client, "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -")
        run(client, "sudo apt-get install -y nodejs build-essential python3-dev")
    else:
        print(f"  Node.js já instalado: {node_version}")

    # 3) Verifica / instala PM2
    print("\n[3/6] Verificando PM2...")
    pm2_ver = run(client, "pm2 --version 2>/dev/null || echo MISSING", check=False)
    if "MISSING" in pm2_ver:
        print("  PM2 não encontrado – instalando ...")
        run(client, "sudo npm install -g pm2")
    else:
        print(f"  PM2 já instalado: {pm2_ver}")

    # 4) Cria estrutura de diretórios
    print("\n[4/6] Preparando diretórios na VM...")
    run(client, f"mkdir -p {REMOTE}/frontend")

    # 5) Faz upload do backend compilado + frontend dist
    print("\n[5/6] Enviando arquivos...")

    # Backend dist/
    backend_dist = BASE / "backend" / "dist"
    backend_pkg  = BASE / "backend" / "package.json"
    tar_path = upload_dir(sftp, backend_dist, f"{REMOTE}/backend")
    run(client, f"mkdir -p {REMOTE}/backend && cd {REMOTE}/backend && tar xzf {tar_path} && rm {tar_path}")

    # package.json do backend (para npm install --omit=dev)
    sftp.put(str(backend_pkg), f"{REMOTE}/backend/package.json")

    # Frontend dist/
    frontend_dist = BASE / "frontend" / "dist"
    front_tar = upload_dir(sftp, frontend_dist, f"{REMOTE}/frontend")
    run(client, f"mkdir -p {REMOTE}/frontend && cd {REMOTE}/frontend && tar xzf {front_tar} && rm {front_tar}")

    # ecosystem.config.js
    sftp.put(str(BASE / "ecosystem.config.js"), f"{REMOTE}/ecosystem.config.js")
    print("  ecosystem.config.js enviado")

    # 6) Instala dependências e inicia com PM2
    print("\n[6/6] Instalando deps de produção e iniciando com PM2...")
    run(client, f"cd {REMOTE}/backend && npm install --omit=dev")
    run(client, f"cd {REMOTE} && pm2 delete financas 2>/dev/null; pm2 start ecosystem.config.js", check=False)
    run(client, "pm2 save")
    run(client, "sudo pm2 startup systemd -u univates --hp /home/univates 2>/dev/null || true", check=False)

    sftp.close()
    client.close()

    print("\n" + "="*50)
    print("  Deploy concluído com sucesso!")
    print(f"  URL: http://{HOST}:3000")
    print("  Login: admin / admin123")
    print("="*50 + "\n")

if __name__ == "__main__":
    main()
