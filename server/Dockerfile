FROM node:20-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list \
    -o /etc/apt/sources.list.d/dart_stable.list \
    && curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /usr/share/keyrings/dart-archive-keyring.gpg \
    && sed -i 's#deb https://storage.googleapis.com/download.dartlang.org/linux/debian stable main#deb [signed-by=/usr/share/keyrings/dart-archive-keyring.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main#g' /etc/apt/sources.list.d/dart_stable.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends dart \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json ./
COPY run_dart_server.js ./

ENV PORT=8080
EXPOSE 8080

CMD ["node", "run_dart_server.js"]
