# Start here — build XM6 Wrist online for free from Windows

This is a watch-only app project with a read-only Sony Bluetooth diagnostic. It **does not** control ANC, ambient sound, or EQ yet.

## What is free
- GitHub Actions uses a real Mac to compile the watchOS app. GitHub's **standard macOS runners for PUBLIC repositories** are free and unlimited, subject to GitHub's normal abuse/policy limits.
- A free GitHub account is sufficient to try compiling.
- **No macOS VM, Xcode install on Windows, or Apple Developer Program payment is required to compile.**

## What it does *not* do
- It creates an **unsigned Simulator build**, which **cannot be installed on a real Apple Watch**. A green check means the code compiled, not that Sony settings can be controlled.
- For real-device testing, the app needs Apple signing and a physical-watch installation path. Direct Xcode device installation generally requires access to a Mac. TestFlight is an alternative for watch-only apps, but requires the paid Apple Developer Program.
- The CoreBluetooth probe cannot test Sony's Bluetooth services in a remote cloud simulator.

## On your Windows PC — GitHub Desktop, no command line needed
1. Download/unzip the project. You should see `XM6Wrist.xcodeproj`, `XM6Wrist`, `README.md`, and a hidden-style folder named `.github` in the **same project folder**. Don't upload the zip itself as the repository content.
2. Create/sign in to your account at https://github.com/ (free).
3. Install **GitHub Desktop for Windows** from https://desktop.github.com/ and sign in.
4. In GitHub Desktop use **File > Add local repository**, click **Choose**, and select the unzipped `XM6Wrist_GitHub_Free_Build` folder. If it says it is *not* a Git repository, click **Create a repository here** and accept.
5. If your changed files appear under **Changes**, enter a summary such as `Add watchOS project and cloud build` and click **Commit to main**.
6. Click **Publish repository**. **Uncheck "Keep this code private"** to use the unlimited free public-repository runner. IMPORTANT: a public repo exposes all project files to everyone; there should be no passwords, credentials, personal data or diagnostic reports in this project.
7. In your browser open your new repository, select the **Actions** tab, and choose **XM6 Wrist - free watchOS build**. If GitHub asks to enable Actions, enable workflows for this repository.
8. A build should start after publishing the first commit. If not, press **Run workflow** and select **Run workflow** again.
9. Open the run, then the `build-watchos` job. A **green check** means the code compiled. A **red X** means a build step failed; copy the error messages or download **XM6Wrist-build-log** from the run's **Artifacts** section and share it in ChatGPT so the project can be fixed.

## Workflow file
`.github/workflows/watchos-build.yml` is the automation. Keep the leading dot in `.github` and don't move it.

## Why the watch cannot be tested online
GitHub Actions' cloud Mac has no Bluetooth path to your own nearby earbuds and is not directly paired to your Apple Watch. Even successful remote compilation is not equivalent to installing the Bluetooth probe on the physical watch. Hardware testing remains a separate task.
