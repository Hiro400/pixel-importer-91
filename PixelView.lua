-- PixelView.lua
-- Shows pixel art made by Pixel Importer 91, by placing square ImageControls side by side.
--
-- One ImageControl is used per dot (transparent dots are skipped).
-- With merge = true, dots of the same color that touch horizontally share one wide ImageControl.
-- ImageControls are created from a template and reused, so their number never keeps growing.
--
-- Usage:
--   local PixelView = require("pixel_importer/PixelView")
--   local view = PixelView.New({
--       parent = script.object.parent,
--       templateIndex = 1,     -- an ImageControl template (any size; it is resized to one dot)
--       x = 800, y = 450,      -- position of the top-left dot (anchoredPositionX / Y)
--       spacing = 4,           -- distance between neighboring dots
--       step = 1,              -- 2 = use every 2nd dot (half the resolution, a quarter of the ImageControls)
--       merge = true,          -- share one ImageControl between same-colored dots in a row
--   })
--   view:Show(art)             -- show a picture (does nothing if it is already shown)
--   view:Clear()               -- hide it
--
-- To avoid a slow first Show, create the ImageControls in advance, a few per frame:
--   view:Grow(300, view:Count(art))   -- returns true when finished

local PixelView = {}
PixelView.__index = PixelView

-- The character that means "transparent". Must match the converter.
PixelView.TRANSPARENT_KEY = "."


-- ===== Colors =====

-- "#RRGGBB" -> ColorValue. Each color is made only once.
local colorCache = {}
local function ToColorValue(hex)
    local c = colorCache[hex]
    if c == nil then
        local r = tonumber(hex:sub(2, 3), 16)
        local g = tonumber(hex:sub(4, 5), 16)
        local b = tonumber(hex:sub(6, 7), 16)
        c = Color(r, g, b, 255)
        colorCache[hex] = c
    end
    return c
end


-- ===== Compressed rows =====

-- Pictures made with "Compress" have encoding = "rle". Their rows are written as:
--   a color key or "."      one dot, as it is
--   " " + length + key      the key repeated `length` times
--   "  " + length           the same `length` dots as the row above
-- A length is one character: the color keys in order and then ".", meaning 4, 5, 6, ... 95.
-- Must match the converter.
local COUNT_KEYS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    .. "abcdefghijklmnopqrstuvwxyz"
    .. "0123456789"
    .. "!#$%&'()*+,-/:;<=>?@[]^_`{|}~"
    .. "."
local lengthOf = {}
for i = 1, #COUNT_KEYS do
    lengthOf[COUNT_KEYS:sub(i, i)] = i + 3
end

-- Turn one compressed row back into one character per dot. above is the previous row, already expanded.
local function ExpandRow(text, above)
    local parts = {}
    local done = 0   -- how many dots are expanded so far
    local i = 1
    while i <= #text do
        local ch = text:sub(i, i)
        if ch ~= " " then
            table.insert(parts, ch)
            done = done + 1
            i = i + 1
        elseif text:sub(i + 1, i + 1) == " " then
            local n = lengthOf[text:sub(i + 2, i + 2)]
            table.insert(parts, above:sub(done + 1, done + n))
            done = done + n
            i = i + 3
        else
            local n = lengthOf[text:sub(i + 1, i + 1)]
            table.insert(parts, string.rep(text:sub(i + 2, i + 2), n))
            done = done + n
            i = i + 3
        end
    end
    return table.concat(parts)
end

-- The rows of a picture, one character per dot (expanded once and remembered).
local rowCache = setmetatable({}, { __mode = "k" })
local function RowsOf(art)
    if art.encoding == nil then
        return art.rows
    end
    if art.encoding ~= "rle" then
        error("PixelView: unknown encoding " .. tostring(art.encoding))
    end
    local rows = rowCache[art]
    if rows == nil then
        rows = {}
        local above = ""
        for y, text in ipairs(art.rows) do
            above = ExpandRow(text, above)
            rows[y] = above
        end
        rowCache[art] = rows
    end
    return rows
end


-- ===== Picture -> list of pieces =====

-- A "piece" is one ImageControl:
--   { col = column, row = row, length = number of dots it covers, color = "#RRGGBB" }
-- col and row count from 0 in the reduced grid (after step).
-- Without merge, length is always 1.
--
-- The list is made once per picture, step and merge, and remembered.
local pieceCache = setmetatable({}, { __mode = "k" })   -- forget pictures that are no longer used

local function Pieces(art, step, merge)
    local key = step .. (merge and "m" or "")
    local byArt = pieceCache[art]
    if byArt == nil then
        byArt = {}
        pieceCache[art] = byArt
    end
    if byArt[key] ~= nil then
        return byArt[key]
    end

    local transparent = PixelView.TRANSPARENT_KEY
    local rows = RowsOf(art)
    local pieces = {}
    local row = 0
    for y = 1, #rows, step do
        local line = rows[y]
        local last = nil   -- the piece we may still extend to the right
        local col = 0
        for x = 1, #line, step do
            local ch = line:sub(x, x)
            local color = nil
            if ch ~= transparent then
                color = art.palette[ch]
            end
            if color == nil then
                last = nil
            elseif merge and last ~= nil and last.color == color then
                last.length = last.length + 1
            else
                last = { col = col, row = row, length = 1, color = color }
                table.insert(pieces, last)
            end
            col = col + 1
        end
        row = row + 1
    end
    byArt[key] = pieces
    return pieces
end


-- ===== The view =====

-- options:
--   parent, templateIndex   where to create ImageControls, and from which template (required)
--   x, y                    position of the top-left dot (default 0, 0)
--   spacing                 distance between dots (default 4)
--   step                    1 = every dot, 2 = every 2nd dot, ... (default 1)
--   merge                   share ImageControls between same-colored neighbors (default false)
--   dotSize                 width and height of one dot (default: the same as spacing, so there are no gaps).
--                           The ImageControls are resized to this, so the template's own size does not matter.
--   pivotX                  the template's horizontal pivot: 0 = left, 0.5 = center, 1 = right (default 0.5)
function PixelView.New(options)
    -- Stop here with a clear message if something required is missing.
    -- (error level 2 points the message at the line that called New.)
    if type(options) ~= "table" then
        error("PixelView: New needs a table, like PixelView.New({ parent = ..., templateIndex = ... })", 2)
    end
    if options.parent == nil then
        error("PixelView: parent is required in PixelView.New({ ... })", 2)
    end
    if options.templateIndex == nil then
        error("PixelView: templateIndex is required in PixelView.New({ ... })", 2)
    end
    local view = {
        options = options,
        images = {},       -- created ImageControls (reused)
        colors = {},       -- the color last given to each ImageControl
        widths = {},       -- the width last given to each ImageControl
        shown = 0,         -- how many are visible now
        currentArt = nil,
    }
    return setmetatable(view, PixelView)
end

-- Settings with their defaults. Used only inside this file.
local function StepOf(view)
    return view.options.step or 1
end

local function SpacingOf(o)
    return o.spacing or 4
end

local function DotSizeOf(o)
    return o.dotSize or SpacingOf(o)
end

-- How many ImageControls this picture needs with this view's settings.
-- The list of pieces is remembered, so this also makes the first Show faster.
function PixelView:Count(art)
    if art == nil then
        return 0   -- like Show(nil), a missing picture needs nothing
    end
    return #Pieces(art, StepOf(self), self.options.merge)
end

-- Make the list of pieces now, so the first Show does less work.
-- Count does the same, so this is needed only when Count is not used.
function PixelView:Prepare(art)
    if art ~= nil then
        Pieces(art, StepOf(self), self.options.merge)
    end
end

-- Create one ImageControl from the template, hidden, with the height of one dot.
-- (The width is set by Show, because a merged piece is wider.)
local function NewImage(o)
    local image = game.InstantiateClientUIControl(o.templateIndex, o.parent)
    image:SetActive(false)
    image.sizeDeltaY = DotSizeOf(o)
    return image
end

-- Create up to count ImageControls now, until there are total of them.
-- Returns true when there are total of them.
-- Call it once per frame (for example in OnUpdate) until it returns true.
function PixelView:Grow(count, total)
    local made = 0
    while #self.images < total and made < count do
        table.insert(self.images, NewImage(self.options))
        made = made + 1
    end
    return #self.images >= total
end

function PixelView:Clear()
    for i = 1, self.shown do
        self.images[i]:SetActive(false)
    end
    self.shown = 0
    self.currentArt = nil
end

function PixelView:Show(art)
    if art == nil then
        self:Clear()
        return
    end
    if art == self.currentArt then
        return
    end
    local o = self.options
    local spacing = SpacingOf(o)
    local dotSize = DotSizeOf(o)
    local pivotX = o.pivotX or 0.5
    local pieces = Pieces(art, StepOf(self), o.merge)

    -- Create any that are still missing (all at once, so this can be slow; see Grow)
    while #self.images < #pieces do
        table.insert(self.images, NewImage(o))
    end

    local x = o.x or 0
    local y = o.y or 0
    for i, piece in ipairs(pieces) do
        local image = self.images[i]
        -- A wide piece grows around its pivot, so move it right by pivotX of the extra width
        image.anchoredPositionX = x + (piece.col + pivotX * (piece.length - 1)) * spacing
        image.anchoredPositionY = y - piece.row * spacing   -- larger Y is higher, so lower rows get smaller Y
        -- One dot wide, or for a merged piece, its dots and the gaps between them.
        -- Written only when it changes, so showing another picture costs little.
        local width = dotSize + (piece.length - 1) * spacing
        if self.widths[i] ~= width then
            image.sizeDeltaX = width
            self.widths[i] = width
        end
        if self.colors[i] ~= piece.color then
            image.imageColor = ToColorValue(piece.color)
            self.colors[i] = piece.color
        end
        image:SetActive(true)
    end
    -- Hide the ones the previous picture used but this one does not
    for i = #pieces + 1, self.shown do
        self.images[i]:SetActive(false)
    end
    self.shown = #pieces
    self.currentArt = art
end

return PixelView
