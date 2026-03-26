# OpenRocket QuickLook Preview (macOS)

This project builds a QuickLook preview plugin for OpenRocket `.ork` files on macOS and integrates it into the existing install4j-generated OpenRocket DMG.

Because install4j cannot build, sign, or notarize macOS QuickLook extensions, this repository provides an external Xcode project and a helper script (`runit`) to build, sign, notarize, and inject the plugin into the final DMG.

---

## Architecture

The project has two Xcode targets:

| Target | Output | Purpose |
|--------|--------|---------|
| **OpenRocket QuickLook Preview** | `.app` (host) | A minimal shell app that carries the QuickLook extension and declares the `.ork` UTI |
| **OpenRocket QL Preview** | `.appex` (extension) | The actual QuickLook preview extension that renders `.ork` files |

The `.appex` lives inside the host app at `OpenRocket QuickLook Preview.app/Contents/Plugins/OpenRocket QL Preview.appex`. During the merge step, the `Plugins/` folder is copied into the install4j-built `OpenRocket.app`.

---

## Prerequisites

### Apple Developer Account

You need an [Apple Developer Program](https://developer.apple.com/programs/) membership.

### 1. Developer ID Application Certificate

This certificate is required for signing apps distributed **outside** the Mac App Store.

1. Go to [developer.apple.com/account](https://developer.apple.com/account) > **Certificates, Identifiers & Profiles** > **Certificates**
2. Click **+** and select **Developer ID Application**
3. Follow the prompts to generate and download the certificate
4. Double-click the downloaded `.cer` file to install it in your Keychain

Verify it's installed:

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### 2. Register App IDs

Go to **Certificates, Identifiers & Profiles** > **Identifiers** > click **+** to register a new App ID. Register two App IDs (one for the host app, one for the extension):

| Field | Host app | Extension |
|-------|----------|-----------|
| **Platform** | macOS | macOS |
| **Description** | `OpenRocket QuickLook Preview` | `OpenRocket QL Preview Extension` |
| **Bundle ID** | Select **Explicit**, enter `info.openrocket.ork` | Select **Explicit**, enter `info.openrocket.ork.qlpreview` |
| **Capabilities** | Leave all unchecked | Leave all unchecked |

No capabilities are needed for either App ID — just leave them all unchecked and click **Continue** > **Register**.

> The extension Bundle ID must be prefixed with the host app's Bundle ID (i.e. `info.openrocket.ork.qlpreview` starts with `info.openrocket.ork`). This is an Apple requirement for app extensions.

### 3. App-Specific Password for Notarization

Apple's notarization service requires an app-specific password (not your regular Apple ID password).

1. Go to [appleid.apple.com](https://appleid.apple.com) > **Sign-In and Security** > **App-Specific Passwords**
2. Generate a new password and save it somewhere secure

Then store it in your macOS Keychain so the `runit` script can use it non-interactively:

```bash
xcrun notarytool store-credentials "AppPwdNotarizID" \
  --apple-id "your@email.com" \
  --team-id YOURTEAMID \
  --password "xxxx-xxxx-xxxx-xxxx"
```

- Replace `your@email.com` with your Apple ID
- Replace `YOURTEAMID` with your 10-character Team ID (find it at [developer.apple.com/account](https://developer.apple.com/account) under **Membership Details**)
- Replace the password with the app-specific password you generated
- `"AppPwdNotarizID"` is the keychain profile name referenced by the `runit` script

---

## Info.plist Configuration

There are two Info.plist files in this repo. Both already exist — you do **not** need to create them. They must stay in sync with each other.

```
macOS-QuickLook-extension/
├── OpenRocket-QuickLook-Preview-Info.plist   <-- Host app Info.plist
└── OpenRocket QL Preview/
    └── Info.plist                             <-- Extension Info.plist
```

### Host App: `OpenRocket-QuickLook-Preview-Info.plist` (repo root)

This is the Info.plist for the host app target ("OpenRocket QuickLook Preview"). It declares the `.ork` Uniform Type Identifier (UTI) and document ownership. This is only used by Xcode during the build — it is **not** installed on end-user machines.

- **`UTExportedTypeDeclarations`** — Registers the UTI `info.openrocket.ork` and maps it to the `.ork` file extension
- **`CFBundleDocumentTypes`** — Tells macOS this app can open `info.openrocket.ork` files

### Extension: `OpenRocket QL Preview/Info.plist`

This is the Info.plist for the QuickLook extension target ("OpenRocket QL Preview"). It tells macOS which content types this extension can preview. This file **is** included in the final product (inside the `.appex` bundle).

- **`QLSupportedContentTypes`** — Lists `info.openrocket.ork` as the type this extension handles

### Critical: UTIs must match

The UTI string in the extension's `QLSupportedContentTypes` must **exactly match** the `UTTypeIdentifier` in the host app's `UTExportedTypeDeclarations`. Both must be `info.openrocket.ork`. A mismatch will cause QuickLook to silently ignore `.ork` files.

You generally do not need to edit these files. They are already configured correctly in the repo.

### These plists do NOT handle file association

These Info.plist files only exist for building and signing the QuickLook extension. They do **not** make `.ork` files open in OpenRocket when double-clicked. The `runit` script only copies the `Plugins/` folder into the install4j app — the host app's Info.plist is never installed.

For double-click file association (`.ork` → OpenRocket) **and** for QuickLook to work, the **install4j-built `OpenRocket.app`** must declare the same UTI and document types in its own Info.plist. See the [install4j Integration](#install4j-integration) section below.

---

## install4j Integration

install4j builds the main OpenRocket Java app but has no concept of QuickLook extensions. You need to configure two things in install4j for the QuickLook extension (and file association) to work on end-user machines.

### 1. Declare the UTI in the install4j app

The install4j-built `OpenRocket.app` is what actually gets installed on users' machines. It **must** declare the `.ork` UTI in its own Info.plist. Without this:
- macOS won't know that `.ork` files belong to OpenRocket (no double-click to open)
- QuickLook won't invoke the extension (it needs the UTI to be declared by an installed app)

Add the following to your install4j project's macOS launcher Info.plist configuration:

#### a) File association (CFBundleDocumentTypes)

install4j does not allow `CFBundleDocumentTypes` in custom Info.plist entries — it manages document types through its own UI. To configure it:

1. Go to **Launchers** (left sidebar)
2. Select your macOS launcher
3. Find the **File Associations** or **Document Types** section
4. Add a new association with:
   - **Extension:** `ork`
   - **Description:** `OpenRocket Data File`
   - **Role:** `Editor`
   - **UTI:** `info.openrocket.ork`
   - **Conforms to:** `public.data`

This generates the `CFBundleDocumentTypes` entry in the app's Info.plist automatically.

#### b) UTI declaration (UTExportedTypeDeclarations)

If install4j's file association UI does not have a UTI field, you need to add the UTI declaration manually. Go to **Launchers** > your macOS launcher > **macOS** tab > **Custom Info.plist entries** and add:

```xml
<key>UTExportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>info.openrocket.ork</string>
        <key>UTTypeConformsTo</key>
        <array><string>public.data</string></array>
        <key>UTTypeDescription</key>
        <string>OpenRocket Data File</string>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array><string>ork</string></array>
        </dict>
    </dict>
</array>
```

These entries end up in `OpenRocket.app/Contents/Info.plist` inside the final DMG.

### 2. Enable code signing and notarization in install4j

In your install4j macOS media file configuration:
- Enable **Code signing** with your **Developer ID Application** certificate
- Enable **Notarization** (provide your Apple ID, Team ID, and app-specific password)

The DMG that install4j produces will be modified by the `runit` script to include the QuickLook extension.

---

## Build Flow

### Step-by-step

```
1. install4j       --> Builds, signs, and notarizes OpenRocket.dmg
2. Xcode / runit   --> Builds the QuickLook host app + extension
3. runit            --> Notarizes and staples the .appex extension
4. runit            --> Injects the Plugins/ folder into the install4j DMG
5. runit            --> Produces a new read-only DMG
```

### 1. Build the install4j DMG

Build the standard OpenRocket macOS DMG using install4j with code signing and notarization enabled. Keep the resulting DMG file.

### 2. Configure Xcode signing

Open `OpenRocket QuickLook Preview.xcodeproj` in Xcode.

1. In the left sidebar (Project Navigator), click the **project file** at the very top — the blue icon labeled **OpenRocket QuickLook Preview**. This opens the project editor.
2. In the project editor's left column, look under **TARGETS**. You will see two targets:
   - **OpenRocket QuickLook Preview** (the host app)
   - **OpenRocket QL Preview** (the extension)
3. Click the first target (**OpenRocket QuickLook Preview**), then:
   - Select the **Signing & Capabilities** tab at the top of the editor
   - Set **Team** to your Apple Developer team
   - Set **Signing Certificate** to **Developer ID Application**
4. Click the second target (**OpenRocket QL Preview**) and repeat the same signing settings.

> You do not need to commit signing changes to git.

### 3. Configure the `runit` script

Open the `runit` script and set the three variables at the top (lines 7-9):

```sh
KEYCHAIN_PROFILE="AppPwdNotarizID"    # Keychain profile from store-credentials
ORIGINAL_DMG="/path/to/install4j/OpenRocket.dmg"  # install4j output DMG
MODIFIED_DMG="/path/to/output/OpenRocket-with-QL.dmg"  # Final output DMG
```

### 4. Run the script

Run the script from **Terminal** (not Xcode), in the repo's root directory:

```bash
cd /path/to/macOS-QuickLook-extension
./runit
```

The script performs these steps automatically:

1. **Archive** the Xcode project (builds + code signs using Developer ID)
2. **Compress** the `.appex` extension into a zip
3. **Notarize** the zip with Apple (waits for completion)
4. **Staple** the notarization ticket to the `.appex`
5. **Convert** the install4j DMG to a writable format
6. **Resize** the DMG to fit the additional plugin files
7. **Copy** the `Plugins/` folder into `OpenRocket.app/Contents/`
8. **Convert** back to a read-only DMG

### Building the Xcode project manually (optional)

If you want to build without the `runit` script:

**From Xcode:**
- Open the project, select the scheme, and press `Cmd+B`

**From Terminal:**

```sh
xcodebuild -target "OpenRocket QuickLook Preview" -configuration Release -scheme "OpenRocket QuickLook Preview"
```

Built app location: `build/DerivedData/Build/Products/Release/OpenRocket QuickLook Preview.app`

---

## Debugging

### Test the QuickLook extension

```bash
# Preview a file directly
qlmanage -p /path/to/file.ork

# List registered QuickLook plugins
qlmanage -m plugins

# Reset the QuickLook daemon (useful after reinstalling)
qlmanage -r
qlmanage -r cache
```

### Check Console logs

Open **Console.app** and filter for `quicklook` or `qlmanage` to see errors from the QuickLook subsystem.

### Common issues

| Problem | Cause | Fix |
|---------|-------|-----|
| QuickLook shows nothing for `.ork` files | UTI mismatch between host and extension Info.plists | Ensure `QLSupportedContentTypes` matches `UTTypeIdentifier` exactly |
| "not valid for use in process" error | Wrong signing certificate | Use **Developer ID Application**, not Apple Development |
| Notarization fails | Missing/expired app-specific password | Regenerate at appleid.apple.com and re-run `store-credentials` |
| Plugin not found after install | `Plugins/` folder not in the right location | Verify `OpenRocket.app/Contents/Plugins/OpenRocket QL Preview.appex` exists |
| Gatekeeper blocks the DMG | Final DMG not notarized | The `.appex` is notarized by the script; the DMG inherits notarization from install4j. If modified DMG is blocked, notarize it separately (see below) |

### Notarizing the final DMG (if needed)

If Gatekeeper blocks the modified DMG, you may need to notarize it after the merge:

```bash
xcrun notarytool submit /path/to/modified.dmg --keychain-profile "AppPwdNotarizID" --wait
xcrun stapler staple /path/to/modified.dmg
```

---

## Summary

- **install4j** builds and notarizes the main OpenRocket Java app as a DMG
- **Xcode** builds the QuickLook host app (which contains the `.appex` extension)
- **`runit`** bridges the gap: it signs, notarizes, and merges the extension into the install4j DMG
- The install4j app's `Info.plist` must declare the `info.openrocket.ork` UTI so macOS associates `.ork` files with the app
- The final result is a Gatekeeper-clean DMG with a working QuickLook preview for `.ork` files
