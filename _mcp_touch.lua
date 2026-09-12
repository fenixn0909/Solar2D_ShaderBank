
-- MCP Touch: Simulates touch events from control file commands
local controlFile = "/var/folders/10/hydfn9d9191_df9jxf68zv780000gn/T/solar2d_touch_Solar2D_ShaderBank.control"
local infoFile = "/var/folders/10/hydfn9d9191_df9jxf68zv780000gn/T/solar2d_display_Solar2D_ShaderBank.json"
local checkInterval = 100  -- Check for commands every 100ms
local json = require("json")

-- Stored target from "began" phase for consistent event dispatch
local touchTarget = nil
local touchStartX, touchStartY = 0, 0

-- Helper to read and consume control file
local function readControlFile()
    local file = io.open(controlFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        os.remove(controlFile)  -- Consume the command
        return content
    end
    return nil
end

-- Parse command string
local function parseCommand(content)
    local parts = {}
    for part in string.gmatch(content, "[^,]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Check if object has a touch listener
local function hasTouchListener(obj)
    -- Check for touch_handler (used by some frameworks)
    if obj.touch_handler then return true end
    -- Check for _tableListeners.touch (standard Solar2D listener table)
    if obj._tableListeners and obj._tableListeners.touch then return true end
    -- Check for _functionListeners.touch
    if obj._functionListeners and obj._functionListeners.touch then return true end
    return false
end

-- Find the topmost touchable object at coordinates via hit testing
local function findHitObject(group, x, y)
    if not group or not group.numChildren then return nil end

    -- Traverse in reverse order (higher index = on top)
    for i = group.numChildren, 1, -1 do
        local child = group[i]
        if child and child.isVisible ~= false then
            -- Recurse into groups first
            if child.numChildren then
                local hit = findHitObject(child, x, y)
                if hit then return hit end
            end

            -- Check if this object is within bounds
            if child.contentBounds then
                local bounds = child.contentBounds
                if x >= bounds.xMin and x <= bounds.xMax and
                   y >= bounds.yMin and y <= bounds.yMax then
                    -- Check if it has a touch listener
                    if hasTouchListener(child) then
                        return child
                    end
                end
            end
        end
    end
    return nil
end

-- Dispatch a touch event to appropriate target
local function dispatchTouch(phase, x, y)
    local target = nil

    if phase == "began" then
        -- Find the topmost touchable object at this point
        target = findHitObject(display.getCurrentStage(), x, y)
        if target then
            touchTarget = target
            touchStartX, touchStartY = x, y
        end
    else
        target = touchTarget
        if phase == "ended" then
            touchTarget = nil
        end
    end

    local event = {
        name = "touch",
        phase = phase,
        x = x,
        y = y,
        xStart = touchStartX or x,
        yStart = touchStartY or y,
        time = system.getTimer(),
        target = target
    }

    if target then
        target:dispatchEvent(event)
    else
        -- Fallback to Runtime if no target found
        Runtime:dispatchEvent(event)
    end
end

-- Write display info to file
local function writeDisplayInfo()
    local info = {
        contentWidth = display.contentWidth,
        contentHeight = display.contentHeight,
        actualContentWidth = display.actualContentWidth,
        actualContentHeight = display.actualContentHeight,
        screenOriginX = display.screenOriginX,
        screenOriginY = display.screenOriginY
    }

    local file = io.open(infoFile, "w")
    if file then
        file:write(json.encode(info))
        file:close()
    end
end

-- Execute a tap at coordinates
local function executeTap(x, y)
    print("[MCP Touch] Tap at (" .. x .. ", " .. y .. ")")

    -- Dispatch "began" phase
    dispatchTouch("began", x, y)

    -- Short delay, then dispatch "ended" phase
    timer.performWithDelay(50, function()
        dispatchTouch("ended", x, y)
    end)
end

-- Execute a drag from (x1,y1) to (x2,y2) over duration ms
local function executeDrag(x1, y1, x2, y2, duration)
    print("[MCP Touch] Drag from (" .. x1 .. ", " .. y1 .. ") to (" .. x2 .. ", " .. y2 .. ") over " .. duration .. "ms")

    local steps = math.max(1, math.floor(duration / 16))  -- ~60fps
    local stepDelay = duration / steps

    -- Dispatch "began" at start position
    dispatchTouch("began", x1, y1)

    -- Dispatch "moved" events at interpolated positions
    for i = 1, steps do
        timer.performWithDelay(math.floor(stepDelay * i), function()
            local t = i / steps
            local x = x1 + (x2 - x1) * t
            local y = y1 + (y2 - y1) * t
            dispatchTouch("moved", x, y)

            -- Dispatch "ended" after the final moved event
            if i == steps then
                timer.performWithDelay(16, function()
                    dispatchTouch("ended", x2, y2)
                end)
            end
        end)
    end
end

-- Check control file for commands
local function checkControl()
    local content = readControlFile()
    if content then
        local parts = parseCommand(content)
        local cmd = parts[1]

        if cmd == "tap" then
            local x = tonumber(parts[2])
            local y = tonumber(parts[3])
            if x and y then
                executeTap(x, y)
            else
                print("[MCP Touch] Invalid tap coordinates")
            end
        elseif cmd == "drag" then
            local x1 = tonumber(parts[2])
            local y1 = tonumber(parts[3])
            local x2 = tonumber(parts[4])
            local y2 = tonumber(parts[5])
            local dur = tonumber(parts[6])
            if x1 and y1 and x2 and y2 and dur then
                executeDrag(x1, y1, x2, y2, dur)
            else
                print("[MCP Touch] Invalid drag parameters")
            end
        else
            print("[MCP Touch] Unknown command: " .. tostring(cmd))
        end
    end
end

-- Initialize
writeDisplayInfo()  -- Write display info on startup
print("[MCP Touch] Module initialized - listening for touch commands")

-- Start polling for commands
timer.performWithDelay(checkInterval, checkControl, 0)
