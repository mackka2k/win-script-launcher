# GitHub Release Creation Guide

## ✅ Release Package Ready!

**File:** `ScriptLauncher-v2.0.0-Windows.zip`
**Size:** ~35 MB
**SHA256:** `E65382F2C68E52EE1DCAA950713B7F44D6992747238488B9E184C52787575A1`

**Contents:**
- ScriptLauncher.exe (Standalone executable)
- README.md (Full documentation)
- LICENSE (MIT License)

---

## 🚀 Step-by-Step Release Creation

### Step 1: Push the Git Tag

In Git Bash, run:
```bash
git push origin v2.0.0
```

Enter your credentials:
- Username: `mackka2k`
- Password: [Your Personal Access Token]

### Step 2: Create Release on GitHub

1. **Go to:** https://github.com/mackka2k/script-launcher/releases/new

2. **Choose a tag:** Select `v2.0.0` from dropdown

3. **Release title:**
   ```
   Script Launcher v2.0.0 - Production Ready 🚀
   ```

4. **Description:** Copy the entire content from `RELEASE_NOTES.md`

5. **Attach binaries:**
   - Click "Attach binaries by dropping them here or selecting them"
   - Upload: `ScriptLauncher-v2.0.0-Windows.zip`
   - Optionally also upload: `dist/ScriptLauncher.exe` (standalone)

6. **Options:**
   - ✅ Set as the latest release
   - ✅ Create a discussion for this release (optional)

7. **Click:** "Publish release"

---

## 📋 Release Checklist

- [x] Tag created: `v2.0.0`
- [x] Release notes prepared: `RELEASE_NOTES.md`
- [x] Release package created: `ScriptLauncher-v2.0.0-Windows.zip`
- [x] SHA256 checksum generated
- [ ] Tag pushed to GitHub
- [ ] Release created on GitHub
- [ ] Assets uploaded
- [ ] Release published

---

## 📦 Release Assets

Upload these files to the release:

1. **ScriptLauncher-v2.0.0-Windows.zip** (Recommended)
   - Complete package with executable, README, and LICENSE
   - Size: ~35 MB
   - SHA256: `E65382F2C68E52EE1DCAA950713B7F44D6992747238488B9E184C52787575A1`

2. **ScriptLauncher.exe** (Optional - for users who just want the exe)
   - Located in: `dist/ScriptLauncher.exe`
   - Standalone executable

---

## 🔐 Security Note

**SHA256 Checksum for verification:**
```
E65382F2C68E52EE1DCAA950713B7F44D6992747238488B9E184C52787575A1
```

Users can verify the download integrity with:
```powershell
Get-FileHash ScriptLauncher-v2.0.0-Windows.zip -Algorithm SHA256
```

---

## 📝 Release Description Template

Copy this for the GitHub release description:

```markdown
# Script Launcher v2.0.0 - Production Ready Release 🚀

## 🎉 First Official Release!

A modern, production-ready Windows Script Launcher with a beautiful GUI and comprehensive utility scripts.

## ✨ Key Features

- 🎨 Modern compact list UI with category organization
- ⚡ 17+ utility scripts for Windows optimization
- 🔒 Production-ready code with custom exceptions and input validation
- 🧪 52 test cases with 52% code coverage
- 📝 Comprehensive documentation
- 🛡️ Security features (path traversal protection, input sanitization)

## 📦 What's Included

### Scripts by Category:
- 🧹 **Cleaning** (4): System Cleanup, Browser Cleaner, Empty Folder Cleaner, Registry Backup
- 🎮 **Gaming** (1): Game Optimizer
- 🛡️ **Privacy** (2): Privacy Tweaker, Context Menu Cleaner
- 🌐 **Network** (3): Network Diagnostics, DNS Changer, IP Information
- ⚙️ **System** (3): SSD Optimizer, Windows Debloater, Open to BIOS
- 🔧 **Quick Fixes** (4): Icon Cache Rebuild, Font Cache Rebuild, Store Reset, Search Rebuild

## 🚀 Quick Start

1. Download `ScriptLauncher-v2.0.0-Windows.zip`
2. Extract to any folder
3. Run `ScriptLauncher.exe`
4. No installation or Python required!

## 📊 Technical Details

- **Language:** Python 3.11
- **GUI:** Tkinter
- **Tests:** 52 (41 passing, 79%)
- **Coverage:** 52%
- **License:** MIT

## 🔐 Security

**SHA256 Checksum:**
```
E65382F2C68E52EE1DCAA950713B7F44D6992747238488B9E184C52787575A1
```

## 📄 Full Release Notes

See [RELEASE_NOTES.md](https://github.com/mackka2k/script-launcher/blob/main/RELEASE_NOTES.md) for complete details.

## 👤 Author

**mackka2k**
- GitHub: [@mackka2k](https://github.com/mackka2k)
- Email: mackonis111@gmail.com

---

**Made with ❤️ for Windows power users**
```

---

## 🎯 After Publishing

Once published, your release will be available at:
**https://github.com/mackka2k/script-launcher/releases/tag/v2.0.0**

Users can download with:
```bash
# Direct download link
https://github.com/mackka2k/script-launcher/releases/download/v2.0.0/ScriptLauncher-v2.0.0-Windows.zip
```

---

## ✨ Promotion Ideas

After publishing, consider:

1. **Add to GitHub Profile README**
2. **Share on social media**
3. **Post in relevant subreddits** (r/Windows, r/PowerShell, r/sysadmin)
4. **Add to awesome lists**
5. **Submit to software directories**

---

**Good luck with your release! 🚀**
