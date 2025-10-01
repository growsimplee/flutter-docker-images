FROM ubuntu:22.04

# 1. Install required system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl git unzip xz-utils zip libglu1-mesa wget openssh-client \
  ruby ruby-dev build-essential sed gnupg openjdk-17-jdk && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Dynamically set JAVA_HOME
RUN JAVA_PATH=$(readlink -f $(which java)) && \
    JAVA_HOME=$(dirname $(dirname "$JAVA_PATH")) && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "PATH=$JAVA_HOME/bin:$PATH" >> /etc/environment && \
    export JAVA_HOME=$JAVA_HOME && export PATH=$JAVA_HOME/bin:$PATH && \
    echo "Resolved JAVA_HOME=$JAVA_HOME"

# 3. Set environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# 4. Install Android SDK Command Line Tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip && rm tools.zip && \
    mv cmdline-tools latest

# 5. Install SDK packages first (triggers license generation)
RUN yes | sdkmanager \
    "platform-tools" \
    "build-tools;34.0.0" \
    "build-tools;35.0.1" \
    "ndk;29.0.13846066" \
    "cmake;3.22.1" \
    "platforms;android-34" \
    "platforms;android-35" \
    "platforms;android-36"

# 6. Accept all SDK licenses AFTER installing packages
RUN yes | sdkmanager --licenses

# 7. Install Flutter SDK
ENV FLUTTER_VERSION=3.35.4
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${PATH}:${FLUTTER_HOME}/bin"

RUN git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION $FLUTTER_HOME && \
    flutter doctor --android-licenses && \
    flutter precache && \
    flutter doctor

# 8. Set working directory
WORKDIR /app