# RADHA — AWS Production Deploy Runbook

**Target topology:** the three NestJS processes (API + worker + scheduler) run in Docker on
**one EC2** (`ec2-18-60-109-5.ap-south-2`, Ubuntu); **Postgres → RDS**, **Redis →
ElastiCache**; **nginx + Let's Encrypt TLS** terminate in front of the API on your domain;
**S3 + CloudFront** host media + product images.

```
[Flutter app] --HTTPS--> [nginx :443 on EC2] --> [api :3000 (docker)]
                                                     |--> RDS Postgres (5432, TLS)
                                                     |--> ElastiCache Redis (6379, TLS)
                                                     '--> S3 / CloudFront (media)
[worker] [scheduler]  (same image, no public ports)
```

Files in this repo that drive the deploy:
`Dockerfile` · `.dockerignore` · `docker-compose.prod.yml` · `deploy/nginx/radha-api.conf` ·
`server/.env.production.example` · `server/tsconfig.runtime.json`.

> ⚠️ The image build hasn't been validated end-to-end yet (no Docker in the dev sandbox).
> The two things to watch on the **first build on the box** are called out in §11.

---

## 1. What you provide (gather these first)
- **Domain** for the API, e.g. `api.YOURDOMAIN.com` (an A record → the EC2's Elastic IP).
- **RDS** Postgres endpoint + `radha_app` user/password (db name `radha`).
- **ElastiCache** Redis primary endpoint (+ AUTH token if enabled).
- **S3 bucket** (`radha-prod-media`) + **CloudFront** distribution domain.
- **IAM**: either an **instance role** on the EC2 with S3 access (preferred) or an access-key pair.
- **Secrets:** real 2Factor key, Razorpay LIVE keys + webhook secret, JWT secrets (`openssl rand -hex 48`), Gemini key.

## 2. Provision AWS infra (console or CLI, region ap-south-… )
1. **RDS Postgres** (15+), Multi-AZ for prod, storage encryption on, automated backups (7–30d).
   DB name `radha`, master or app user `radha_app`. **Enforce TLS.**
2. **ElastiCache Redis** (cluster mode off is fine for V1), encryption in-transit on.
3. **S3 bucket** `radha-prod-media` (block public access ON — served via CloudFront, not public).
4. **CloudFront** distribution with the S3 bucket as origin (OAC). Note the `*.cloudfront.net` domain.
5. **Security groups:**
   - EC2 SG: inbound `22` (your IP only), `80` + `443` (0.0.0.0/0). **Do NOT expose 3000.**
   - RDS SG: inbound `5432` **from the EC2 SG only**.
   - ElastiCache SG: inbound `6379` **from the EC2 SG only**.
6. Allocate an **Elastic IP**, associate it with the EC2, and point `api.YOURDOMAIN.com` at it.

## 3. EC2 base setup (SSH in)
```bash
ssh -i Radha.pem ubuntu@ec2-18-60-109-5.ap-south-2.compute.amazonaws.com

sudo apt-get update && sudo apt-get install -y ca-certificates curl git nginx
# Docker engine + compose plugin
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu && newgrp docker
```

## 4. Get the code + env
```bash
git clone <YOUR_REPO_URL> radha && cd radha/RADHA_UPGRADED_PROJECT_FILES
# Build the prod env from the template (fill EVERY <PLACEHOLDER>):
cp server/.env.production.example server/.env.production
nano server/.env.production       # paste RDS/ElastiCache endpoints, secrets, domain
```
(If you don't have the repo on a git remote, `scp` the project up instead — but exclude
`apps/mobile/build` and `node_modules`.)

## 5. Build + run the stack
```bash
docker compose -f docker-compose.prod.yml --env-file server/.env.production build
docker compose -f docker-compose.prod.yml --env-file server/.env.production up -d
docker compose -f docker-compose.prod.yml ps          # api should become healthy
docker compose -f docker-compose.prod.yml logs -f api # watch boot (Ctrl-C to stop)
```
The API is now on `127.0.0.1:3000` (loopback). It is NOT public until nginx is wired (§7).

## 6. Migrate + seed (one-time, then as needed)
```bash
# Run inside the api container so it uses the same deps + env:
docker compose -f docker-compose.prod.yml exec api pnpm db:migrate
docker compose -f docker-compose.prod.yml exec api pnpm db:import:curated   # real OFF data
docker compose -f docker-compose.prod.yml exec api pnpm db:import:catalog   # (optional) broad OFF import
```
Then, locally, apply the resolved EANs into the app + rebuild the mobile app:
`cd apps/mobile && dart run tool/apply_resolved_eans.dart`.

## 7. nginx + HTTPS (Let's Encrypt)
```bash
sudo cp deploy/nginx/radha-api.conf /etc/nginx/sites-available/radha-api.conf
sudo sed -i 's/api.YOURDOMAIN.com/api.<your-real-domain>/g' /etc/nginx/sites-available/radha-api.conf
sudo ln -s /etc/nginx/sites-available/radha-api.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/certbot

# Issue the cert (DNS must already resolve to this box):
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.<your-real-domain> --agree-tos -m ops@<your-domain> --redirect
sudo nginx -t && sudo systemctl reload nginx
```
certbot auto-renews via its systemd timer.

## 8. Host the product images on S3/CloudFront (Phase 3)
After the curated seed (§6), with AWS creds/role + `AWS_S3_BUCKET` + `AWS_CLOUDFRONT_DOMAIN` set:
```bash
docker compose -f docker-compose.prod.yml exec api pnpm db:host:images
```
This uploads the 29 bundled WebP pack-shots to S3 and points `products.image_url` at the CDN.
The app still uses the bundled assets offline; network images become the canonical source.

## 9. Point the mobile app at production
Set the API base URL to `https://api.<your-domain>/` for release builds
(`apps/mobile/lib/core/network/dio_provider.dart` — base URL / `--dart-define=API_BASE_URL=`),
then `flutter build apk --release --split-per-abi` (or appbundle). Verify OTP login end-to-end.

## 10. Verify
```bash
curl -s https://api.<your-domain>/api/v1/health        # {"status":"ok",...}
curl -s https://api.<your-domain>/api/v1/health/ready   # downstream (db) check
```
Then in the app: request OTP → verify → browse a category → open a product → (seeded ones show real nutrition).

## 11. Operations + first-build gotchas
- **`@/` path alias (watch on first build):** `nest build` leaves `@/*` unresolved in `dist/`.
  The containers run `node -r tsconfig-paths/register` with `TS_NODE_PROJECT=tsconfig.runtime.json`
  (baseUrl=dist). If a container crashes with `Cannot find module '@/...'`, the cleaner permanent
  fix is to add `tsc-alias` to the server build (`nest build && tsc-alias -p tsconfig.build.json`)
  and drop the `-r tsconfig-paths/register` from the commands.
- **pnpm install in Docker:** the single-stage image keeps devDeps (so `tsx`/`ts-node` work for the
  migrate/seed CLIs). Slim later with `pnpm deploy --prod` if image size matters.
- **OFF seed needs outbound internet** from the EC2 (egress 443). It's idempotent — safe to re-run
  to resolve more products.
- **Redeploy after a code change:**
  `git pull && docker compose -f docker-compose.prod.yml --env-file server/.env.production up -d --build`.
- **Logs / restart:** `docker compose -f docker-compose.prod.yml logs -f <api|worker|scheduler>` ·
  `... restart <svc>`.
- Cross-check `PRODUCTION_CHECKLIST.md` before going live (backups, alerting, Razorpay webhook URL =
  `https://api.<your-domain>/api/v1/payments/webhook`).
```
