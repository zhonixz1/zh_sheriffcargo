# qq-cargo

A network-synchronized cargo wagon event for VORP-based RedM servers, supporting manual and scheduled operation.

## Features

- NUI mission setup menu opened with `/setup_cargo`
- Automatic mission starts at configured server times
- Multiple selectable routes with individual driving settings
- Configurable chest items and quantity limits
- Job and minimum job-grade permissions
- Network-synchronized wagon, NPC driver, and cargo chest
- Carry, drop, and open chest interactions
- Automatic cleanup when the route finishes or the resource stops
- In-game commands for recording new routes

## Requirements

- RedM server
- `vorp_core`
- `vorp_inventory`

## Installation

1. Place the `qq-cargo` folder inside your resources directory.
2. Make sure `vorp_core` and `vorp_inventory` start before this resource.
3. Add `ensure qq-cargo` to your `server.cfg`.
4. After changing the configuration, run `restart qq-cargo` in the server console.

## Operating modes

`Config.SpawnMode` determines how the system operates.

```lua
Config.SpawnMode = "manual"
```

- `"manual"`: An authorized player uses `/setup_cargo`, selects a route and chest contents in the menu, and starts the mission.
- `"automatic"`: The mission starts at the server times listed in `Config.Automatic.times`. Its route and chest contents come from `Config.Automatic`.

Only one cargo mission can run at a time. At least one player must be online so an automatic mission can create its networked entities. The schedule uses the server machine's local clock in 24-hour format.

```lua
Config.Automatic = {
    times = {
        {hour = 12, minute = 0},
        {hour = 18, minute = 30}
    },
    route = "valentine",
    items = {
        {item = "consumable_coffee", amount = 1},
        {item = "consumable_medicine", amount = 1}
    },
    checkInterval = 15000
}
```

- `times`: Hours and minutes at which a mission should start.
- `route`: The `Config.routePoints` key used by automatic missions.
- `items`: Contents of the automatic cargo chest. Every item must exist in `Config.MarketItems`.
- `checkInterval`: Schedule-check frequency in milliseconds. `15000` equals 15 seconds.

## Main configuration

- `Config.DefaultRoute`: Route selected by default when the manual menu opens.
- `Config.OpenCommand`: Command that opens the manual menu. The default is `setup_cargo`.
- `Config.Permissions.enabled`: Enables or disables job checks for the manual command.
- `Config.Permissions.jobs`: Jobs allowed to use the command.
- `Config.Permissions.minimumJobGrade`: Minimum required job grade.
- `Config.MarketItems`: Allow-list used by the setup menu and automatic chest rewards.
- `Config.UI.maxTotalItems`: Maximum total number of items allowed in the chest.
- `Config.UI.maxPerItem`: Default per-item limit when an item has no specific limit.
- `Config.Models`: Wagon, driver, and crate models.
- `Config.Blip`: Wagon map-blip status, name, sprite, and scale.

Market item example:

```lua
{
    item = "consumable_coffee",
    label = "Coffee",
    image = "item/consumable_coffee.png",
    defaultAmount = 1,
    maxAmount = 5
}
```

- `item`: VORP Inventory item name.
- `label`: Name displayed in the setup menu.
- `image`: Image path relative to the `html` directory. Set it to `false` to disable the image.
- `defaultAmount`: Quantity added by default when the item is selected.
- `maxAmount`: Maximum selectable quantity of this item.

## Routes and driving settings

Routes are added under `Config.routePoints`. The first entry in `locations` is the wagon spawn point. Driving normally begins at the second coordinate.

```lua
["example_route"] = {
    label = "Example Route",
    driving = {
        speed = 7.0,
        drivingStyle = 262144,
        stoppingRange = 1.5,
        straightLineDistance = -1.0,
        arrivalDistance = 4.0,
        routeCheckInterval = 250,
        taskRefreshInterval = 5000,
        startPointIndex = 2
    },
    locations = {
        {coords = vector3(-216.0961, 625.4980, 116.2943)},
        {coords = vector3(-129.6071, 568.3389, 113.5835)}
    }
}
```

When a setting is omitted from a route's `driving` table, its value is inherited from `Config.Driving` or `Config.Timing`.

### `speed`

The driving speed requested from the wagon driver. A higher value makes the wagon move faster but increases the risk of sliding, leaving the road, or crashing on sharp turns. Values between `6.0` and `8.0` are suitable for most routes.

### `drivingStyle`

The native driving bitmask that controls road usage and obstacle behavior. The default value of `262144` can normally be kept. An unsuitable value may cause the wagon to stop following the road.

### `stoppingRange`

The target-approach distance passed to the NPC driving task. A smaller value asks the driver to approach the coordinate more closely. Extremely small values can make the driver turn around or become stuck while trying to hit the exact point. Values between `1.0` and `3.0` are generally safe.

### `straightLineDistance`

Controls when the NPC may drive directly toward the target instead of relying on normal pathfinding. The recommended value is `-1.0`. Large positive values may cause the wagon to leave the road and drive in a straight line toward the destination.

### `arrivalDistance`

The distance at which the script considers a route point complete. When the wagon enters this range, the script advances to the next coordinate. This is different from `stoppingRange`:

- `stoppingRange` affects the game's NPC driving task.
- `arrivalDistance` controls the script's progression to the next point.

Keep `arrivalDistance` greater than `stoppingRange` to reduce the chance of the wagon becoming stuck. For example, use `arrivalDistance = 4.0` with `stoppingRange = 1.5`.

### `routeCheckInterval`

How often the script checks whether the wagon has reached its target, in milliseconds. A value of `250` performs four checks per second. Lower values react faster but perform more frequent work. Values between `150` and `500` are generally appropriate.

### `taskRefreshInterval`

How often the NPC driving task is issued again, in milliseconds. This can help when the driver loses the task or briefly becomes stuck. A value of `5000` refreshes it every five seconds. Very low values may disrupt movement.

### `startPointIndex`

The index in `locations` from which driving begins. Because the first coordinate is the spawn point, the recommended value is `2`. A value of `3` skips the second coordinate.

## General timing settings

- `modelLoadTimeout`: Maximum time allowed for a model to load.
- `requestControlTimeout`: Maximum time allowed to obtain control of a network entity.
- `deleteControlTimeout`: Time allowed to obtain network control before deletion.
- `routeCheckInterval`: Default target-check interval when a route does not override it.
- `routeTaskRefreshInterval`: Default driving-task refresh interval when a route does not override it.
- `spawnRegisterTimeout`: Time allowed for spawned network entities to register with the server.
- `idleInteractionInterval`: Chest-interaction check frequency while the player is far away.
- `holdToOpen`: How long the interaction key must be held to open the chest.
- `cleanupAfterRoute`: Delay before entities are removed after reaching the final point.
- `driverSeatCheckDelay`: Delay after placing the NPC driver in the wagon seat.

All timing values are expressed in milliseconds.

## Crate settings

- `interactionDistance`: Maximum distance from which a player can interact with the chest.
- `spawnZOffset`: Vertical offset applied when the chest is spawned.
- `attachToWagon`: Bone, position, and rotation used while the chest is attached to the wagon.
- `attachToPlayer`: Player bone, position, and rotation used while carrying the chest.

## Route-recording commands

```text
/record_route start route_key Route Label
/record_route stop
/record_route clear
```

1. Use `/record_route start route_key Route Label` at the starting point.
2. Travel along the route you want to record.
3. Use `/record_route stop` at the final point.
4. Copy the generated Lua route block from the F8 console into `Config.routePoints`.

`Config.RouteRecorder.interval` controls the coordinate-check frequency. `minDistance` controls the minimum distance between recorded points. The `clear` action discards the current recording without printing it.

## Tebex product copy

### Product title

**qq-cargo | Manual & Scheduled Cargo Event for VORP RedM**

### Short description

Create immersive networked cargo wagon events on your VORP RedM server with manual NUI setup, scheduled automatic starts, configurable routes, selectable chest rewards, job permissions, and synchronized cargo interactions.

### Full description

**qq-cargo** is a configurable cargo wagon event resource developed for VORP-based RedM servers. It allows server owners to run cargo missions manually through an in-game setup interface or automatically at configured server times.

In manual mode, authorized players can use `/setup_cargo` to open the cargo setup menu, select an available route, choose the items and quantities placed inside the cargo chest, and start the event. Job and minimum job-grade permissions can be configured for staff, law enforcement, or any custom VORP job.

In automatic mode, the resource checks the server clock and starts a configured cargo route at scheduled times. Server owners can choose the automatic route, schedule multiple start times, and define chest rewards directly in `config.lua`.

The wagon, NPC driver, and cargo chest are networked for multiplayer synchronization. Players can interact with the chest, carry it, drop it, and open it. Inventory capacity is checked through VORP Inventory before rewards are given. When the route finishes, the event entities are cleaned up automatically.

Every route can use its own speed, stopping distance, arrival range, route-check interval, and task-refresh settings. A built-in route recorder helps server owners create coordinate paths directly in game and prints a ready-to-use Lua route block to the F8 console.

### Included features

- Manual cargo setup through an in-game NUI menu
- Scheduled automatic cargo events using server time
- Multiple configurable cargo routes
- Per-route NPC driving configuration
- Configurable chest rewards and quantity limits
- VORP job and minimum job-grade permissions
- Network-synchronized wagon, driver, and cargo chest
- Carry, drop, and open chest interactions
- VORP Inventory capacity checks
- Configurable wagon map blip
- In-game route-recording commands
- Automatic cleanup after route completion
- Editable `config.lua`
- Installation and configuration documentation

### Requirements

- A working RedM server
- VORP Core
- VORP Inventory

### Customer notice

This resource requires basic RedM server administration knowledge. Routes, item names, permissions, schedules, and models must be configured for your server. Item names used in the configuration must exist in your VORP Inventory database.

When requesting support, provide your RedM artifact version, VORP Core version, VORP Inventory version, and all relevant client/server console errors.

### License text

This purchase grants usage rights to the purchasing customer according to the store license terms. Redistribution, resale, sharing, leaking, or unauthorized re-uploading of the resource is prohibited.
