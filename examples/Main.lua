-- Example: show a picture in a Client Script.
-- Change the three values marked "CHANGE" to match your stage.

local PixelView = require("pixel_importer/PixelView")   -- CHANGE: the path where you put PixelView.lua
local sample = require("examples/sample")              -- CHANGE: the path of a .lua made by Pixel Importer 91

local TEMPLATE_INDEX = 1                               -- CHANGE: the index of your ImageControl template
local PER_FRAME = 300                                  -- ImageControls created per frame (lower it if the game stutters)

local view = nil
local total = 0

function OnStart()
    view = PixelView.New({
        parent = script.object.parent,
        templateIndex = TEMPLATE_INDEX,
        x = 800,
        y = 450,
        dotSize = 4,
        step = 1,
    })
    -- The largest number of ImageControls any of your pictures needs.
    -- Pixel Importer 91 shows this number ("Largest: ... ImageControls").
    total = view:Count(sample)
    script:EnableUpdate(true)
end

function OnUpdate(dt)
    -- Create the ImageControls a few at a time, then show the picture
    if view:Grow(PER_FRAME, total) then
        script:EnableUpdate(false)
        view:Show(sample)
    end
end
