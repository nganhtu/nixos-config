# ons-nix — devenv thay cho ons-docker (môi trường dev)

Bản dịch workflow `ons-docker` sang **devenv + direnv** cho máy NixOS. Mỗi project là một
thư mục self-contained (`.envrc` + `devenv.yaml` + `devenv.nix`), copy đè vào repo tương ứng
trong `~/src/Onschool` y như cách dùng `ons-docker`.

## Khác gì so với Docker

| | ons-docker | ons-nix (devenv) |
|---|---|---|
| Build | `docobuild` | không cần (Nix tự dựng khi `cd`) |
| Chạy | `docodul` | `devenv up` |
| Vào shell | `docobash <svc>` | `cd` là vào sẵn (direnv) |
| Deps host | `docker cp vendor` ra host | nằm thẳng trên host, uid của bạn → LSP chạy luôn |

## Dùng thế nào

```bash
# 1 lần cho mỗi project, sau khi copy file vào repo:
cd <project>
direnv allow            # cho phép tự kích hoạt môi trường

# Laravel backend — thiết lập lần đầu (key + passport):
bootstrap               # script định nghĩa trong devenv.nix (chỉ các BE Laravel có)

# Chạy dev server (+ service như redis/prometheus/grafana nếu có):
devenv up
```

## Project nào Nix, project nào giữ Docker

**→ devenv (trong repo này):**

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

**→ giữ Docker (vẫn dùng `ons-docker`):**

| Project | Lý do |
|---|---|
| SLC/student-oas-dashboard | stack 9-service (postgres/pgbouncer/valkey/minio/prometheus/grafana/nginx) — compose đúng việc |

## Lưu ý

- **`.env` không quản ở đây.** Vẫn để như cũ (file copy kèm, quản ở `ons-docker`). ons-nix
  không carry `.env` nên không đè lên `.env` sẵn có trong repo.
- **Thêm vào `.gitignore` của mỗi repo Onschool:** `.devenv*`, `.direnv`, `devenv.local.nix`.
  (Không đặt sẵn `.gitignore` ở đây để khỏi đè `.gitignore` gốc của project khi copy.)

## CHECKLIST verify trên máy NixOS (chưa chạy thử được khi scaffold)

- [ ] **PHP insecure:** php8.0/8.1 bị nixpkgs đánh dấu insecure. Đã xử bằng
      `config.allowInsecurePredicate = _: true` khi import nixpkgs. Nếu vẫn chặn → kiểm tra
      `nix-phps` có cung cấp `overlays.default` đúng tên không.
- [ ] **Tên extension PHP:** `withExtensions` dùng tên `pdo_mysql`, `pdo_pgsql`, `bcmath`,
      `gd`, `zip`, `mbstring`, `exif`, `pcntl`. Verify khớp attr trong nix-phps.
- [ ] **composer:** đến từ `languages.php`. Nếu thiếu, thêm vào `packages`.
- [ ] **node14 attr:** đang dùng `nodejs-14_x` (nixos-22.05). Nếu lỗi → đổi `nodejs_14`.
- [ ] **node18 attr:** `nodejs_18` (nixos-24.11) — verify build.
- [ ] **api-gateway:** đã sửa target prometheus `slc-be:8080` → `localhost:8080`. Lệnh grafana
      (`grafana server …`) cần verify cú pháp với bản grafana trong nixpkgs.
- [ ] **Cổng artisan serve:** đã đặt theo cổng host docker publish. Đối chiếu lại nếu app
      đọc cổng từ `.env`.
- [ ] **frontend deps:** `webpack@4` + `flatpickr` (web-application, srm2-tmu-fe) phải có sẵn
      trong `package.json` — Docker cũ `npm install --save` thêm lúc build.
