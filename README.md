# The Ruins That Breathe

An isometric Godot 4.6 action game with singleplayer and room-based co-op multiplayer,
a shared Haven hub, a class/shop system, and procedurally generated levels.

## Features

- Singleplayer and Multiplayer start options (name + room code).
- Room-based co-op over WebSockets (`scripts/Net.gd`), shared map seed per room.
- Shared Haven: press `H` to enter, `Y` to return to your level (synced for the room).
- Start each run with 1 random class of 5; buy the others in the Haven shop for 100 coins.
- 2x larger maps, normal combat rooms with 5 waves, and an 8-wave boss/portal room.
- Red isometric tile telegraphs for blocked tiles and incoming attacks.
- `R` switches music (scans `assets/audio/`), `Z` shows the controls overlay.

## Controls

| Key | Action |
|-----|--------|
| LMB | Move |
| RMB | Attack / hold to charge |
| 1-9 | Switch class |
| E / Q | Pick up / drop weapon |
| H / Y | Enter Haven / return to level |
| R | Switch music track |
| G | Ping objective |
| T | Toggle map |
| Z | Toggle controls overlay |

## Run locally (Godot editor)

1. Open the project in Godot 4.6.
2. Press Play. Click `SINGLEPLAYER` to start a run.

### Test multiplayer locally

Open a terminal in the project folder.

1. Start the dedicated server:
   ```
   godot --headless --path . res://Server.tscn
   ```
   (or `godot --headless --path . -- --server`). It listens on `ws://127.0.0.1:10000`.
2. Launch two game instances (two editor runs, or two exported builds). On each:
   - Click `MULTIPLAYER`, enter a display name and the SAME room code, then `JOIN ROOM`.
   - Both players appear in the same seeded world. Same room code = same session;
     different codes never see each other.

The client picks the server URL automatically:
- In the editor / local: `multiplayer_server_url` (default `ws://127.0.0.1:10000`).
- In exported / web builds: `multiplayer_server_url_production` (set this to your Render URL).
- Override anywhere with the `MULTIPLAYER_SERVER_URL` environment variable.

## Music

Drop any `.wav`, `.ogg`, or `.mp3` files into `assets/audio/`. They are auto-added to the
in-game playlist; press `R` during play to cycle tracks.

## Deploy the multiplayer server on Render (Docker)

The server is Godot headless in a container (it speaks Godot's WebSocket protocol).

1. Push this repo to GitHub.
2. In Render: New + > Blueprint, point it at the repo. `render.yaml` defines the services.
   - Or create a Web Service manually: Runtime = Docker, Dockerfile path = `server/Dockerfile`.
3. Render sets `PORT` automatically; `scripts/Net.gd` reads it and binds `0.0.0.0:$PORT`.
4. Environment variables:
   - `MAX_PLAYERS_PER_ROOM` (optional, default 24).
5. After it deploys you get a URL like `https://ruins-multiplayer-server.onrender.com`.
   The WebSocket URL is the same host with `wss://`:
   `wss://ruins-multiplayer-server.onrender.com`.

### Put the server URL into the game

In the Godot editor, select the root `World` node in `world.tscn` and set:
- `Multiplayer > Multiplayer Server Url Production` = `wss://YOUR-APP.onrender.com`

(You can also set the `MULTIPLAYER_SERVER_URL` env var to override at runtime.)

## Deploy the game as a static website

1. Install the Godot Web export templates (Editor > Manage Export Templates).
2. Export the Web preset (already defined in `export_presets.cfg`) to the `web/` folder:
   - Editor: Project > Export > Web > Export Project, output `web/index.html`.
   - CLI: `godot --headless --path . --export-release "Web" web/index.html`
3. Commit the generated `web/` folder.
4. Render: the `ruins-web` static service in `render.yaml` serves `web/`.
   - Or any static host (GitHub Pages, Netlify, Cloudflare Pages) pointed at `web/`.

The Web preset disables threads, so no special COOP/COEP headers are required.
If you re-enable `thread_support`, add the headers in `web/_headers` (and uncomment the
header block in `render.yaml`).

## Push to GitHub

```
git init
git add .
git commit -m "The Ruins That Breathe: MP, Haven, classes, deploy"
git branch -M main
git remote add origin https://github.com/YOUR-USER/YOUR-REPO.git
git push -u origin main
```

## Confirm multiplayer works after deployment

1. Open the deployed static site URL in two browser tabs (or two devices).
2. In each: `MULTIPLAYER` > same name-distinct, same room code > `JOIN ROOM`.
3. You should see each other moving in the same world. Press `H` together to share the Haven,
   `Y` to return.

## Project layout

- `scripts/world.gd` - main game controller (movement, HUD, waves, map, music, menus).
- `scripts/Net.gd` - WebSocket server + client (rooms, names, seeds, sync). Autoload `Net`.
- `Server.tscn` / `scripts/Server.gd` - dedicated server scene.
- `scripts/weapons/WeaponManager.gd` - class catalog, hotbar, purchases.
- `scripts/managers/SaveManager.gd` - coins + owned classes persistence.
- `server/Dockerfile`, `render.yaml` - deployment.
- `export_presets.cfg` - Web export preset.
