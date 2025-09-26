## Flutter Docker Images 🚀🐳

Prebuilt Docker images for consistent Flutter Android builds on CI and local machines. Each image bundles Ubuntu 22.04, OpenJDK 17, Android SDK/NDK, CMake, and a pinned Flutter SDK version.

### Why ✨
- ✅ **Reproducible builds**: Avoid local SDK drift and OS differences
- ⚡ **Fast CI**: Images are tagged and versioned; CI can build and push automatically
- 🔢 **Multi-version**: Maintain multiple Flutter versions in parallel (e.g., 3.24.2, 3.27.0)

### Repository layout 🗂️
```
flutter-docker-images/
  flutter-3.24.2/
    Dockerfile
    versions           # monotonically increasing image version used by CI
  flutter-3.27.0/
    Dockerfile
    versions
  .circleci/config.yml # CI workflow to build/push images and bump versions
```

---

## Available image variants 🧩

- 🎯 **`flutter-3.24.2`**
  - Android SDK packages: build-tools 30.0.3, NDK 23.1.7779620, CMake 3.18.1
  - Platforms: android-33, android-34, android-35

- 🎯 **`flutter-3.27.0`**
  - Android SDK packages: build-tools 35.0.1, NDK 29.0.13846066, CMake 3.22.1
  - Platforms: android-34, android-35, android-36

📦 All images are based on Ubuntu 22.04 and include: curl, git, unzip, xz-utils, zip, libglu1-mesa, wget, OpenSSH client, Ruby toolchain, build-essential, sed, gnupg, and OpenJDK 17.

---

## Image tags and versioning 🏷️

Each directory contains a `versions` file with a single integer. The CI pipeline:
- 🔎 Reads the current value N
- 🏗️ Builds the image
- 🚢 Pushes two tags: `latest` and `<N+1>`
- ✍️ Commits the bump by writing `<N+1>` back to the `versions` file in a PR

🐳 Resulting tags on Docker Hub (examples):
- `your-dockerhub-username/flutter-3.27.0:latest`
- `your-dockerhub-username/flutter-3.27.0:5` (numeric build tag)

---

## Pull and use the images ⬇️

Replace `your-dockerhub-username` with your Docker Hub account.

```bash
docker pull your-dockerhub-username/flutter-3.27.0:latest
docker run --rm -it \
  -v "$PWD":/app \
  -w /app \
  your-dockerhub-username/flutter-3.27.0:latest \
  bash -lc "flutter --version && dart --version"
```

📦 Typical Android build (APK):
```bash
docker run --rm -it \
  -v "$PWD":/app \
  -w /app \
  your-dockerhub-username/flutter-3.27.0:latest \
  bash -lc "flutter pub get && flutter build apk --release"
```

📦 For AAB:
```bash
docker run --rm -it \
  -v "$PWD":/app \
  -w /app \
  your-dockerhub-username/flutter-3.27.0:latest \
  bash -lc "flutter pub get && flutter build appbundle --release"
```

🌐 Web builds (optional):
```bash
docker run --rm -it \
  -v "$PWD":/app \
  -w /app \
  your-dockerhub-username/flutter-3.27.0:latest \
  bash -lc "flutter config --enable-web && flutter pub get && flutter build web"
```

---

## Build images locally 🛠️

📍 From repo root:
```bash
# Build 3.27.0 locally
docker build -f flutter-3.27.0/Dockerfile -t flutter-3.27.0:local .

# Build 3.24.2 locally
docker build -f flutter-3.24.2/Dockerfile -t flutter-3.24.2:local .
```

Run the local image:
```bash
docker run --rm -it -v "$PWD":/app -w /app flutter-3.27.0:local bash
```

---

## CI/CD (CircleCI) 🤖

The workflow in `.circleci/config.yml` provides jobs to build and push each image and then open a PR that bumps the `versions` file. Branch filters are used to scope builds:

- 🧭 Push to branch `build-flutter-3.24.2` → builds `flutter-3.24.2`
- 🧭 Push to branch `build-flutter-3.27.0` → builds `flutter-3.27.0`
- 🧭 Push to branch `test` → runs a lightweight test job

### Required environment variables (CircleCI project) 🔐
- `DOCKERHUB_USER`: Docker Hub username
- `DOCKERHUB_PASS`: Docker Hub password or access token
- `GITHUB_ACCESS_TOKEN`: Token with `repo` scope to push branches and open PRs

### What the CI does ✅
1. Logs in to Docker Hub
2. Builds the image and tags as `latest` and `<new_version>`
3. Pushes tags to Docker Hub
4. Creates a branch, commits updated `versions`, and opens a PR against `main`

---

## Adding a new Flutter version ➕

Grant this pre-configured script permission to run:
```bash
chmod +x scripts/add_flutter_version.sh
```

Use the helper script to scaffold everything:
```bash
bash scripts/add_flutter_version.sh 3.29.0
# or interactively (will prompt for version):
bash scripts/add_flutter_version.sh
```

What this does:
- Creates `flutter-<version>/` with a `Dockerfile` copied from the latest existing folder
- Updates `ENV FLUTTER_VERSION=<version>` inside that `Dockerfile`
- Creates `flutter-<version>/versions` with a single line: `0`
- Appends a new CI job in `.circleci/config.yml` for branch `build-flutter-<version>`
- Creates and checks out a git branch `build-flutter-<version>` (no commit is made)

After running:
1. Review `flutter-<version>/Dockerfile` and adjust Android SDK packages if needed
2. Review diffs: `git status && git diff`
3. Commit when ready: `git add flutter-<version> .circleci/config.yml && git commit -m "Add flutter-<version> image and CI job"`
4. Push the branch to trigger CI: `git push -u origin build-flutter-<version>`

---

## Notes and caveats ⚠️

- These images are intended for building artifacts (APK/AAB) and running Flutter CLI tools. Running Android emulators within Docker is not supported here.
- `JAVA_HOME` is dynamically resolved during image build and exported for use by Android tooling.
- `flutter precache` is executed during build to speed up first runs.

---

## License 📄

Code in this repository is provided under your chosen license. If unspecified, consider adding a license file (e.g., MIT) at repository root.


