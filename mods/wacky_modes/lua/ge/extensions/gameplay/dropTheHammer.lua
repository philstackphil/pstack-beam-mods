-- Drop the Hammer — free-roam sandbox extension.
-- Activate:  extensions.load('gameplay/dropTheHammer')
-- Deactivate: extensions.unload('gameplay/dropTheHammer')
-- Console trigger (dev/testing): extensions.gameplay_dropTheHammer.drop()

local M = {}

-- ── config ────────────────────────────────────────────────────────────────────

local HOTKEY        = 'H'   -- change to any uppercase letter/key name
local SEARCH_RADIUS = 50    -- metres: how far to scan for target vehicles
local DROP_HEIGHT   = 15    -- metres above target when spawning the crate (~50 ft)
local AHEAD_DIST    = 6     -- metres ahead of player when no target found (~20 ft)
local CRATE_MODEL   = 'drop_hammer_crate'
local TRAFFIC_COUNT = 14    -- AI cars to fill the city on load

-- ── state ─────────────────────────────────────────────────────────────────────

local hammerCount = 0

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
    -- No car nearby: drop just ahead of the player so it lands ~20 ft in front
    local fwd = playerVeh:getDirectionVector()
    spawnPos  = playerPos + fwd * AHEAD_DIST + vec3(0, 0, DROP_HEIGHT)
  end

  -- Random yaw so the crate tumbles unpredictably on impact
  local yaw = math.rad(math.random(0, 359))
  core_vehicles.spawnNewVehicle(CRATE_MODEL, {
    pos              = spawnPos,
    rot              = quatFromEuler(0, 0, yaw),
    config           = '',
    autoEnterVehicle = false,
  })

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

-- im.IsKeyPressed fires once per press (rising-edge), perfect for a drop action.
-- Key index for letter keys matches their ASCII value in BeamNG's ImGui bindings.
local keyCode = string.byte(HOTKEY)

function M.onUpdate(dt)
  if im and im.IsKeyPressed(keyCode) then
    performDrop()
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
  startTraffic()
  guihooks.trigger('toastrMsg', {
    type  = 'info',
    title = 'Drop the Hammer',
    msg   = string.format('Ready! Press [%s] to drop a crate on the nearest car.', HOTKEY),
  })
end

function M.onExtensionUnloaded()
  stopTraffic()
  hammerCount = 0
end

return M
