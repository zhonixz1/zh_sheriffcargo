# ZH Sheriff Cargo

> A fully configurable sheriff-controlled cargo wagon event for RedM.

ZH Sheriff Cargo is a standalone cargo event designed for immersive RedM roleplay servers. The system allows authorized law enforcement players to organize secure cargo transports using a configurable wagon and crate system.

Sheriffs can manually prepare every cargo event by selecting the route, choosing the crate contents, and starting the transport. Alternatively, events can be scheduled automatically through the configuration file.

The resource focuses on immersive gameplay, synchronized interactions, server-side validation, and optimized performance.

---

# ✨ Features

- 🚔 Sheriff/Law Enforcement Only Event
- 📦 Interactive Cargo Crate
- 🛒 Cargo Wagon System
- 🎒 Carryable Cargo Crate
- 📍 Configurable Delivery Routes
- ⏰ Automatic Scheduled Events
- ▶️ Manual Event Start
- 📋 Item Selection Menu
- 📦 Custom Item Quantities
- 🔄 Network Synchronized
- ⚡ Optimized Performance
- 🔒 Server-side Validation
- ⚙️ Easy Configuration
- 🧩 Standalone Resource
- 👨‍💻 Developer Friendly

---

# 🚔 Event Workflow

The event can be started in two different ways.

## Manual Mode

Authorized sheriffs can:

- Start the event.
- Select the cargo route.
- Choose which items will be stored inside the crate.
- Configure item quantities.
- Launch the transport.

Everything is validated server-side before the event begins.

---

## Automatic Mode

The event can also be started automatically using configurable schedules inside:

```lua
Config.AutoStart
```

The server will automatically create a cargo event without requiring manual interaction.

---

# 📦 Cargo Crate

The cargo crate is fully interactive.

Players can:

- Pick up the crate from the wagon.
- Carry it on their back.
- Drop it anywhere.
- Pick it back up.
- Place it on the ground.
- Hold the interaction key to open the crate.
- Receive the configured rewards.

All interactions are synchronized between players.

---

# 🎒 Crate Interaction

Interaction flow:

1. Walk to the cargo crate.
2. Press **E** to pick it up.
3. Carry the crate on your back.
4. Press **E** again to place it on the ground.
5. The crate can be picked up again at any time.
6. Hold **E** while looking at the crate.
7. Receive every configured item inside.

---

# 📋 Item Configuration

Before starting the event, sheriffs can choose:

- Which items will be inside the crate.
- Quantity of every item.
- Delivery route.

This allows every event to be different.

---

# ⚙️ Configuration

Most values can be modified through the configuration file.

Examples:

- Sheriff jobs
- Wagon model
- NPC model
- Automatic event times
- Delivery routes
- Rewards
- Item list
- Item quantities
- Interaction distance
- Debug mode

No code modifications are required for basic customization.

---

# 🔒 Security

The resource follows a server-authoritative architecture.

The server validates:

- Authorized job
- Active event
- Crate state
- Item rewards
- Route validation
- Distance validation
- Event state
- Duplicate reward attempts
- Spam requests

Clients never control rewards or event progression.

---

# ⚡ Performance

Designed with optimization in mind.

Features include:

- Dynamic thread wait times
- Optimized entity management
- Reduced CPU usage
- Lightweight network events
- Minimal synchronization traffic
- Efficient client loops

---

# 🛠 Technologies

- Lua
- RedM
- Cfx.re
- Standalone

---

# 📂 Resource Structure

```
zh_sheriffcargo/
│
├── client/
│   └── main.lua
│
├── server/
│   └── main.lua
│
├── shared/
│   └── config.lua
│
├── html/
│
├── fxmanifest.lua
│
└── README.md
```

---

# 🚀 Installation

1. Download the resource.

2. Place it inside:

```
resources/[jobs]/zh_sheriffcargo
```

3. Add the following line to your **server.cfg**

```cfg
ensure zh_sheriffcargo
```

4. Configure the resource:

```
shared/config.lua
```

5. Restart your server.

---

# 🔮 Planned Features

Future updates may include:

- Discord Webhook Logs
- Database Statistics
- Multiple Wagon Types
- Route Randomization
- Event History
- Difficulty Levels
- Custom NPC Guards
- Framework Bridges

---

# 📸 Screenshots

Screenshots will be added soon.

---

# 📜 License

This project is licensed under the MIT License.

---

# 👨‍💻 Author

Developed by **Zhonix**

RedM Developer

Portfolio Project
