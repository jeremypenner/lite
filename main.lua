renderer = {}

function renderer.show_debug(show)
    -- useful?
end

function renderer.get_size()
    return love.graphics.getWidth(), love.graphics.getHeight()
end

function renderer.begin_frame()
    love.graphics.origin()
    love.graphics.clear(love.graphics.getBackgroundColor())
end

function renderer.end_frame()
    love.graphics.present()
end

function renderer.set_clip_rect(x, y, w, h)
    love.graphics.setScissor(x, y, w, h)
end

function renderer.set_litecolor(color)
    if not color or #color < 3 then color = { 255, 255, 255, 255 } end
    local alpha = 1
    if #color == 4 then
        alpha = color[4] / 255
    end
    love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255, alpha)
end
function renderer.draw_rect(x, y, w, h, color)
    renderer.set_litecolor(color)
    love.graphics.rectangle("fill", x, y, w, h)
end

function renderer.draw_text(font, text, x, y, color)
    renderer.set_litecolor(color)
    local textobj = love.graphics.newText(font.font, text)
    love.graphics.draw(textobj, x, y)
    return x + textobj:getWidth()
end

renderer.font = {}
function renderer.font.load(filename, size)
    local font = love.graphics.newFont(filename, size)
    return {
        font = font,
        set_tab_width = function(self, n)
            -- todo? Ignore?
        end,
        get_width = function(self, text)
            return self.font:getWidth(text)
        end,
        get_height = function(self)
            return self.font:getHeight()
        end
    }
end

system = {}
function system.poll_event()
    local function button_name(button)
        if button == 1 then return 'left' end
        if button == 2 then return 'right' end
        if button == 3 then return 'middle' end
        return '?'
    end
    local function key_name(key)
        if key:sub(1, 2) == "kp" then
            return "keypad " .. key:sub(3)
        end
        if key:sub(2) == "ctrl" or key:sub(2) == "shift" or key:sub(2) == "alt" or key:sub(2) == "gui" then
            if key:sub(1, 1) == "l" then return "left " .. key:sub(2) end
            return "right " .. key:sub(2)
        end
        return key
    end
    love.event.pump()
    for ev, a, b, c, d, e, f in love.event.poll() do
        if ev == 'quit' then
            return 'quit'
        elseif ev == 'resize' then
            return 'resized', a, b
        elseif ev == 'filedropped' then
            return 'filedropped', a:getFilename(), love.mouse.getX(), love.mouse.getY()
        elseif ev == 'keypressed' then
            return 'keypressed', key_name(a or b)
        elseif ev == 'keyreleased' then
            return 'keyreleased', key_name(a or b)
        elseif ev == 'textinput' then
            return 'textinput', a
        elseif ev == 'mousepressed' then
            return 'mousepressed', button_name(c), a, b, e
        elseif ev == 'mousereleased' then
            return 'mousereleased', button_name(c), a, b
        elseif ev == 'mousemoved' then
            return 'mousemoved', a, b, c, d
        elseif ev == 'wheelmoved' then
            return 'mousewheel', b
        end
    end
end

function system.wait_event(n)
    -- no love2d equivalent
    return false
end

function system.set_cursor(cursor)
    if cursor == nil then cursor = 'arrow' end
    if cursor == 'sizeh' then cursor = 'sizewe' end
    if cursor == 'sizev' then cursor = 'sizens' end
    love.mouse.setCursor(love.mouse.getSystemCursor(cursor))
end

function system.set_window_title(title)
    love.window.setTitle(title)
end

function system.set_window_mode(mode)
    love.window.setFullscreen(mode == 'fullscreen')
    if mode == nil or mode == 'normal' then love.window.restore() end
    if mode == 'maximized' then love.window.maximize() end
end

function system.window_has_focus()
    return love.window.hasFocus()
end

function system.show_confirm_dialog(title, msg)
    return love.window.showMessageBox(title, message, { 'Yes', 'No', escapebutton = 2 }, 'warning') == 1
end

function system.chdir(dir)
    -- not possible with love2d
end

function system.list_dir(path)
    if path == '.' then path = '' end
    local info = love.filesystem.getInfo(path)
    if info and info.type == 'directory' then
        return love.filesystem.getDirectoryItems(path)
    end
    return nil, "Not a directory"
end

function system.absolute_path(path)
    return path -- love.filesystem.getRealDirectory(path)
end

function system.get_file_info(path)
    local info = love.filesystem.getInfo(path)
    if info then
        local type = nil
        if info.type == 'file' then
            type = 'file'
        elseif info.type == 'directory' then
            type = 'dir'
        end
        return {
            modified = info.modtime,
            size = info.size,
            type = type
        }
    else
        return nil, "Doesn't exist"
    end
end

function system.get_clipboard()
    return love.system.getClipboardText()
end

function system.set_clipboard(text)
    love.system.setClipboardText(text)
end

function system.get_time()
    return love.timer.getTime()
end

function system.sleep(s)
    love.timer.sleep(s)
end

function system.exec(cmd)
    -- ehhhh todo I guess
end

function system.fuzzy_match(str, ptn)
    local istr = 1
    local iptn = 1
    local score = 0
    local run = 0
    while istr <= str:len() and iptn <= ptn:len() do
        while str:sub(istr,istr) == ' ' do istr = istr + 1 end
        while ptn:sub(iptn,iptn) == ' ' do iptn = iptn + 1 end
        local cstr = str:sub(istr,istr)
        local cptn = ptn:sub(iptn,iptn)
        if cstr:lower() == cptn:lower() then
            score = score + (run * 10)
            if cstr ~= cptn then score = score - 1 end
            istr = istr + 1
            iptn = iptn + 1
        else
            score = score - 10
            run = 0
        end
        istr = istr + 1
    end
    if iptn > ptn:len() then
        return score - str:len() + istr - 1
    end
end

table.unpack = unpack

core = ""
function love.run()
    ARGS = love.arg.parseGameArguments(arg)
    VERSION = "1.11"
    PLATFORM = "love2d"
    SCALE = love.graphics.getDPIScale()
    EXEDIR = ""
    PATHSEP = package.config:sub(1, 1)
    love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), love.filesystem.getSourceBaseDirectory())
    package.path = love.filesystem.getWorkingDirectory() .. '/data/?.lua;' .. love.filesystem.getWorkingDirectory() .. '/data/?/init.lua;' .. package.path
    core = require('core')
    local style = require('core.style')
    style.code_font = renderer.font.load(EXEDIR .. "/data/fonts/monospace.ttf", 15 * SCALE)
    core.init()
    return core.run
end
