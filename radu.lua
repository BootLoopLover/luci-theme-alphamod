module("luci.controller.radu", package.seeall)

function index()
    entry({"admin", "system", "radu"}, call("action_page"), _("Custom Background"), 99)
end

function action_page()
    local http = require "luci.http"
    local fs   = require "nixio.fs"

    local target_dir = "/www/luci-static/alpha/background/"
    local dashboard_file = target_dir .. "dashboard.png"
    local login_file = target_dir .. "login.png"
    local tmp_file = "/tmp/radu_upload"

    local success = false
    local message = nil

    -- Ensure target folder exists
    if not fs.stat(target_dir) then fs.mkdir(target_dir) end

    -- === Upload file ===
    if http.formvalue("upload") and http.formvalue("file") then
        local out = io.open(tmp_file, "wb")
        if out then
            http.setfilehandler(function(meta, chunk, eof)
                if chunk then out:write(chunk) end
                if eof then out:close() end
            end)
            http.formvalue("file")
        else
            message = "❌ Cannot write temp file"
        end
    end

    -- === Image URL ===
    local image_url = http.formvalue("image_url")
    if image_url then
        os.execute(string.format('curl -s -L -o "%s" "%s"', tmp_file, image_url))
    end

    -- === Copy to dashboard & login ===
    if fs.stat(tmp_file) and fs.stat(tmp_file).size > 0 then
        -- Backup old files
        if fs.stat(dashboard_file) then fs.rename(dashboard_file, dashboard_file..".bak") end
        if fs.stat(login_file) then fs.rename(login_file, login_file..".bak") end

        -- Copy tmp_file
        fs.copy(tmp_file, dashboard_file)
        fs.copy(tmp_file, login_file)

        fs.remove(tmp_file)

        success = true
        message = "✅ Background updated! dashboard.png & login.png overwritten."
    end

    luci.template.render("radu", {success=success, message=message})
end