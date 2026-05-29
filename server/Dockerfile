# Dedicated multiplayer server: Godot 4.6 headless running res://Server.tscn.
# This speaks Godot's native WebSocket multiplayer protocol (scripts/Net.gd),
# so it must be the same Godot engine the client is built with.
FROM debian:bookworm-slim

ENV GODOT_VERSION=4.6-stable
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Download the Godot headless (Linux) binary.
RUN curl -L -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && unzip /tmp/godot.zip -d /usr/local/bin \
    && mv "/usr/local/bin/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

WORKDIR /app
COPY . /app

# Render injects PORT; Net.gd reads it (defaults to 10000 locally).
ENV PORT=10000
EXPOSE 10000

# Import resources once, then boot the dedicated server scene.
CMD ["sh", "-c", "godot --headless --path /app --import || true; godot --headless --path /app res://Server.tscn"]
