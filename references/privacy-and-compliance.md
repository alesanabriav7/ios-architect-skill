# Privacy and Compliance

Use this file for privacy manifest setup, App Store compliance, and data handling requirements.

## PrivacyInfo.xcprivacy Template

Add `PrivacyInfo.xcprivacy` to the app target's root. Declare every Required Reason API the app calls directly.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <!-- File timestamp -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <!-- Disk space -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>E174.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

Reason codes used above:

- `CA92.1` — access UserDefaults to read/write app-specific data.
- `C617.1` — access file timestamps for files inside the app container.
- `E174.1` — check available disk space before writes.

Only include API categories the app actually uses. Remove entries that do not apply.

## Privacy Nutrition Labels

Declare collected data types in App Store Connect under **App Privacy**.

- List every data type collected (name, email, usage data, diagnostics, etc.).
- For each type specify the purpose: **App Functionality**, **Analytics**, **Product Personalization**, **Third-Party Advertising**, or **Other Purposes**.
- Mark each type as **Linked to User** (tied to account/identity) or **Not Linked to User** (anonymous/aggregated).
- Mark whether the data is **Used to Track** the user across apps/websites owned by other companies.
- If the app collects no data at all, select **Data Not Collected**.

Update labels whenever a new SDK or feature changes the data the app handles. Inaccurate labels trigger App Review rejection.

## Account Deletion Requirement

If the app supports account creation it must also support account deletion.

- Provide an in-app path to initiate deletion (Settings or profile screen).
- Complete deletion of personal data within a reasonable time (Apple guideline: 14 days maximum for backend cleanup).
- Clearly explain what happens to the user's data before they confirm.
- If the app uses **Sign in with Apple**, revoke the token on deletion:

```swift
import AuthenticationServices

func revokeAppleSignInToken(_ authorizationCode: String) async throws {
    let provider = ASAuthorizationAppleIDProvider()
    // The authorization code comes from the initial sign-in credential.
    // Exchange it for a refresh token on your server, then call revoke.
    try await provider.revokeToken(withAuthorizationCode: authorizationCode)
}
```

- Test the full deletion flow end-to-end before submission.

## Third-Party SDK Privacy Manifests

Every third-party SDK must ship its own `PrivacyInfo.xcprivacy` declaring the Required Reason APIs it uses.

- Xcode aggregates all privacy manifests at build time into a single privacy report.
- Generate the report: **Product > Generate Privacy Report** in Xcode.
- Review the aggregated report to verify no undeclared API usage.
- When adding a new dependency (SPM, CocoaPods, XCFramework), confirm the SDK includes a privacy manifest. If it does not, file an issue with the SDK maintainer.
- XCFrameworks must be signed. SPM packages must include a signature or come from a trusted source.

## Submission Checklist

- [ ] Privacy policy URL set in App Store Connect.
- [ ] Privacy nutrition labels completed and accurate.
- [ ] Required Reason APIs declared in `PrivacyInfo.xcprivacy`.
- [ ] Third-party SDK privacy manifests included (run **Generate Privacy Report**).
- [ ] SDK signatures verified (XCFramework signed, SPM packages with valid signature).
- [ ] Account deletion flow tested end-to-end (if account creation exists).
