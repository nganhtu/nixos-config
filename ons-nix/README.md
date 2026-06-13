# ons-nix — môi trường dev cho Onschool (devenv thay ons-docker)

Mỗi project Onschool có một thư mục self-contained ở đây: `.envrc` + `devenv.yaml` + `devenv.nix`
(+ `.env.age` nếu cần secret). Copy thư mục đè vào repo tương ứng trong `~/src/Onschool`, môi
trường dev (PHP/Node/JDK + deps) **tự dựng bằng Nix khi `cd` vào** — không cần Docker, deps nằm
thẳng trên host nên LSP chạy luôn.

Quen tay ons-docker: `docobuild` → khỏi cần · `docodul` → `devenv up` · `docobash` → `cd` là vào sẵn.

## Yêu cầu

- NixOS với `direnv` và `agenix` (đã có trong config Niquesse).
- `~/.ssh/id_ed25519` — identity để giải mã `.env` (xem [Secrets](#secrets-env)).

## Thiết lập một project

```bash
# 1. copy thư mục project vào repo Onschool tương ứng
cp -rT ons-nix/SRM/general ~/src/Onschool/SRM/general

# 2. tạo .env từ bản mã hoá (xem Secrets) — hoặc bung cả loạt một lần:
#    ./decrypt-env.sh ~/src/Onschool

# 3. kích hoạt môi trường (chỉ cần 1 lần cho mỗi project)
cd ~/src/Onschool/SRM/general
direnv allow

# 4. Laravel BE — thiết lập lần đầu (app key + passport); chỉ project có script này
bootstrap

# 5. chạy dev server (+ redis/prometheus/grafana nếu project khai báo)
devenv up
```

Sau bước `direnv allow`, mỗi lần `cd` vào là môi trường tự sẵn sàng.

## Project & runtime

Dùng devenv (trong repo này):

| Project | Runtime | Nguồn | Cổng |
|---|---|---|---|
| SLC/slc-migration | php8.4 (+redis) | nix-phps | 8088 |
| SLC/api-gateway | jdk21 + maven (+prometheus/grafana) | nixpkgs | 8080 / graf 3003 |
| SLC/apm-web-ui | node20 (yarn) | nixpkgs | 3000 |
| SRM/general | php8.1 (+libreoffice) | nix-phps | 8080 |
| SRM/registration-form/web-application | php8.1 (`php -S`) | nix-phps | 3000 |
| SRM/srm2-tmu-be | php8.1 (+libreoffice) | nix-phps | 8080 |
| SRM/srm-v1-be | php8.0 | nix-phps | 8000 |
| SRM/srm-gpu-v1-be | php8.0 | nix-phps | 8000 |
| SRM/web-application | node18 | nixpkgs pin `nixos-24.11` | 3000 |
| SRM/srm2-tmu-fe | node18 | nixpkgs pin `nixos-24.11` | 3000 |
| SRM/srm-v1-fe | node14 | nixpkgs pin `nixos-22.05` | 3000 |
| SRM/srm-gpu-v1-fe | node14 | nixpkgs pin `nixos-22.05` | 3000 |

Giữ Docker (vẫn chạy bằng ons-docker):

| Project | Lý do |
|---|---|
| SLC/student-oas-dashboard | stack 9 service (postgres/pgbouncer/valkey/minio/prometheus/grafana/nginx) — compose hợp hơn |

## Secrets (.env)

`.env` thật (chứa `DB_PASSWORD`, `JWT_SECRET`…) được mã hoá bằng **agenix** thành `*.env.age` nên
commit an toàn. Recipient key khai báo trong `secrets.nix`, giải mã bằng `~/.ssh/id_ed25519`.

```bash
./decrypt-env.sh ~/src/Onschool   # bung tất cả .env.age → .env vào cây Onschool
./decrypt-env.sh                  # bung tại chỗ (trong ons-nix)
agenix -e SRM/general/.env.age    # sửa / tạo secret (chạy từ thư mục có secrets.nix)
```

- Plaintext `.env` bị `.gitignore` ở đây — chỉ `.env.age` được track.
- `registration-form/web-application` không dùng `.env` (cấu hình trong `config.php`).
- Trong mỗi repo Onschool, nhớ `.gitignore`: `.devenv*`, `.direnv`, `devenv.local.nix`, `.env`.
