
-- MCP Screenshot: Captures screenshots periodically when recording is enabled
local lfs = require("lfs")
local screenshotDir = "/var/folders/10/hydfn9d9191_df9jxf68zv780000gn/T/solar2d_screenshots_Solar2D_ShaderBank"
local controlFile = "/var/folders/10/hydfn9d9191_df9jxf68zv780000gn/T/solar2d_screenshots_Solar2D_ShaderBank.control"
local captureInterval = 100  -- 100ms between captures
local screenshotCount = 0
local recordingEndTime = 0

-- Helper to check if file exists
local function fileExists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

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

-- Clear screenshot directory on start
local function clearScreenshotDir()
    -- Create directory if it doesn't exist
    lfs.mkdir(screenshotDir)
    -- Remove existing screenshots
    for file in lfs.dir(screenshotDir) do
        if file ~= "." and file ~= ".." then
            os.remove(screenshotDir .. "/" .. file)
        end
    end
end

-- Check if currently recording
local function isRecording()
    return system.getTimer() < recordingEndTime
end

-- Helper to copy file (works across volumes)
local function copyFile(src, dst)
    local infile = io.open(src, "rb")
    if not infile then return false end
    local content = infile:read("*all")
    infile:close()

    local outfile = io.open(dst, "wb")
    if not outfile then return false end
    outfile:write(content)
    outfile:close()
    return true
end

-- Capture screenshot
local function captureScreen()
    if not isRecording() then return end

    screenshotCount = screenshotCount + 1
    local filename = string.format("screenshot_%03d.jpg", screenshotCount)
    local fullPath = screenshotDir .. "/" .. filename

    -- Capture the display to Solar2D's temp directory
    display.save(display.currentStage, {
        filename = filename,
        baseDir = system.TemporaryDirectory,
        captureOffscreenArea = false,
        isFullResolution = false
    })

    -- Copy from Solar2D temp to our /tmp/ screenshot directory
    local tempPath = system.pathForFile(filename, system.TemporaryDirectory)
    if tempPath then
        if copyFile(tempPath, fullPath) then
            os.remove(tempPath)  -- Clean up temp file
        end
    end
end

-- Capture a single on-demand screenshot (not part of recording sequence)
local function captureOnDemand()
    local filename = "screenshot_latest.jpg"
    local fullPath = screenshotDir .. "/" .. filename

    -- Capture the display to Solar2D's temp directory
    display.save(display.currentStage, {
        filename = filename,
        baseDir = system.TemporaryDirectory,
        captureOffscreenArea = false,
        isFullResolution = false
    })

    -- Copy from Solar2D temp to our /tmp/ screenshot directory
    local tempPath = system.pathForFile(filename, system.TemporaryDirectory)
    if tempPath then
        if copyFile(tempPath, fullPath) then
            os.remove(tempPath)  -- Clean up temp file
            print("[MCP Screenshot] On-demand capture saved")
        end
    end
end

-- Check control file for recording commands
local function checkControl()
    local content = readControlFile()
    if not content then return end

    -- Check for "now" command (on-demand capture)
    if content == "now" then
        captureOnDemand()
        return
    end

    local duration = tonumber(content)
    if duration == nil then
        -- Not a number, ignore
        return
    elseif duration > 0 then
        recordingEndTime = system.getTimer() + (duration * 1000)
        print("[MCP Screenshot] Recording for " .. duration .. " seconds (screenshots continue from #" .. (screenshotCount + 1) .. ")")
    elseif duration == 0 then
        -- Explicit stop command
        recordingEndTime = 0
        print("[MCP Screenshot] Recording stopped at screenshot #" .. screenshotCount)
    end
end

-- Initialize
clearScreenshotDir()
print("[MCP Screenshot] Module initialized - screenshots will be saved to: " .. screenshotDir)

-- Start timers
timer.performWithDelay(captureInterval, captureScreen, 0)
timer.performWithDelay(500, checkControl, 0)
