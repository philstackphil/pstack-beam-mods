-- Drop the Hammer — free-roam sandbox extension.
-- Activate:  extensions.load('gameplay/dropTheHammer')
-- Deactivate: extensions.unload('gameplay/dropTheHammer')
-- Console trigger (dev/testing): extensions.gameplay_dropTheHammer.drop()

local M = {}

-- ── config ────────────────────────────────────────────────────────────────────

local HOTKEY        = 'h'   -- lowercase for ActionMap:bind(); change freely
local SEARCH_RADIUS = 50    -- metres: how far to scan for target vehicles
local DROP_HEIGHT   = 15    -- metres above target when spawning the crate (~50 ft)
local AHEAD_DIST    = 6     -- metres ahead of player when no target found (~20 ft)
local CRATE_MODEL   = 'drop_hammer_crate'
local TRAFFIC_COUNT = 14    -- AI cars to fill the city on load

-- ── state ─────────────────────────────────────────────────────────────────────

local hammerCount = 0
local actionMap   = nil

-- ── target selection ──────────────────────────────────────────────────────────

local function nearestVehicle(fromPos)
  local playerVeh = be:getPlayerVehicle(0)
  local playerId  = playerVeh and playerVeh:getID() or -1
  local best, bestDist = nil, SEARCH_RADIUS

  for i = 0, be:getObjectCount() - 1 do
    local obj = be:getObject(i)
    if obj and obj:getID() ~= playerId and obj:getField('JBeam', 0) ~= '' then
      local d = (obj:getPosition() - fromPos):length()
      if d < bestDist then
        bestDist, best = d, obj
      end
    end
  end

  return best
end

-- ── drop ──────────────────────────────────────────────────────────────────────

local function performDrop()
  local playerVeh = be:getPlayerVehicle(0)
  if not playerVeh then return end

  local playerPos = playerVeh:getPosition()
  local target    = nearestVehicle(playerPos)

  local spawnPos
  if target then
    spawnPos = target:getPosition() + vec3(0, 0, DROP_HEIGHT)
  else
    local fwd = playerVeh:getDirectionVector()
    spawnPos  = playerPos + fwd * AHEAD_DIST + vec3(0, 0, DROP_HEIGHT)
  end

  local yaw = math.rad(math.random(0, 359))
  core_vehicles.spawnNewVehicle(CRATE_MODEL, {
    pos              = spawnPos,
    rot              = quatFromEuler(0, 0, yaw),
    config           = '',
    autoEnterVehicle = false,
  })

  -- Silence the horn that the vehicle also received from the H key press.
  -- queueLuaCommand runs in the vehicle's Lua context next tick.
  playerVeh:queueLuaCommand("input.event('horn', 0, 2)")

  hammerCount = hammerCount + 1
  guihooks.trigger('toastrMsg', {
    type  = 'info',
    title = 'Drop the Hammer',
    msg   = string.format('Hammers dropped: %d', hammerCount),
  })
end

-- Public alias — call from the Lua console while iterating:
--   extensions.gameplay_dropTheHammer.drop()
M.drop = performDrop

-- ── input ─────────────────────────────────────────────────────────────────────

local function setupInput()
  -- ActionMap sits above the vehicle's input stack, so pushing it here
  -- captures H before the vehicle's horn binding sees it.
  actionMap = ActionMap()
  actionMap:push()
  actionMap:bind('keyboard', HOTKEY, function(val)
    if val > 0 then performDrop() end
  end)
end

local function teardownInput()
  if actionMap then
    actionMap:pop()
    actionMap = nil
  end
end

-- ── traffic ───────────────────────────────────────────────────────────────────

local function startTraffic()
  if not extensions.isLoaded('traffic') then
    extensions.load('traffic')
  end
  extensions.traffic.activate(TRAFFIC_COUNT)
end

local function stopTraffic()
  if extensions.isLoaded('traffic') then
    extensions.traffic.deactivate()
  end
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────

function M.onExtensionLoaded()
  setupInput()
  startTraffic()
  guihooks.trigger('toastrMsg', {
    type  = 'info',
    title = 'Drop the Hammer',
    msg   = string.format('Ready! Press [%s] to drop a crate on the nearest car.', string.upper(HOTKEY)),
  })
end

function M.onExtensionUnloaded()
  teardownInput()
  stopTraffic()
  hammerCount = 0
end

return M
