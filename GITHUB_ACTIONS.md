# GitHub Actions Workflow Documentation

## Build and Release APK Workflow

This repository includes an automated GitHub Actions workflow that builds a release APK from your Flutter project and publishes it to GitHub Releases.

### Workflow File Location
`.github/workflows/build-and-release.yml`

### How It Works

#### Automatic Triggers

1. **Push to main branch**: Every push to the `main` branch will:
   - Build a release APK
   - Create a pre-release in GitHub Releases
   - Tag it as `v{version}-build-{commit-sha}`

2. **Version tags**: Pushing a git tag starting with `v` (e.g., `v1.0.0`, `v2.1.3`) will:
   - Build a release APK
   - Create an official release with that tag
   - Not marked as pre-release

3. **Manual trigger**: You can manually run the workflow from the Actions tab

#### Build Process

The workflow performs these steps:
1. Checks out the repository code
2. Sets up Java 17 (required for Android builds)
3. Sets up Flutter 3.24.5 (stable channel)
4. Installs Flutter dependencies (`flutter pub get`)
5. Builds the release APK (`flutter build apk --release`)
6. Extracts version information from `pubspec.yaml`
7. Uploads the APK as a workflow artifact (retained for 90 days)
8. Creates a GitHub Release with the APK attached

### Using the Workflow

#### Option 1: Automatic Build on Main Branch Push
Simply push your changes to the `main` branch:
```bash
git add .
git commit -m "Your commit message"
git push origin main
```

This will create a pre-release with the APK attached.

#### Option 2: Create a Tagged Release
To create an official release, tag your commit and push:
```bash
# Update version in pubspec.yaml first (e.g., version: 1.2.0+3)
git add pubspec.yaml
git commit -m "Bump version to 1.2.0"
git tag v1.2.0
git push origin main
git push origin v1.2.0
```

#### Option 3: Manual Workflow Trigger
1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. Select "Build and Release APK" from the workflows list
4. Click "Run workflow"
5. Select the branch to build from
6. Click "Run workflow" button

### Finding Your APK

After the workflow completes successfully:

1. Go to the "Releases" section of your repository
2. Find the latest release (either tagged or automatic build)
3. Download the `app-release.apk` file from the Assets section
4. Install it on your Android device (requires Android 9.0 Pie or higher)

### Workflow Artifacts

In addition to GitHub Releases, the workflow also uploads APK files as workflow artifacts:
- Go to Actions tab → Select a workflow run → Scroll to "Artifacts" section
- Download the artifact named `usaapp-release-{version}`
- Artifacts are retained for 90 days

### Release Information

Each release includes:
- **Version**: Extracted from `pubspec.yaml`
- **Build commit**: Short SHA of the commit that triggered the build
- **Date**: Timestamp of the commit
- **Changes**: Commit message
- **Installation instructions**: How to install the APK
- **Feature list**: Key features of the app

### Requirements

- The workflow requires no secrets or special configuration
- It uses the default `GITHUB_TOKEN` provided by GitHub Actions
- The app is signed with debug keys (suitable for testing, not production distribution)

### For Production Releases

If you want to sign the APK with production keys for Google Play Store distribution:
1. Generate a keystore file
2. Add the keystore as a repository secret
3. Update the workflow to use the production keystore
4. Modify `android/app/build.gradle.kts` to use release signing config

### Troubleshooting

If the workflow fails:
1. Check the Actions tab for error logs
2. Common issues:
   - Flutter dependency issues: Run `flutter pub get` locally to verify dependencies
   - Build configuration errors: Check `android/app/build.gradle.kts`
   - Permission issues: Verify `GITHUB_TOKEN` has necessary permissions

### Customization

You can customize the workflow by editing `.github/workflows/build-and-release.yml`:
- Change Flutter version
- Modify Java version
- Add additional build steps
- Change artifact retention period
- Modify release notes template
