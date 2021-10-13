local api, CHILDS, CONTENTS = ...

local json = require "json"
local helper = require "helper"
local anims = require(api.localized "anims")

local font, info_font
local white = resource.create_colored_texture(1,1,1)

local schedule = {}
local next_talks = {}
local last_check_min = 0

local M = {}

local function rgba(base, a)
    return base[1], base[2], base[3], a
end

function M.updated_config_json(config)
    font = resource.load_font(api.localized("font.ttf"))
    info_font = resource.load_font(api.localized("font.ttf"))
end

function M.updated_schedule_json(new_schedule)
    print "new schedule"
    schedule = new_schedule
end

local function wrap(str, font, size, max_w)
    local lines = {}
    local space_w = font:width(" ", size)

    local remaining = max_w
    local line = {}
    for non_space in str:gmatch("%S+") do
        local w = font:width(non_space, size)
        if remaining - w < 0 then
            lines[#lines+1] = table.concat(line, "")
            line = {}
            remaining = max_w
        end
        line[#line+1] = non_space
        line[#line+1] = " "
        remaining = remaining - w - space_w
    end
    if #line > 0 then
        lines[#lines+1] = table.concat(line, "")
    end
    return lines
end

local function check_next_talk()
    local now = api.clock.unix()
    local check_min = math.floor(now / 60)
    if check_min == last_check_min then
        return
    end
    last_check_min = check_min
    
    -- Search all next talks
    next_talks = {}
    for idx = 1, #schedule do
        local talk = schedule[idx]

        -- Just started?
        if now > talk.start_unix and 
           now < talk.end_unix and
           talk.start_unix + 15 * 60 > now
        then
           next_talks[#next_talks+1] = talk
        end

        -- Starting soon
        if talk.start_unix > now and #next_talks < 20 then
            next_talks[#next_talks+1] = talk
        end
    end

    pp(next_talks)
end

local function view_all_talks(starts, ends, config, x1, y1, x2, y2)
    local title_size = config.font_size or 70
    local align = "left"
    local default_color = {helper.parse_rgb("#ffffff")}

    local a = anims.Area(x2 - x1, y2 - y1)

    local S = starts
    local E = ends

    local time_size = title_size
    local info_size = math.floor(title_size * 0.8)

    local split_x
    if align == "left" then
        split_x = font:width("In 60 min", title_size)*1.5
    else
        split_x = 0
    end

    local x, y = 0, 0

    local function text(...)
        return a.add(anims.moving_font(S, E, font, ...))
    end

    if #schedule == 0 then
        text(split_x, y, "Fetching talks...", title_size, rgba(default_color,1))
    elseif #next_talks == 0 and #schedule > 0 and sys.now() > 30 then
        text(split_x, y, "No more talks :(", title_size, rgba(default_color,1))
    end

    local now = api.clock.unix()

    for idx = 1, #next_talks do
        local talk = next_talks[idx]

        local title_lines = wrap(
            talk.title,
            font, title_size, a.width - split_x
        )

        local subtitle_lines = wrap(
            talk.subtitle,
            font, info_size, a.width - split_x
        )

        local info_text = talk.place .. ", von/mit " .. table.concat(talk.speakers, ", ")
        if #talk.speakers == 0
            info_text = talk.place
        end

        local info_lines = wrap(
            info_text, 
            font, info_size, a.width - split_x
        )

        if y + #title_lines * title_size + #subtitle_lines * info_size + #info_lines * info_size > a.height then
            break
        end

        -- time
        local time
        local til = talk.start_unix - now
        if til > -60 and til < 60 then
            time = "Now"
            local w = font:width(time, time_size)+time_size
            text(x+split_x-w, y, time, time_size, 0,.6,0.57,1)
        elseif til > 0 and til < 15 * 60 then
            time = string.format("In %d min", math.floor(til/60))
            local w = font:width(time, time_size)+time_size
            text(x+split_x-w, y, time, time_size, 0,.6,0.57,1)
        elseif talk.start_unix > now then
            time = talk.start_str
            local w = font:width(time, time_size)+time_size
            text(x+split_x-w, y, time, time_size, rgba(default_color, 1))
        else
            time = string.format("%d min ago", math.ceil(-til/60))
            local w = font:width(time, time_size)+time_size
            text(x+split_x-w, y, time, time_size, rgba(default_color,.8))
        end


        -- title
        for idx = 1, #title_lines do
            text(x+split_x, y, title_lines[idx], title_size, rgba(default_color,1))
            y = y + title_size
        end
        y = y + 3

        -- subtitle
        for idx = 1, #subtitle_lines do
            text(x+split_x, y, subtitle_lines[idx], info_size, rgba(default_color,1))
            y = y + info_size
        end
        y = y + 3

        -- info
        for idx = 1, #info_lines do
            text(x+split_x, y, info_lines[idx], info_size, rgba(default_color,.8))
            y = y + info_size
        end
        y = y + 20
    end

    for now in api.frame_between(starts, ends) do
        a.draw(now, x1, y1, x2, y2)
    end
end

function M.task(starts, ends, config, x1, y1, x2, y2)
    check_next_talk()
    return view_all_talks(starts, ends, config, x1, y1, x2, y2)
end

function M.can_show(config)
    return true
end

return M
