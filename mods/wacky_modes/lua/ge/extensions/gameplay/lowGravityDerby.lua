-- Low Gravity Derby: everyone floats, nothing makes sense, chaos reigns.
local M = {}

local GRAVITY = -1.5  -- m/s², normal BeamNG is -9.81

local function applyGravity()
  be:setGravity(GRAVITY)
end

local function resetGravity()
  be:setGravity(-9.81)
end

function M.onExtensionLoaded()
  applyGravity()
  guihooks.trigger("toastrMsg", {
    type = "info",
    title = "Low Gravity Derby",
    msg = "Gravity reduced. Try not to fly away."
  })
end

function M.onExtensionUnloaded()
  resetGravity()
end

return M
