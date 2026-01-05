This project creates a QuickLook Preview for the OpenRocket project.

1) What Install4j does for the primary OpenRocket app

The Mac OpenRocket application is build with Install4j, which code signs the application.
From the Install4j documentation:

Code signing ensures that the installer, uninstaller and launchers can be traced back to a particular vendor.
A third party certificate authority guarantees that the signing organization is known to them and has been checked
to some extent. The certificate authority has the ability to revoke a certificate in case it gets compromised.

The basis for code signing is a public and private key pair that you generate on your computer. The private key
is only known to yourself, and you never give it to anyone else. The certificate provider takes your public key
and signs it with its own private key. That key, in turn, is validated by an official root certificate that is
known to the operating system. The private key, the public key and the certificate chain provided by the certificate
provider are all required for code signing.

Code signing is important for installers on Windows and macOS. For unsigned applications that require admin privileges,
a window will display special warning dialogs to alert the user that the application is untrusted and may harm the computer.
Also, the SmartScreen filter will make it very difficult for the user to execute unsigned executables.

On macOS, the Gatekeeper prevents non-expert users from installing an unsigned application that was marked as downloaded
from the internet, so code signing is practically required.

Install4j also notarizes the application. Again, from its documetation:

Apple offers a service that checks DMGs for security problems and adds them to their database. This is called
"notarization" and is required starting with macOS 10.15. The exact steps for notarizing your application are
described on the Apple developer web site.

However, Apple will only notarize applications that follow certain guidelines. The "hardened runtime" has to be enabled,
which install4j automatically does for you by adding the appropriate entries to the entitlements file. Also, all binaries
in the DMG have to be signed. This also concerns binaries that are in a ZIP archive. Because JAR files are ZIP archives,
the notarization process can detect binaries in JAR files. Some popular frameworks and libraries, such as SWT or JNA, ship
native binaries in their JAR files. These contained binaries have to be signed as well.

For this purpose, install4j lets you configure a list name pattern for binaries. All files in the distribution tree are
matched against these patterns, and if a match is found, the corresponding file is signed if it is really a MACH-O binary.
The reason why install4j cannot just automatically check all files in this way is that this check is rather expensive.

In addition, you can configure a list of name patterns for JAR files that should be scanned for binaries with the above
name patterns. This only works for unsigned JAR files because the modification introduced by the signature would
break the signature of a signed JAR file and install4j has no way of regenerating that signature.

The actual notarization of a media file is performed by uploading it with the App Store Connect API to Apple while identifying
yourself with an API key generated for an account matching the code signing certificate. If the app passes the inspection,
install4j "staples" the notarization signature to the DMG. Stapling is only necessary if a macOS machine is offline and cannot
verify the notarization of an app by connecting to the internet.

In the install4j IDE, notarization must be enabled on the "General Settings->Code signing" step and an App Store Connect
API team key ID, issuer and private key file has to be entered. The access role of the key must be "Developer".
You can generate API keys on the Apple App Store Connect website.

Reference for Install4j:
  https://www.ej-technologies.com/resources/install4j/help/doc/concepts/codeSigning.html
Reference for the general process:
  https://dennisbabkin.com/blog/?t=how-to-get-certificate-code-sign-notarize-macos-binaries-outside-apple-app-store


2) Why is this project and script necessary?

Apple requires all executables (ie plugins) to be code signed. While not strictly necessary, notarization of them removes the
need for users to allow their use by finding them in the Settings app and manually enabling them.

Since Install4j cannot handle app plugins, it's necessary to code sign and notarize the plugins via some other path,
then copy the signed plugin into an existing Install4j produced DMG. The script "runit" does this, and is described below.


3) The "runit" script

Before running the script, select the Project file (top left), then for each target set the "Team" account in "Signing & Capacities",
and the "Certificate" should be "Developer ID Application". You don't need to save and commit changes.

Required:
- create a "Developer ID Application" Certificate on developer.apple.com if you don't already have it (see Reference 2)
- create an App-Specific password for use with the notarization scripts (to avoid exposing your password in clear text)
  see above Reference 2 or https://support.apple.com/en-us/102654

Add the password to your keychain (see above Reference 2) - this is what I did (my id, my team-id)
  $ xcrun notarytool store-credentials "AppPwdNotarizID --apple-id "dhoerl@mac.com" --team-id 748Z47NBAH --password "<the app specific one>",

Open "runit" in a separate tab, and fill in the 3 shell variables:
There is a command line script "runit" (shown on left). You need to set the three variables lines 3-5:
  KEYCHAIN_PROFILE  # The identifier for your app specific password as provided in the above xcrun for "store-credentials"
  ORIGINAL_DMG      # the full path to the original DMG
  MODIFIED_DMG      # the full path (and name) for the updated DMG to be located

Once done, then in Terminal:
- cd to the Project directory (where "runit) is located
- execute "./runit"

To understand what "runit" is doing, view it in Xcode (it's listed in the left pane)
