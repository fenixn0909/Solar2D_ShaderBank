
-- MCP Logger: Redirects print() to file for MCP server access
local mcp_log_file = "/var/folders/10/hydfn9d9191_df9jxf68zv780000gn/T/corona_log_Solar2D_ShaderBank.txt"
local original_print = print

-- Truncate log file on simulator start (clear old logs)
do
    local file = io.open(mcp_log_file, "w")
    if file then
        file:write("=== Solar2D Simulator Started ===\n")
        file:close()
    end
end

_G.print = function(...)
    local args = {...}
    local message = ""
    for i, v in ipairs(args) do
        if i > 1 then message = message .. "\t" end
        message = message .. tostring(v)
    end

    -- Call original print
    original_print(...)

    -- Also write to MCP log file (append mode)
    local file = io.open(mcp_log_file, "a")
    if file then
        file:write(message .. "\n")
        file:flush()
        file:close()
    end
end

print("[MCP] Logging initialized - output will be captured for Claude")
