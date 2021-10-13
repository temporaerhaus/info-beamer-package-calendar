local api, CHILDS, CONTENTS = ...

local json = require "json"
local helper = require "helper"
local anims = require(api.localized("anims"))

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

        -- Now running?
        if now > talk.start_unix and 
           now < talk.end_unix
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
    local default_color = {helper.parse_rgb("#ffffff")}

    local a = anims.Area(x2 - x1, y2 - y1)

    local S = starts
    local E = ends

    local date_size = title_size
    local info_size = math.floor(title_size * 0.85)
    local time_size = info_size

    local split_x = font:width("Bis 20:15", title_size)*1.5

    local x, y = 0, 0

    local function text(...)
        return a.add(anims.moving_font(S, E, font, ...))
    end

    if #schedule == 0 then
        text(split_x, y, "Fetching events...", title_size, rgba(default_color,1))
    elseif #next_talks == 0 and #schedule > 0 and sys.now() > 30 then
        text(split_x, y, "No events in calendar :(", title_size, rgba(default_color,1))
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

        local info_text = talk.place .. ", von/mit "
        if #talk.speakers == 0 then
            info_text = talk.place
        end

        if y + #title_lines * title_size + #subtitle_lines * info_size + info_size > a.height then
            break
        end

        local first_line_y = y
        -- left area

        -- date
        local date
        if now > talk.start_unix and now < talk.end_unix then
            date = "Jetzt"
        else
            date = talk.start_date
        end
        local w = font:width(date, date_size)+date_size
        text(x+split_x-w, y, date, date_size, rgba(default_color, 1))

        y = y + date_size + 3

        -- time
        local time
        local til = talk.start_unix - now
        if talk.start_unix > now then
            time = talk.start_str
            local w = font:width(time, time_size)+time_size
            text(x+split_x-w, y, time, time_size, rgba(default_color, 1))
        else
            time = "Bis " .. talk.end_str
            local w = font:width(time, time_size)+time_size
            text(x+split_x-w, y, time, time_size, rgba(default_color,.8))
        end

        y = y + time_size + 3

        -- weekday
        local wday = talk.start_weekday
        local w = font:width(wday, info_size)+info_size
        text(x+split_x-w, y, wday, info_size, rgba(default_color, .8))


        -- right area
        y = first_line_y

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
        y = y + 6


        -- info
        text(x+split_x, y, info_text, info_size, rgba(default_color,.8))
        if #talk.speakers > 0 then
            local w = font:width(info_text, info_size)
            a.add(anims.moving_font_list(S, E, font, x+split_x+w+5, y, talk.speakers, info_size, rgba(default_color,.8)))
        end
        y = y + info_size


        -- for the next block
        y = y + 40
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
