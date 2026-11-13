# Street Rush — Unity Game Design & Master Prompt

Wheel Smart Studio · 13 Nov 2026

This document describes the whole game as it exists in the web/Android prototype (`game/index.html`, `apk/StreetRush.apk`) and how to rebuild it properly in Unity. Part 10 is a single prompt you can paste into an AI coding assistant (Claude Code, Cursor, etc.) inside a Unity project.

> **Art note.** The goal is the *feel* of a bright, tropical-island mobile battle-royale map (lush grass, warm dirt roads, sunny sky, chunky stylised props). Garena's Free Fire / Bermuda assets, textures, map layout and names are copyrighted and must not be extracted, copied or traced. Use original assets or assets you have a licence for (Unity Asset Store, Synty POLYGON packs, Kenney, Quixel, your own Blender work).

---

## 1. Overview

| | |
|---|---|
| Title | **Street Rush** |
| Studio | Wheel Smart Studio |
| Genre | Arcade car game: drifting + capture the flag |
| Platforms | Android first (min Android 7 / API 24), iOS later |
| Players | 1 (Solo Drift) or 2–4 online (Team Code) |
| Session length | 10 rounds, about 4–8 minutes |
| Engine | Unity 6 LTS, Universal Render Pipeline (URP) |

**Pitch.** A flag stands at the centre of the map. Each player has a base on the edge of the map in their car colour. After a 10-second countdown everyone races to the flag. The first car to touch it carries it. Ram the carrier and the flag jumps to your car. Drift through the streets, shake off chasers and drop the flag in your own base to score. Bases move every round. Most points after 10 rounds wins.

---

## 2. Core gameplay

### Match rules
1. **Rounds:** 10 per match. There is no time limit.
2. **Countdown:** each round starts with a **10-second countdown**. Cars are frozen at their spawn while it runs. The last 3 seconds beep, then "GO!".
3. **Flag pickup:** the flag sits on a stand at the map centre (temple in Village, centre circle in City). The **first car to touch it** (within 3 m) gets the flag, which attaches to the car's rear roof.
4. **Steal (dash):** if any other car touches the carrier (cars within about 4.2 m), the flag **instantly moves to that car**. Steals can repeat any number of times. After each steal the flag can't be stolen again for **1.2 s**, so it doesn't flicker between two touching cars.
5. **Capture:** the carrier drives into **their own base** (a 6.5 m radius circle in their car colour). The flag plants there and the player scores **+1**. The round ends with a 3.5 s celebration.
6. **Next round:** everyone respawns at a **new base location** (see Maps), the flag resets to the centre and a new countdown starts.
7. **Win:** after round 10, the highest score wins. Equal top scores show **DRAW**. The result screen lists everyone's points.
8. **Car colours:** slot 1 orange `#FF6A0A`, slot 2 blue `#2F7BFF`, slot 3 green `#22C55E`, slot 4 magenta `#D23BD8`. Each base, its light beam, its pennant and its name tag use the owner's colour.

### Solo Drift
The same rules with only your car: 10 flags, then a result screen with your total time ("10 flags in 3:42"). It is used for practice and for drifting around freely.

### Feedback players must always get
- Objective text under the speedometer: "GRAB THE FLAG", "TAKE THE FLAG TO YOUR BASE" or "DASH ‹name› TO STEAL THE FLAG".
- A tall gold light beam above the flag wherever it is (hidden on your own screen while you carry it).
- A coloured light beam and floating name tag above every base.
- Popups: "GOT THE FLAG!", "FLAG STOLEN!", "FLAG LOST — ‹name› dashed you", "‹NAME› SCORES", "POINT!".
- **No navigation arrow** above the car (removed on purpose). The minimap is the navigation aid.

---

## 3. Maps

Both maps are open street arenas (not a straight track), sized about 400–500 m square, with an invisible boundary wall drawn as a painted line on the ground.

### Village Roads
- **Ground:** lush, varied grass everywhere, with large-scale colour variation so tiling is never visible.
- **Roads:** mud/dirt roads on a 5×5 street network about 12 m wide. Intersections are jittered so streets bend. Some interior streets are removed, which creates lanes and dead ends. Roads blend softly into the grass and show tyre ruts and pebbles.
- **Centre:** a dirt village ground with a **South-Indian style temple** (stone plinth, white shrine, stepped coloured gopuram tower, gold kalasam, a flagpole in front). The flag stand is in front of the temple.
- **Houses:** up to **3 houses per street**, facing the road: tiled-roof houses, flat-roof RCC houses (some two-storey, some with a black water tank on top) and round thatched huts. Walls are plastered in pastel colours. Houses are solid colliders and are never placed on a base spot, a spawn, the temple ground or another road.
- Nothing else: no trees, poles or props on the playable area.

### City Streets
- **Ground:** large paved concrete slabs with seams, stains and cracks.
- **Roads:** a 6×6 grid of tar roads 18 m wide: two lanes each way, a yellow double centre line, white dashed lanes and edge lines, and zebra crossings at every junction.
- **Centre:** a painted centre circle with the flag stand.
- No buildings on the playable area (roads and ground only).

### Base spots (both maps)
- **12 base spots per map**, all on the outer ring road: 3 per side (middle, left, right). Each spot has an inward direction toward the centre.
- At the start of **every round** the host picks a spot for each player, keeping chosen spots **at least 150 m apart**, and sends the choice to everyone.
- Each car spawns 14 m inward from its base, facing the centre.

### Minimap
A round minimap in the top-left corner that rotates with the player and shows roads, houses, bases in their colours, other players as coloured dots, the flag as a gold flag icon and you as an arrow in your colour.

---

## 4. Cars and driving

### Handling model (arcade, not simulation)
Use a **custom raycast-suspension controller on a Rigidbody**, not WheelColliders. It is more stable on mobile and easier to tune for drifting.
- 4 suspension raycasts with spring and damper forces. Wheel meshes follow the ray hit points.
- Split velocity into forward and lateral parts. Lateral grip is high when gripping (about 9/s), drops when sliding (about 2.4/s) and is very low with the handbrake (about 0.9/s).
- Some of the lateral speed lost turns into forward speed, which keeps drifts fast.
- Top speed about 80 m/s (≈290 km/h). Acceleration falls off near top speed. Brake and reverse are capped at −15 m/s.
- Steering eases in, and its strength is reduced at high speed. The handbrake multiplies yaw rate by 1.7 above 8 m/s.
- An automatic 6-speed gearbox drives the engine sound and the HUD gear display.

### Collisions
- **Car vs car and car vs wall: no bounce.** Remove the velocity into the contact (restitution ≈ 0), apply small extra damping (about 3–6 %), and separate the cars by half the overlap each. Cars must not be thrown far.
- Strong hits give camera shake, a thump sound and a light screen flash.
- Temple, houses and the boundary are static colliders.

### Drift animation and effects (when slip > 3.5 m/s at speed > 10 m/s)
- Body leans outward up to about 8.5° (more than in normal cornering).
- The front wheels visually counter-steer toward the slide.
- **Light trails** in the car's colour come from both rear wheels (additive ribbons, about 0.55 s long).
- Tyre smoke on tarmac, or dust plus flying grit on dirt and grass. Skid marks are left on the ground.
- The camera rolls slightly (about ±3°) and the FOV widens with speed. Speed lines appear above about 140 km/h.
- A **DRIFT** counter pulses white-gold and grows with slip angle. Drift points and a ×combo are shown.
- Remote players' drifts show their smoke and trails on your screen too (send drift intensity in the network state).

### Car visuals
A sporty coupe with a curved body (no box shapes), glossy clear-coat paint, dark glass, a rear wing, headlights, tail lights that brighten when braking, 5-spoke rims, brake discs and red calipers, and a soft blob shadow under the real shadow.

---

## 5. Multiplayer (Team Code)

### Player flow
1. **TEAM CODE → CREATE TEAM.** The host gets a **6-character code** (letters A–Z without I/O, digits 2–9), with COPY and SHARE buttons (Android share sheet, for example WhatsApp).
2. A friend opens **TEAM CODE**, types the code and taps **JOIN**. They appear in the lobby list with their colour.
3. The host picks the map. The other players see the selection live.
4. The host taps **START** (enabled with 2 or more players). Up to 4 players.
5. Results → host taps **BACK TO LOBBY** to play again with the same team.

Players in **different cities on different networks** (Jio, Airtel, Wi-Fi…) must be able to play together. That means relay-based networking, not LAN and not plain P2P.

### Recommended Unity stack (Unity Gaming Services)
| Need | Package |
|---|---|
| Player identity | **Authentication** (anonymous sign-in, display name) |
| Team code / lobby | **Lobby** service: `CreateLobbyAsync` returns a `LobbyCode` (the team code); `JoinLobbyByCodeAsync`; lobby data holds the map and player colours/slots |
| Cross-network connection | **Relay** (allocations with a join code stored in lobby data). Works through any NAT and mobile carrier |
| Game sync | **Netcode for GameObjects** with Unity Transport using Relay |

The UGS free tier covers development and small player counts. Check current pricing before launch.

### Authority model
- The **host is the referee** (host-authoritative state): flag holder, scores, round number, countdown start, base spots per round and the win.
- Each client **simulates its own car locally** (client-authoritative movement, for zero input lag) and sends its state **15 times per second**: position, yaw, velocity, steer and drift intensity. Use `NetworkTransform` with client authority or a custom unreliable RPC.
- Remote cars are **extrapolated** by up to 0.3 s and smoothed (exponential lerp, snapping if more than 12 m off).
- **Claims:** a client that touches the flag, rams the carrier or enters its own base with the flag sends `PickClaim`, `StealClaim` or `CaptureClaim` to the host. The host validates the phase, the current holder and the steal cooldown, then broadcasts the result.
- Messages: `RoundStart{n, scores, spots[]}`, `FlagHolder{holder, from}`, `Capture{slot, scores, round}`, `MatchEnd{scores}`, `BackToLobby`, `PlayerLeft{slot}`.
- If the host leaves, everyone gets "The team host left the game" and returns to the menu. If a client leaves, it is removed. If it was carrying the flag, the flag goes back to the centre.
- Rooms close after the match or when the host leaves (delete the lobby).

---

## 6. UI and game flow

1. **Studio intro (≈3.3 s, tap to skip):** dark background. A small orange car drives across the screen leaving an orange light line. "WHEEL **SMART**" is revealed behind it, a spinning orange wheel emblem pops in, then "S T U D I O" fades up.
2. **Main menu:** title "STREET **RUSH**", subtitle "WHEEL SMART STUDIO · CAPTURE THE FLAG", a **YOUR NAME** field (saved, 12 characters), and two big buttons: **SOLO DRIFT** and **TEAM CODE**. The 3D map orbits slowly behind the menu.
3. **Solo map select:** two cards with illustrations: **City Streets** and **Village Roads**.
4. **Team screen:** CREATE TEAM, or a code field plus JOIN, with a status line for errors such as "No team found with that code".
5. **Lobby:** team code (large) with COPY and SHARE; 4 player slots (colour chip, name, HOST/READY, or "Waiting for a friend…"); the map cards (host can select); LEAVE and START.
6. **HUD:** scoreboard top-left (colour, name, flag icon on the carrier, points, ROUND n/10); minimap under it; speedometer and gear top-centre; objective text; top-right buttons MENU, CAM (chase / far / cinematic), quality (LOW/MED/HD), SOUND; big countdown digits with "ROUND n / 10"; popups in the middle.
7. **Touch controls:** ◀ ▶ steering bottom-left; GAS (tall), BRAKE and DRIFT bottom-right; multi-touch; landscape only.
8. **Pause:** RESUME / LEAVE MATCH. In online play the match keeps running for others.
9. **Results:** VICTORY / DEFEAT / DRAW (or COMPLETE in Solo), a ranked list, PLAY AGAIN / BACK TO LOBBY, and MAIN MENU.
10. Android **Back** opens pause in a match and exits from the main menu.

Fonts: a squared techno display face for headings and numbers (for example Chakra Petch), a clean sans for body text (for example Inter). UI accent orange `#FF7A1A`, flag gold `#FFD23F`, dark glass panels `rgba(12,16,22,.46)`.

---

## 7. Art direction

**Mood:** sunny tropical island afternoon, saturated and friendly, readable at a glance on a phone. Stylised-realistic, not cartoon.

- **Palette:** deep sky blue `#1C7CF0` fading to a pale horizon `#CFEAF8`; grass from lush `#4F8F2C` to dry yellow-green; dirt `#B07848`; plaster walls in pastels (cream, yellow, pink, sky blue, mint, terracotta).
- **Textures:** 512–1024 px tiling PBR sets (albedo, normal, packed mask) at 4–8 m per tile, plus a large-scale macro variation (vertex colour or a world-space noise mask) to hide repetition. Grass has visible blades, a few flowers and patches. Dirt has ruts, pebbles and cracks. Concrete has slab seams, stains and cracks. Plaster has grime toward the ground.
- **Props:** chunky, slightly exaggerated proportions; bevelled edges; no pure cubes.
- **Lighting (URP):** one warm directional sun (intensity about 3, slightly yellow), soft shadows with a short shadow distance (about 60 m on mobile); a gradient ambient sky; ACES tonemapping; a little bloom on emissives (beams, trails, tail lights); light colour grading (+10 saturation, slight warm white balance); distance fog matching the horizon colour.
- **Effects:** additive light beams for the flag and bases, particle tyre smoke and dust, trail renderers for drift lights, decal skid marks.
- **Assets:** Unity Asset Store or Synty-style low/mid-poly packs (tropical village, city road kit, vehicles) or your own. **Do not use Garena/Free Fire assets, maps or logos.**

---

## 8. Audio, performance and build

### Audio
- Engine: a looped sample with pitch and filter following RPM and throttle.
- Tyre screech and dust loop scaled by drift intensity; wind by speed.
- Impact thump, flag pickup chime, steal "whoosh", capture fanfare, countdown beeps, victory and defeat stingers.

### Mobile targets
- **60 fps** on mid-range Android (Snapdragon 7-series); **30 fps** minimum on low-end devices.
- Fewer than 150 draw calls, under 300k visible triangles. GPU instancing for houses and props; static batching for roads and ground.
- Dynamic resolution (start at render scale 1.0, drop to 0.7 before cutting effects). Three quality presets (LOW / MED / HD) that switch shadows, MSAA, particle counts and render scale. Auto-downgrade if average fps < 45 over 3 s.
- Texture compression ASTC 6×6; atlas the UI; Addressables for maps.

### Build settings
- Package `com.wheelsmart.streetrush`, landscape only, immersive full-screen, keep the screen on.
- IL2CPP, ARM64, minimum API 24, target API 34 or higher; internet permission.
- Keep the release keystore safe: every update must use the same key.

---

## 9. Unity project structure and milestones

```
Assets/
  _Game/
    Art/ (Materials, Textures, Models, VFX, UI)
    Audio/
    Prefabs/ (Car, Flag, Base, HUD, Menus)
    Scenes/ (Boot, Menu, Village, City)
    Scripts/
      Core/      GameBootstrap, SceneLoader, Settings, QualityManager
      Car/       CarController, CarSuspension, CarDriftFX, CarAudio, CarVisuals, CarCollisionDamping
      Match/     MatchManager (host), RoundTimer, FlagController, BaseZone, SpawnPoints, ScoreBoard
      Net/       UGSInit, AuthService, LobbyService (team code), RelayService, NetworkCarSync, NetMessages
      UI/        IntroLogo, MainMenu, TeamCodePanel, LobbyPanel, HUD, Minimap, PausePanel, ResultsPanel, TouchControls
      Camera/    ChaseCamera (Cinemachine), CameraShake
```

| # | Milestone | Done when |
|---|---|---|
| 1 | Car feel | One car drifts nicely on a test plane with touch and keyboard controls, effects and sound |
| 2 | Maps | Village and City built with colliders, 12 base spots, flag stand, minimap |
| 3 | Solo match | 10 rounds, countdown, pickup, capture, moving bases, results |
| 4 | Online | UGS sign-in, team code create/join, relay connection, lobby map select, start |
| 5 | Online match | Car sync, host referee, steal by dash, leave handling |
| 6 | Polish | Intro logo, UI animations, audio mix, quality presets, Android build |

---

## 10. Master prompt (copy everything inside the box)

```
You are a senior Unity engineer and technical artist. Build a complete, shippable mobile game in this Unity project.

PROJECT
- Unity 6 LTS, Universal Render Pipeline, new Input System, Cinemachine 3, TextMeshPro, Netcode for GameObjects, Unity Transport, Unity Gaming Services (Authentication, Lobby, Relay).
- Target Android first (API 24+, IL2CPP, ARM64, landscape, immersive full screen, screen kept on). Must run at 60 fps on mid-range phones and 30 fps on low-end phones.
- Game: "Street Rush" by "Wheel Smart Studio". Package com.wheelsmart.streetrush.
- Work milestone by milestone (see MILESTONES). After each milestone, make sure the project compiles with zero errors, list the files you created, and explain how to test it in the Editor.
- Write clean, commented C# in namespaces StreetRush.Core / Car / Match / Net / UI / CameraRig. No placeholder TODOs in finished milestones.

ART DIRECTION (original or licensed assets only)
- Feel: a bright, sunny, tropical-island mobile battle-royale look — lush varied grass, warm dirt roads, deep blue sky to pale horizon, chunky stylised-realistic props with bevelled edges, saturated but readable.
- Never use, extract, trace or imitate copyrighted game assets, maps or logos (for example Garena Free Fire). Use primitives/ProBuilder plus procedural textures, or clearly marked placeholder slots where licensed packs can be dropped in.
- Textures: tiling PBR materials 4–8 m per tile plus world-space macro variation to hide repetition. Grass with blades, small flowers and patches; dirt with ruts, pebbles and cracks; concrete slabs with seams and stains; plastered pastel walls with grime near the ground.
- Lighting: warm directional sun (~3 intensity) with soft shadows (shadow distance ~60 m on mobile), gradient ambient, ACES tonemapping, mild bloom, +10 saturation, horizon-coloured fog.

GAME RULES (capture the flag)
- 1 player (Solo Drift) or 2–4 players online. Slot colours: 1 orange #FF6A0A, 2 blue #2F7BFF, 3 green #22C55E, 4 magenta #D23BD8.
- A match has 10 rounds and no time limit. Each round starts with a 10-second countdown during which cars are frozen at their spawns (beeps at 3, 2, 1, then "GO!").
- A flag (pole plus waving gold cloth with a wheel emblem) stands on a stand at the map centre with a tall gold light beam.
- The first car to come within 3 m of the flag picks it up; the flag attaches to that car's rear roof and the beam follows it (hidden on the carrier's own screen).
- If any other car touches the carrier (centres within ~4.2 m), the flag moves to that car instantly. After any steal, no new steal for 1.2 s.
- Each player has a base: a 6.5 m radius circle in their colour with a coloured light beam, a pennant and a floating name tag. When the carrier enters their OWN base, the flag plants there, they score +1, a 3.5 s celebration plays, then the next round begins.
- Every round, bases MOVE: each map has 12 base spots on the outer ring road (3 per side). The host picks one per player with chosen spots at least 150 m apart and broadcasts the choice. Cars spawn 14 m inward from their base, facing the centre. The flag resets to the centre.
- After round 10 the highest score wins (VICTORY / DEFEAT, DRAW on a tie). Solo Drift uses the same rules alone and shows the total time ("10 flags in 3:42").
- HUD objective text: "GRAB THE FLAG" / "TAKE THE FLAG TO YOUR BASE" / "DASH <name> TO STEAL THE FLAG". Do NOT add a navigation arrow above the car.

MAPS (two scenes, each about 450 m square, boundary = invisible wall plus painted line)
1) Village Roads: grass ground everywhere; a 5x5 network of 12 m wide dirt roads with jittered intersections and ~9 interior streets removed (keep the network connected and the outer ring intact); soft road edges with ruts. Centre: a village dirt ground with a South-Indian temple (stone plinth, white shrine with red band, 5-tier coloured gopuram, gold kalasam, gold flagpole in front); the flag stand is in front of it. Up to 3 houses per street facing the road (tiled-roof, flat-roof RCC some 2-storey with black water tanks, round thatched huts), pastel plaster walls, doors, windows with sunshades. Never place houses on base spots, spawns, the temple ground or other roads. Nothing else on the playable area.
2) City Streets: paved concrete ground; a 6x6 grid of 18 m tar roads (2 lanes each way, yellow double centre line, dashed white lanes, edge lines, zebra crossings at junctions); a painted centre circle with the flag stand. Roads and ground only.
- Minimap (render texture or UI drawing): round, top-left, rotates with the player, shows roads, houses, bases in colour, players as coloured dots, the flag as a gold icon and the local player as an arrow.

CAR AND DRIVING (custom arcade controller, no WheelColliders)
- Rigidbody plus 4 raycast springs/dampers; wheel meshes follow the ground and spin with speed.
- Split velocity into forward and lateral parts. Lateral grip: 9/s normally, 2.4/s while sliding (lateral speed > 4.5 m/s), 0.9/s with the handbrake. Add 35% of the removed lateral speed back as forward speed.
- Top speed 80 m/s with falloff; brake -32 m/s², reverse capped at -15 m/s. Steering eases in and is reduced at high speed; handbrake yaw x1.7 above 8 m/s. Automatic 6-speed gearbox driving RPM.
- Collisions with cars and walls must NOT bounce: zero restitution along the contact normal, 3–6% extra damping, separate by half the penetration each. Strong hits only give camera shake, a thump sound and a brief screen flash.
- Drift (slip > 3.5 m/s at speed > 10 m/s): body leans outward up to ~8.5°, front wheels visually counter-steer, light trails in the car colour from both rear wheels (TrailRenderer, additive, 0.55 s), tyre smoke on tarmac / dust and grit on dirt and grass, skid-mark decals, camera roll ±3°, FOV widens with speed, speed lines above 140 km/h, a pulsing "DRIFT <points> xCombo" label.
- Car look: curved sporty coupe body (no boxy shapes), clear-coat paint in the slot colour, dark glass, rear wing, emissive headlights and tail lights (brighter when braking), 5-spoke rims, brake discs and red calipers.
- Cameras: chase (default), far chase and cinematic orbit (CAM button); the camera never clips into houses (spherecast and pull in).

MULTIPLAYER (Team Code, must work between different cities and mobile networks)
- Sign in anonymously with UGS Authentication on boot; the display name comes from the YOUR NAME field (12 characters, saved in PlayerPrefs).
- CREATE TEAM: create a Relay allocation, then a Lobby (max 4, private) storing the relay join code, the selected map and each player's slot/colour. Show Lobby.LobbyCode as the 6-character TEAM CODE with COPY (clipboard) and SHARE (Android share intent: "Join my Street Rush team! Open the game, tap TEAM CODE and enter: CODE").
- JOIN: JoinLobbyByCodeAsync, read the relay join code, join the relay, start a Netcode client. Show clear errors: invalid code, team full, match already started, no internet.
- Lobby screen: code with copy/share, 4 slots (colour, name, HOST/READY or "Waiting for a friend…"), map cards (host selects, others see it live via lobby data or a NetworkVariable), LEAVE, START (host only, needs 2+ players). Send lobby heartbeats; delete the lobby on start or leave.
- Authority: the host is the referee for flag holder, scores, round, countdown, base spots and the winner. Each client owns its car movement (client-authoritative) and sends position, yaw, velocity, steer and drift intensity at 15 Hz (unreliable). Remote cars are extrapolated up to 0.3 s and smoothed (snap if > 12 m off). Pickup, steal and capture are claims sent by the client that saw them; the host validates (phase, holder, 1.2 s steal cooldown) and broadcasts RoundStart{n, scores, spots[]}, FlagHolder{holder, from}, Capture{slot, scores, round}, MatchEnd{scores}, BackToLobby, PlayerLeft{slot}.
- Wait for all clients to load the map (or 8 s) before round 1. If the host leaves: show "The team host left the game" and return to the menu. If a client leaves: remove its car and base; if it held the flag, return the flag to the centre.

UI FLOW (TextMeshPro, Chakra Petch for headings/numbers, Inter for body; accent #FF7A1A, flag gold #FFD23F, dark glass panels)
1. Studio intro (3.3 s, tap to skip): dark background; a small orange car drives across leaving an orange light line; the text "WHEEL SMART" (SMART in orange) is revealed behind it; a spinning orange wheel emblem pops in; "S T U D I O" fades up.
2. Main menu over a slow orbit of the map: "STREET RUSH" (RUSH orange), subtitle "WHEEL SMART STUDIO · CAPTURE THE FLAG", a YOUR NAME field, big buttons SOLO DRIFT and TEAM CODE.
3. Solo map select (City Streets / Village Roads cards). 4. Team screen (CREATE TEAM, or code + JOIN, plus a status line). 5. Lobby.
6. HUD: scoreboard (colour, name, flag icon on the carrier, points, ROUND n/10), minimap, speedometer + gear, objective text, buttons MENU / CAM / quality LOW-MED-HD / SOUND, big countdown digits with "ROUND n / 10", centred popups (GOT THE FLAG!, FLAG STOLEN!, FLAG LOST, <NAME> SCORES, POINT!, GO!).
7. Touch controls: steer left/right bottom-left; GAS (tall), BRAKE and DRIFT bottom-right; multi-touch. Keyboard: arrows/WASD, Space = drift, C = camera, Esc = pause.
8. Pause (RESUME / LEAVE MATCH; online play keeps running). 9. Results (VICTORY / DEFEAT / DRAW / COMPLETE, ranked list, PLAY AGAIN or BACK TO LOBBY, MAIN MENU). Android Back = pause in a match, exit from the main menu.

AUDIO
- Engine loop with pitch/filter from RPM and throttle; screech/dust loops from drift intensity; wind from speed; impact thump; pickup chime; steal whoosh; capture fanfare; countdown beeps; victory and defeat stingers. Start audio only after the first tap.

PERFORMANCE
- Under 150 draw calls and 300k visible triangles; static batching for roads and ground; GPU instancing for houses; ASTC textures; shadow distance 60 m.
- Quality presets LOW / MED / HD (shadows, MSAA, particle counts, render scale 0.7–1.0). Auto-drop one level if average fps < 45 over 3 s and show "SMOOTH MODE".

MILESTONES
1) Car feel on a test plane (controller, drift FX, camera, touch + keyboard input, audio).
2) Both maps with colliders, 12 base spots each, flag stand, minimap.
3) Solo match loop end to end with results.
4) UGS sign-in, team code create/join through Lobby + Relay, lobby screen with map select.
5) Online match: car sync, host referee, steal by dash, leave handling, back to lobby.
6) Polish: studio intro, UI animations, audio mix, quality presets, Android build settings and a signed release build.

Start with milestone 1 now. Before writing code, list the packages you will add and the scene setup you need from me.
```
