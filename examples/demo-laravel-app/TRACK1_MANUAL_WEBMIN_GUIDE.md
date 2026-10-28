# Track 1 Guide: Manual Deployment via Webmin & Adminer (Zero-CLI / Shared Hosting Style)

## 1. Overview & Objective

This track demonstrates how to deploy the **ServerLab Pulse** Laravel application in an academic or shared-hosting environment where **terminal, console, and SSH access are strictly unavailable**.

All operational steps—including file transfer, configuration, database creation, and schema migration—are performed entirely through web browsers using **Webmin** (`:10000`) and **Adminer** (`:12322`).

---

## 2. Prerequisites & Access Points

| Component | URL / Port | Credentials |
| :--- | :--- | :--- |
| **Webmin Control Panel** | `https://tajbi.poliwangi.ac.id:10000` | TurnKey root credentials |
| **Adminer Database Manager** | `http://tajbi.poliwangi.ac.id:12322` | System MariaDB root credentials |
| **Public Ingress URL** | `https://tajbi.poliwangi.ac.id/jbi24061/` | Publicly accessible |

---

## 3. Step-by-Step Deployment Procedure

### Step 1: Prepare the Deployment Artifacts
Because Composer and Node cannot be run on the target server without SSH, the project packaging utilities support multiple output formats tailored for Webmin and shared hosting environments:

1. **Native Linux `tar.gz` (`serverlab-pulse.tar.gz`, ~12.3 MB)**:
   > [!TIP]
   > **Recommended for TurnKey Linux / Webmin Filemin**: Native Linux tarballs preserve UNIX permissions (`755`, `644`) and extract with 100% native compatibility on Debian/TurnKey without triggering unzip password prompts.
2. **Webmin-Compatible ZIP (`serverlab-pulse.zip`, ~17.5 MB)**:
   Generated with standard deflate archiving (`bsdtar`), fully unencrypted.
3. **Directory Mode (`dist/serverlab-pulse`)**:
   Generates a clean uncompressed folder for direct upload or sync.

#### Generating the Artifacts
Packaging utilities are provided for both PowerShell (Windows) and Bash (Linux/macOS/Docker):

**Option A — Using PowerShell (Native Windows):**
```powershell
# Recommended: Generate native tar.gz for Webmin
powershell -ExecutionPolicy Bypass -File .\examples\demo-laravel-app\scripts\package-for-webmin.ps1 targz

# Generate standard ZIP archive
powershell -ExecutionPolicy Bypass -File .\examples\demo-laravel-app\scripts\package-for-webmin.ps1 zip

# Generate clean uncompressed directory (dist/serverlab-pulse)
powershell -ExecutionPolicy Bypass -File .\examples\demo-laravel-app\scripts\package-for-webmin.ps1 dir

# Generate all formats simultaneously:
powershell -ExecutionPolicy Bypass -File .\examples\demo-laravel-app\scripts\package-for-webmin.ps1 all
```

**Option B — Using Bash (Linux / WSL / Docker):**
```bash
# Recommended: Generate native tar.gz
bash examples/demo-laravel-app/scripts/package-for-webmin.sh targz

# Generate standard ZIP
bash examples/demo-laravel-app/scripts/package-for-webmin.sh zip

# Generate clean uncompressed directory
bash examples/demo-laravel-app/scripts/package-for-webmin.sh dir

# Generate all formats
bash examples/demo-laravel-app/scripts/package-for-webmin.sh all
```

---

### Step 2: Upload Files Using Webmin File Manager
1. Open your browser and navigate to **Webmin**: `https://tajbi.poliwangi.ac.id:10000`.
2. In the left navigation menu, expand **Tools** (or **System**) and click **File Manager** (Filemin).
3. In the directory navigation path bar, traverse to: `/var/www/laravel`.
4. If an existing placeholder exists, select all files and back them up or delete them.
5. In the top Webmin toolbar, click **File** -> **Upload to current directory** (or click the **Upload** icon).
6. Upload either:
   - **`serverlab-pulse.tar.gz` (Recommended)**: Select the file and click **Extract**. Native `tar` on Debian will instantly extract all files without password prompts.
   - **`serverlab-pulse.zip`**: Select the file and click **Extract**.
7. Verify that `/var/www/laravel/public/index.php` and `/var/www/laravel/artisan` exist in `/var/www/laravel`.
8. Delete the uploaded archive (`.tar.gz` or `.zip`) to conserve disk space.

### Step 3: Configure Environment Variables (`.env`) & Generate Secrets
1. In Webmin File Manager, locate `.env.example` in `/var/www/laravel`.
2. Click on `.env.example`, select **Copy**, and name the new file `.env`.
3. Open `.env` in the Webmin built-in text editor.
4. **Generate a Unique Production `APP_KEY`**:
   Because terminal/Artisan access is unavailable on the target server, generate a 32-byte cryptographically secure AES-256 key manually on your workstation:
   - **On Windows (PowerShell)**:
     ```powershell
     powershell -Command "$bytes = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes); 'base64:' + [Convert]::ToBase64String($bytes)"
     ```
   - **On Linux / macOS (OpenSSL)**:
     ```bash
     echo "base64:$(openssl rand -base64 32)"
     ```
   - **Online / Air-gapped**: Any 32-byte random base64 string prefixed with `base64:`.
5. Insert the newly generated key into your `.env` alongside the campus path and database credentials:
   ```ini
   APP_NAME="ServerLab Pulse"
   APP_ENV=production
   APP_KEY=YOUR_GENERATED_BASE64_KEY_HERE
   APP_DEBUG=false
   APP_URL=https://tajbi.poliwangi.ac.id/jbi24061
   APP_PATH_PREFIX=jbi24061

   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=db_serverlab
   DB_USERNAME=root
   DB_PASSWORD=YOUR_CAMPUS_ROOT_MARIADB_PASSWORD

   SESSION_DRIVER=cookie
   CACHE_STORE=file
   QUEUE_CONNECTION=sync
   ```
6. Click **Save and Close**.

### Step 4: Set Directory Permissions in Webmin
Web servers running Apache require write permissions for storage:
1. In Webmin File Manager, right-click on the `storage` and `bootstrap/cache` folders.
2. Select **Properties** (or **Permissions / Ownership**).
3. Set Permissions to `775` (or `777` for shared testing), and set the owner group to `www-data`.
4. Check **Apply to this directory and all subdirectories**, then click **Save**.

### Step 5: Create and Import Database via Adminer
1. Open **Adminer** in your browser: `http://tajbi.poliwangi.ac.id:12322`.
2. Log in:
   - **System**: `MySQL`
   - **Server**: `localhost` (or `127.0.0.1`)
   - **Username**: `root`
   - **Password**: TurnKey MariaDB root password
3. Click **Create database**:
   - Name: `db_serverlab`
   - Collation: `utf8mb4_unicode_ci`
   - Click **Save**.
4. Select the newly created database `db_serverlab`.
5. Click **SQL Command** (or **Import**):
   - Click **Browse** and select `database/schema.sql` from your local machine.
   - Click **Execute**.
6. Verify that the table `server_nodes` appears with 3 sample seeded records.

---

## 4. Verification

Visit your campus path in your browser:
```text
https://tajbi.poliwangi.ac.id/jbi24061/
```

### Expected Result:
- The **ServerLab Pulse** interface loads with full Bootstrap 5 styling.
- The **Runtime Mode** badge displays: `Native Apache (TurnKey LAMP Mode)`.
- The **Database Status** card shows: `Connected` with low latency.
- The **Subpath Prefix** indicates: `/jbi24061`.
- Clicking "Register Node" adds a new record to MariaDB without any page break or redirection loss.
