# Quick Install

## Recommended: Automated Installation

### Unix/Linux/macOS

```bash
cd your-project/
curl -sSL https://automaze.io/ccpm/install | bash
```

Or with wget:

```bash
cd your-project/
wget -qO- https://automaze.io/ccpm/install | bash
```

### Windows (PowerShell)

```powershell
cd your-project/
iwr -useb https://automaze.io/ccpm/install | iex
```

---

## Manual Installation with Git Clone

If you prefer manual installation or already have a `.claude` directory:

### Unix/Linux/macOS

```bash
# Clone to temporary directory
cd your-project/
git clone https://github.com/automazeio/ccpm.git temp-ccpm

# Copy ccpm directory to .claude
cp -r temp-ccpm/ccpm .claude

# Clean up
rm -rf temp-ccpm
```

### Windows (PowerShell)

```powershell
# Clone to temporary directory
cd your-project/
git clone https://github.com/automazeio/ccpm.git temp-ccpm

# Copy ccpm directory to .claude
Copy-Item -Recurse temp-ccpm/ccpm .claude

# Clean up
Remove-Item -Recurse -Force temp-ccpm
```

### Windows (cmd)

```cmd
REM Clone to temporary directory
cd your-project\
git clone https://github.com/automazeio/ccpm.git temp-ccpm

REM Copy ccpm directory to .claude
xcopy /E /I temp-ccpm\ccpm .claude

REM Clean up
rmdir /s /q temp-ccpm
```

---

## Important Notes

⚠️ **If you already have a `.claude` directory:**

1. Backup your existing `.claude` directory first
2. Either merge the contents manually, or
3. Install CCPM to a different location and copy what you need

⚠️ **The `ccpm/` directory contains the actual `.claude` content:**

- This repository's structure: `ccpm/` (contains all the files)
- Your project structure: `.claude/` (where files should be installed)
- The installation scripts handle this mapping automatically

---

## Next Steps

After installation, run:

```bash
/pm:init
```

This will:
- Detect your Git forge (GitHub or Gitea)
- Install required CLI tools (gh or tea)
- Configure authentication
- Create necessary directories
- Update .gitignore
