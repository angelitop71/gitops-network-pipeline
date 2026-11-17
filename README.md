# GitOps Network Pipeline: Infraestructura de Red como Código

Proyecto TEL-342. Toda la topología de red y las reglas de seguridad se definen en código
(OpenTofu) y se despliegan y configuran automáticamente (Ansible) en cada push o merge a `main`
mediante GitHub Actions.

## Arquitectura

```
 Desarrollador ── git push / PR ──► GitHub ──► GitHub Actions ──► runner self-hosted (servidor Ubuntu)
                                                                    │
     PR:   fmt → validate → plan → comentario automático en el PR    │
     main: tofu apply ──► Docker: redes + contenedores               │
           └► inventario ──► Ansible: nginx + iptables               │
           └► smoke test (web responde / DB no expuesta)             │
     Estado OpenTofu: infra/terraform.tfstate versionado en el repo

        Internet/host ──► :8001 ─► [web-1] ─┐
                      ──► :8002 ─► [web-2] ─┤  red DMZ 172.30.10.0/24
                                            │
                                  [db redis]┘  red BACKEND 172.30.20.0/24 (internal, aislada)
```

| Capa | Qué define | Dónde |
|---|---|---|
| Topología | Red DMZ + red backend aislada (`internal`), subredes | `infra/terraform.tfvars` → `networks` |
| Seguridad de red | Puertos publicados; la DB no publica nada | `infra/terraform.tfvars` → `firewall_rules` |
| Seguridad de host | iptables: política DROP + solo los puertos de `firewall_rules` | `ansible/playbook.yml` |
| Servicio | nginx escuchando en cada puerto declarado | `ansible/templates/` |
| Pipeline | plan en PR; apply + Ansible + test en `main`; destroy manual | `.github/workflows/gitops.yml` |

Una sola definición (`firewall_rules`) alimenta los puertos de Docker **y** el firewall iptables
(defensa en profundidad).

## Instalación en el servidor (una vez)

```bash
sudo apt update
sudo apt install -y docker.io ansible jq curl git
sudo snap install --classic opentofu
sudo usermod -aG docker $USER      # luego cerrar sesión y volver a entrar (o: newgrp docker)
docker ps && tofu version && ansible --version
```

### Runner self-hosted de GitHub
Repo → *Settings → Actions → Runners → New self-hosted runner → Linux x64*: copiar y ejecutar
los comandos que muestra GitHub (download, `./config.sh ...`). Después dejar corriendo:

```bash
cd ~/actions-runner && ./run.sh
```

### Permiso para que el pipeline commitee el estado
Repo → *Settings → Actions → General → Workflow permissions* → **Read and write permissions**.

## Primer despliegue
*Actions → GitOps Network Pipeline → Run workflow → apply*. Luego abrir `http://localhost:8001`.

## Guion de la demo (≈10 min)

1. Mostrar `infra/terraform.tfvars`: "la red completa y el firewall están en este archivo".
2. `docker network ls` / `docker ps` → redes `gitops-net-dmz` y `gitops-net-backend`, 3 contenedores.
3. Abrir `http://localhost:8001` y `:8002` → página con commit, reglas y "DB alcanzable (solo desde servidores)".
4. Mostrar el aislamiento: `nc -zv localhost 6379` → falla (la DB no está expuesta).
5. Mostrar el firewall: `docker exec gitops-net-web-1 iptables -L INPUT -n --line-numbers`.
6. Crear rama, descomentar la regla `app` en `terraform.tfvars`, push y abrir **Pull Request**.
7. Mostrar el comentario automático con el **plan** (los contenedores se recrean con el puerto 8080).
8. **Merge** → ver el job `deploy` en vivo: apply → Ansible → smoke test.
9. Abrir `http://localhost:9001` → nuevo servicio; la página muestra el commit nuevo y la regla `app`.
10. (Extra, drift) `docker exec gitops-net-web-1 iptables -P INPUT ACCEPT` a mano → re-ejecutar el
    pipeline → Ansible vuelve a poner DROP. Git es la única fuente de verdad.

Otras ideas: `web_count = 3` (escalar), cambiar `source` a `172.30.10.0/24` (solo DMZ),
agregar una tercera red.

## Comandos locales útiles
```bash
cd infra && tofu init && tofu plan          # ver qué cambiaría
docker ps --filter label=role=web
docker exec -it gitops-net-web-1 bash
```

## Alternativa cloud (`alternativa-aws/`)
Diseño original para AWS (VPC, subredes en 2 AZ, Internet Gateway, Security Groups, EC2 + UFW).
No se pudo usar porque la cuenta AWS disponible pertenece a una organización con una
*Service Control Policy* que deniega explícitamente `ec2:CreateVpc`, `ec2:DescribeImages`,
`s3:CreateBucket` y `ssm:GetParameter`. El flujo GitOps es idéntico; solo cambia el provider.

## Limitaciones y mejoras (para el informe)
- Estado en el repo: sin bloqueo (mitigado con `concurrency`) y sin cifrar. Mejora: backend remoto
  (S3/HTTP) o cifrado de estado nativo de OpenTofu.
- Contenedores en vez de VMs: misma lógica de red, menor aislamiento. Mejora: provider libvirt o cloud.
- Al cambiar puertos, Docker recrea los contenedores (breve corte). Mejora: reverse proxy delante.
- El runner self-hosted tiene acceso a Docker (equivale a root): usar en máquina dedicada.
