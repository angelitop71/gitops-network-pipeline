# GitOps Network Pipeline: Infraestructura de Red como Código

Proyecto TEL-342 — toda la topología de red y las reglas de seguridad se definen en código
(OpenTofu) y se despliegan/configuran automáticamente (Ansible) en cada push o merge a `main`
mediante GitHub Actions.

## Arquitectura

```
 Desarrollador ── git push / PR ──► GitHub ──► GitHub Actions
                                                 │
                     PR:   fmt → validate → plan → comentario en el PR
                     main: apply ──► AWS (VPC, subredes, IGW, rutas, Security Group, EC2)
                                  └► inventario ──► Ansible (nginx, UFW, hardening SSH)
                                                  └► smoke test (curl)
          Estado de OpenTofu: infra/terraform.tfstate versionado en el repo (lo commitea el pipeline)
```

| Capa | Qué define | Dónde |
|---|---|---|
| Topología | VPC 10.10.0.0/16, 2 subredes en 2 AZ, Internet Gateway, tabla de rutas | `infra/main.tf` + `infra/terraform.tfvars` |
| Seguridad de red | Security Group con reglas generadas desde `web_ingress_rules` | `infra/terraform.tfvars` |
| Seguridad de host | UFW con los **mismos** puertos que el SG + SSH sin password | `ansible/playbook.yml` |
| Servicio | nginx con página que muestra host, IP, commit y puertos | `ansible/templates/index.html.j2` |
| Pipeline | plan en PR, apply + Ansible + test en `main`, destroy manual | `.github/workflows/gitops.yml` |

## Puesta en marcha (una sola vez)

1. **Crear el repo** en GitHub y subir esta carpeta.
2. **Credenciales AWS** (cuenta normal o AWS Academy Learner Lab).
   En Learner Lab: *AWS Details → AWS CLI* muestra `aws_access_key_id`, `aws_secret_access_key`
   y `aws_session_token` (expiran cada ~4 h: actualizar los secrets antes de la demo).
3. **Estado**: no se usa S3 (la cuenta lo bloquea por SCP). El pipeline guarda `infra/terraform.tfstate`
   en el mismo repo tras cada apply/destroy, con `[skip ci]` para no relanzarse.
4. **Llave SSH para Ansible**:
   ```bash
   ssh-keygen -t ed25519 -f gitops_key -N "" -C "gitops-ansible"
   ```
5. **Secrets del repo** (*Settings → Secrets and variables → Actions*):

   | Secret | Valor |
   |---|---|
   | `AWS_ACCESS_KEY_ID` | ... |
   | `AWS_SECRET_ACCESS_KEY` | ... |
   | `SSH_PUBLIC_KEY` | contenido de `gitops_key.pub` |
   | `SSH_PRIVATE_KEY` | contenido de `gitops_key` |

6. (Opcional) *Settings → Environments → `produccion`* → *Required reviewers*: obliga a aprobar
   cada despliegue (control de cambios).
7. Primer despliegue: *Actions → GitOps Network Pipeline → Run workflow → apply*.

## Guion de la demo (≈10 min)

1. Mostrar el repo y `terraform.tfvars`: "la red completa está en este archivo".
2. Abrir `http://<ip>` de un servidor → página con commit y puertos `22, 80`.
3. Probar que el 8080 está cerrado: `nc -zv <ip> 8080` → timeout.
4. Crear rama, descomentar la regla `app` (8080) en `terraform.tfvars`, abrir **Pull Request**.
5. Mostrar el comentario automático con el **plan**: `+ aws_vpc_security_group_ingress_rule.web["app"]`.
6. **Merge** → ver el job `deploy` en vivo: apply → Ansible abre 8080 en UFW → smoke test.
7. Recargar la página: commit nuevo y puertos `22, 80, 8080`.
8. (Extra) Cambiar algo a mano en la consola AWS y mostrar que el siguiente `plan` detecta el
   *drift* y lo revierte → el repositorio es la única fuente de verdad.
9. Al final: *Run workflow → destroy* (para no gastar créditos).

Otras ideas de cambio para la demo: `web_count = 3` (escalar), agregar una subred `publica-c`,
restringir SSH a la IP de la universidad, cerrar el 80 y mostrar que la web deja de responder.

## Pruebas locales (opcional)

```bash
cd infra
tofu init
TF_VAR_ssh_public_key="$(cat ../gitops_key.pub)" tofu plan
```

## Limitaciones conocidas (mencionar en el informe)

- SSH abierto a `0.0.0.0/0` porque las IP de los runners de GitHub cambian. Mitigación: solo
  autenticación por llave + UFW. Mejoras: AWS SSM Session Manager, runner self-hosted o bastion.
- Estado en el repo: sin bloqueo concurrente (se mitiga con `concurrency` en el workflow) y en texto plano.
  Mejora: backend S3 o cifrado de estado de OpenTofu (`encryption` con passphrase).
- Credenciales estáticas en secrets. Mejora: OIDC de GitHub → rol IAM (no disponible en Learner Lab).
- Subredes solo públicas (una privada requiere NAT Gateway, que tiene costo).
