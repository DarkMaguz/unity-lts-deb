FROM debian:bullseye

RUN apt-get update
RUN apt-get install -y curl wget libxml2-utils xdg-utils jshon xz-utils coreutils \
  gconf-service lib32gcc-s1 lib32stdc++6 libasound2 libc6 libc6-i386 \
  libcairo2 libcap2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
  libfreetype6 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libgl1-mesa-glx \
  libglib2.0-0 libglu1-mesa libgtk2.0-0 libnspr4 libnss3 libpango1.0-0 \
  libstdc++6 libx11-6 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
  libxfixes3 libxi6 libxrandr2 libxrender1 libxtst6 zlib1g

RUN apt-get install -y gpg

# Add CPOS deb repo to get the current version of Unity.
RUN echo "deb [arch=amd64] https://darkmagus.dk/cpos/repo/ /" > /etc/apt/sources.list.d/cpos.list
RUN wget -q -O - https://darkmagus.dk/cpos/repo/CPOS.gpg | apt-key add -

RUN mkdir -p /build
WORKDIR /build

ENTRYPOINT ["./docker-run.sh"]
