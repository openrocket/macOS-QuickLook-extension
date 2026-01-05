# OpenRocket QuickLook Preview (macOS)

This project builds a QuickLook preview plugin for OpenRocket project files on macOS and integrates it into the existing Install4j-generated OpenRocket DMG.

Because Install4j cannot build, sign, or notarize macOS QuickLook plugins, this repository provides an external signing + notarization workflow and a helper script to inject the signed plugin into the final DMG.

---

## Overview of the Build Flow

**Where things happen:**

| Step | Tool |
|----|----|
| Build the QuickLook plugin | **Xcode** |
| Sign & notarize the plugin | **Command line (`runit` script)** |
| Build the main OpenRocket app | **install4j** |
| Merge plugin into final DMG | **Command line (`runit` script)** |

---

## 1. Build the QuickLook Plugin (Xcode)

**Where:** Xcode

1. Open the Xcode project.
2. Select the project (top-level entry in the navigator).
3. For each target:
   - Go to **Signing & Capabilities**
   - Set:
     - **Team** → your Apple Developer team
     - **Signing Certificate** → `Developer ID Application`
4. Build the target normally (`⌘B`).

> No need to commit signing changes.

---

## 2. Apple Developer Prerequisites (One-Time)

**Where:** Apple Developer portal + command line

You must have:

- A **Developer ID Application** certificate  
- An **App-Specific Password** for notarization

### Store notarization credentials in Keychain

**Where:** Terminal

```bash
xcrun notarytool store-credentials "AppPwdNotarizID" \
  --apple-id "your@email.com" \
  --team-id YOURTEAMID \
  --password "app-specific-password"
```

- The string `"AppPwdNotarizID"` becomes your **keychain profile name**
- This avoids storing passwords in scripts

---

## 3. Prepare the Install4j DMG

**Where:** install4j

1. Build the standard OpenRocket macOS DMG using install4j.
2. Ensure:
   - Code signing is enabled
   - Notarization is enabled
3. Keep the resulting DMG — it will be **modified**, not rebuilt.

---

## 4. Configure the `runit` Script

**Where:** Xcode or any text editor

Open the `runit` shell script and set the following variables (lines 3–5):

```sh
KEYCHAIN_PROFILE="AppPwdNotarizID"
ORIGINAL_DMG="/full/path/to/OpenRocket-original.dmg"
MODIFIED_DMG="/full/path/to/OpenRocket-with-QuickLook.dmg"
```

What these mean:

- `KEYCHAIN_PROFILE`  
  → Name used in `notarytool store-credentials`
- `ORIGINAL_DMG`  
  → DMG produced by Install4j
- `MODIFIED_DMG`  
  → Output DMG with the signed QuickLook plugin added

---

## 5. Run the Signing + Notarization Script

**Where:** Terminal

```bash
cd path/to/project
./runit
```

The script will:

1. Sign the QuickLook plugin
2. Notarize it with Apple
3. Insert it into the Install4j DMG
4. Re-sign and re-notarize the modified DMG

---

## 6. Understanding / Debugging the Script

**Where:** Xcode

- Open `runit` in Xcode to inspect each step
- All signing and notarization commands are explicit and linear
- No install4j involvement at this stage

---

## Summary

- **install4j** builds and notarizes the main OpenRocket app
- **Xcode** builds the QuickLook plugin
- **`runit`** bridges the gap by signing, notarizing, and merging the plugin
- The final result is a Gatekeeper-clean DMG with a working QuickLook preview

This setup exists purely because macOS treats QuickLook plugins as separate executables, and Install4j does not support them.
