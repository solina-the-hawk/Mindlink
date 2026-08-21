-- =========================================================================
-- MINDLINK: A telepathic communication ledger for Mudlet.
-- Author: Solina (https://github.com/solina-the-hawk/mindlink/)
-- Version: 1.7.0
-- =========================================================================
Mindlink = Mindlink or {}

-- =========================================================================
-- Configuration Block
-- =========================================================================
Mindlink.config = {
    
    -- This controls where the Mindlink window appears on your screen, and how big it is. Adjust as needed!
    -- I strongly recommend creating a Display Border in your Mudlet profile preferences (Main Display tab) to 
    -- put this and other geyser windows into so they never overlap the main output!
    x = "-23%", y = "51%",
    width = "23%", height = "51%",
    
    -- colors: The background colors for your Mindlink tabs and window using RGB (Red, Green, Blue) values.
    colors = {
        activeTab = {r = 40, g = 60, b = 90},   
        inactiveTab = {r = 30, g = 30, b = 30}, 
        windowBg = {r = 0, g = 0, b = 0},       
    }, 

    -- fontSize: This determines the size of text in the Mindlink window. You might want it smaller or bigger
    -- depending on how big you make the window itself!
    fontSize = 9,
    
    -- timestamp: Set to false to disable timestamps, true for a default "[hh:mm:ss] ", or use a custom
    -- string like: "(HH:mm) "
    timestamp = "(HH:mm) ", 
    
    -- colorMain: Set to true to apply your custom Mindlink colors to the text in your main window as well.
    colorMain = true,
    
    -- emoteColor: Set this color to one of the XTerm256 color numbers that Achaea uses (Type COLOURS in
    -- game to see them). This is how Mindlink identifies emotes to capture them.
    emoteColor = 242,

    -- filterAll: Set to true to hide ALL captured chat from your main window, routing it exclusively to
    -- the Mindlink tabs.
    filterAll = false, 
    
    -- filteredChannels: If filterAll is false, you can use this list to hide SPECIFIC spammy channels from the 
    -- main window while keeping the rest. Set a channel to true to hide it, or false/remove it to show it.
    filteredChannels = {
        ["clt"] = false,
        ["market"] = true,
    },

    -- mutedChannels: Channels in this list will be hidden from BOTH the main window AND Mindlink's tabs.
    mutedChannels = {
        -- ["newbie"] = true,
    },

    -- gaggedStrings: Lines containing any of these strings will be hidden from Mindlink tabs, but not the main window.
    gaggedStrings = {
        -- ["A goblin smith swings his fists at you wildly"] = true,
    },

    -- ignorePatterns: This is a list of Regex patterns. If a captured line matches ANY of these patterns, it
    -- will be ignored and not sent to the Mindlink tabs or logs. (e.g., catching random combat numbers or 'writ.')
    ignorePatterns = {
        "^writ%.%s*$", 
        "^%s*[%w_]+%s+%d+%s+%d+%s+", 
        "^%s*[FB]G:%s+%d",           
    },
    
    -- allTab: The name of your catch-everything tab. If a message comes through a channel that isn't mapped 
    -- below, it will default to this tab.
    allTab = "All",
    
    -- tabNames: A list of every tab you want generated in the UI. You can name these whatever you like, 
    -- and have more or fewer, just make sure you map channels to them in the channelMap below!
    tabNames = {
        "All", "Local", "City", "Party", "Tells", "Orgs", "Misc"
    },
    
    -- channelMap: This tells Mindlink where to put incoming GMCP messages. 
    -- The left side is Achaea's internal channel prefix (e.g., "ct" for City), and the right side is 
    -- the exact name of the tab you defined in tabNames above.
    channelMap = {
        say = "Local", yell = "Local", whisper = "Local",
        shout = "Misc", 
        ct = "City", ht = "City", hnt = "City",
        party = "Party", intrepid = "Party", 
        tell = "Tells",
        newbie = "Misc", market = "Misc",
        clt = "Orgs", ot = "Orgs", 
    },
    
    -- logTabs: Choose which tabs get saved to text files on your computer. These default to false, but if
    -- you are interested in logging specific tabs, just add them here and set to true.
    logTabs = {
        ["All"] = false,
        ["Local"] = true,
        ["City"] = false,
        ["Party"] = false,
        ["Tells"] = true,
        ["Orgs"] = false,
        ["Misc"] = false,
    },

    -- highlights: The core color engine! Use Mudlet's <R,G,B> tag format for all colors here.
    highlights = {
        -- words: Force specific names or words to always be highlighted in a specific color.
        words = {
            ["Solina"] = "<125,249,255>",
        },
        -- channels: Force entire channels to be colored. (Note: say, whisper, and yell MUST be mapped 
        -- here to display properly in the Mindlink tabs).
        channels = {
            ["ct"] = "<0,191,255>",
            ["hnt"] = "<135,206,235>",
            ["ht"] = "<0,191,255>",  
            ["say"] = "<0,255,255>",
            ["whisper"] = "<0,255,255>",
            ["yell"] = "<255,255,0>",
        },
        -- linesContaining: If a message contains this exact string of text, the entire line will be painted.
        linesContaining = {
            -- Example: Enter a phrase of your choosing and watch the entire line containing it highlight!
            ["The sun shines brightly on the daisies"] = "<255,255,153>",
            -- Example: Paint all ship announcements a bright, unmissable cyan!
            ["==[CAPTAIN'S ANNOUNCEMENT:"] = "<0,255,255>",
        }
}
}

Mindlink.currentTab = Mindlink.currentTab or Mindlink.config.allTab

-- =========================================================================
 -- Runtime States
 -- Internal variables used for math and tracking. Do not edit!
 -- =========================================================================
Mindlink.consoles = Mindlink.consoles or {}
Mindlink.tabs = Mindlink.tabs or {}
Mindlink.events = Mindlink.events or {}

function Mindlink.echo(msg)
    cecho("\n<dodger_blue>[Mindlink]:<reset> " .. msg)
end

-- =========================================================================
-- Universal Color Parser
-- =========================================================================
function Mindlink.parseColor(colorStr)
    if not colorStr then return 192, 192, 192 end
    if type(colorStr) == "table" then return colorStr[1], colorStr[2], colorStr[3] or 255 end
    local clean = string.gsub(colorStr, "[<> ]", "")
    if color_table[clean] then return unpack(color_table[clean]) end
    local r, g, b = string.match(clean, "(%d+),(%d+),(%d+)")
    if r then return tonumber(r), tonumber(g), tonumber(b) end
    return 192, 192, 192
end

-- =========================================================================
-- Automated Logging
-- =========================================================================
function Mindlink.logMessage(tabName, rawText)
    if not Mindlink.config.logTabs[tabName] then return end
    
    local plainText = string.gsub(rawText, "\27%[[%d;]*m", "")
    
    -- 1. Check and create the master Mindlink folder
    local baseDir = getMudletHomeDir() .. "/Mindlink"
    if not lfs.attributes(baseDir) then lfs.mkdir(baseDir) end
    
    -- 2. Check and create the nested Logs folder
    local logDir = baseDir .. "/Logs"
    if not lfs.attributes(logDir) then lfs.mkdir(logDir) end
    
    local dateStr = os.date("%Y-%m-%d")
    local timeStr = os.date("%H:%M:%S")
    local fileName = logDir .. "/" .. tabName .. "_" .. dateStr .. ".txt"
    
    local file = io.open(fileName, "a")
    if file then
        file:write("[" .. timeStr .. "] " .. plainText .. "\n")
        file:close()
    end
end

-- =========================================================================
-- UI Creation & Interaction
-- =========================================================================
function Mindlink.createUI()
    Mindlink.container = Geyser.Container:new({
        name = "MindlinkContainer",
        x = Mindlink.config.x, y = Mindlink.config.y,
        width = Mindlink.config.width, height = Mindlink.config.height,
    })

    Mindlink.tabBar = Geyser.HBox:new({
        name = "MindlinkTabBar", x = 0, y = 0,
        width = "100%", height = "25px",
    }, Mindlink.container)

    for _, tabName in ipairs(Mindlink.config.tabNames) do
        Mindlink.tabs[tabName] = Geyser.Label:new({
            name = "MindlinkTab_" .. tabName,
        }, Mindlink.tabBar)
        
        Mindlink.tabs[tabName]:echo("<center>" .. tabName .. "</center>")
        Mindlink.tabs[tabName]:setClickCallback("Mindlink.switchTab", tabName)

        Mindlink.consoles[tabName] = Geyser.MiniConsole:new({
            name = "MindlinkWin_" .. tabName,
            x = 0, y = "25px", width = "100%", height = "-25px",
            color = "black",
        }, Mindlink.container)
        
        Mindlink.consoles[tabName]:setFontSize(Mindlink.config.fontSize)
        Mindlink.consoles[tabName]:setWrap(80)
        
        local bg = Mindlink.config.colors.windowBg
        Mindlink.consoles[tabName]:setColor(bg.r, bg.g, bg.b)
        Mindlink.consoles[tabName]:hide()
    end

    Mindlink.switchTab(Mindlink.currentTab)
end

function Mindlink.switchTab(tabName)
    local activeCol = Mindlink.config.colors.activeTab
    local inactiveCol = Mindlink.config.colors.inactiveTab

    if Mindlink.currentTab and Mindlink.consoles[Mindlink.currentTab] then
        Mindlink.consoles[Mindlink.currentTab]:hide()
        Mindlink.tabs[Mindlink.currentTab]:setColor(inactiveCol.r, inactiveCol.g, inactiveCol.b)
    end

    Mindlink.consoles[tabName]:show()
    Mindlink.tabs[tabName]:setColor(activeCol.r, activeCol.g, activeCol.b)
    Mindlink.currentTab = tabName
end

-- =========================================================================
-- Word Highlighting Engine (Channels Handled Externally Now)
-- =========================================================================
function Mindlink.applyWordHighlights(text)
    local result = text
    -- SLEDGEHAMMER: Strip absolutely every Mudlet tag to guarantee a clean text match
    local plainText = string.gsub(result, "<[^>]+>", "")

    for str, color in pairs(Mindlink.config.highlights.linesContaining) do
        if string.find(plainText, str, 1, true) then
            local r, g, b = Mindlink.parseColor(color)
            local safeColor = string.format("<%d,%d,%d>", r, g, b)
            -- Apply the color and use plainText to wipe out any native game tags
            result = safeColor .. plainText
            break 
        end
    end

    local function smartWordHighlight(word, color)
        local r, g, b = Mindlink.parseColor(color)
        local safeColor = string.format("<%d,%d,%d>", r, g, b)
        local escapedWord = word:gsub("([^%w])", "%%%1")
        local pattern = string.match(word, "^%a+$") and ("(%f[%a]" .. escapedWord .. "%f[%A])") or ("(" .. escapedWord .. ")")
        
        local out = ""
        local activeColor = string.match(result, "^(<[^>]+>)") or "<192,192,192>"
        local lastEnd = 1
        
        for colorTag in string.gmatch(result, "<[^>]+>") do
            local startIdx, endIdx = string.find(result, colorTag, lastEnd, true)
            local textSegment = string.sub(result, lastEnd, startIdx - 1)
            
            textSegment = string.gsub(textSegment, pattern, safeColor .. "%1" .. activeColor)
            
            out = out .. textSegment .. colorTag
            activeColor = colorTag
            lastEnd = endIdx + 1
        end
        
        local finalSegment = string.sub(result, lastEnd)
        finalSegment = string.gsub(finalSegment, pattern, safeColor .. "%1" .. activeColor)
        out = out .. finalSegment
        
        result = out
    end

    for word, color in pairs(Mindlink.config.highlights.words) do
        smartWordHighlight(word, color)
    end

    return result
end

-- =========================================================================
-- Tab Printing Helper
-- =========================================================================
function Mindlink.appendChat(targetTab, formattedText, timeStr)
    local console = Mindlink.consoles[targetTab]
    if not console then return end

    console:decho(timeStr .. formattedText .. "\n")

    if Mindlink.config.allTab and targetTab ~= Mindlink.config.allTab then
        local allConsole = Mindlink.consoles[Mindlink.config.allTab]
        if allConsole then
            allConsole:decho(timeStr .. formattedText .. "\n")
        end
    end
end

-- =========================================================================
-- GMCP Chat Processing (Decoupled Geyser/Main Pipelines)
-- =========================================================================
function Mindlink.onGMCPChat()
    if not gmcp.Comm or not gmcp.Comm.Channel or not gmcp.Comm.Channel.Text then return end
    
    local channel = gmcp.Comm.Channel.Text.channel
    local text = gmcp.Comm.Channel.Text.text
    
    if Mindlink.config.debug then
        cecho(string.format("\n<yellow>[Mindlink Debug] Raw Channel ID: <red>'%s'<reset>\n", channel))
    end

    -- Mute Check: If a channel is muted, we will hide it from the main window but not process it further.
    local isMuted = false
    for prefix, active in pairs(Mindlink.config.mutedChannels) do
        if active and string.find(channel:lower(), "^" .. prefix:lower()) then
            isMuted = true
            break
        end
    end

    local targetTab = "Misc" 
    for prefix, mappedTab in pairs(Mindlink.config.channelMap) do
        if string.find(channel:lower(), "^" .. prefix:lower()) then
            targetTab = mappedTab
            break
        end
    end

    if not Mindlink.tabs[targetTab] then targetTab = Mindlink.config.allTab end
    
    local isChannelFiltered = false
    for prefix, active in pairs(Mindlink.config.filteredChannels) do
        if active and string.find(channel:lower(), "^" .. prefix:lower()) then
            isChannelFiltered = true
            break
        end
    end

    local chanColorStr = nil
    for prefix, color in pairs(Mindlink.config.highlights.channels) do
        if string.find(channel:lower(), "^" .. prefix:lower()) then
            chanColorStr = color
            break
        end
    end
    local cR, cG, cB
    if chanColorStr then
        cR, cG, cB = Mindlink.parseColor(chanColorStr)
    end

    -- 1. Format for Tabs (Geyser Window), unless the channel is muted.
    if not isMuted then
        local continuousText = text:gsub("\r?\n", " ")

        -- Gag Check: If the line contains a gagged string, do not process it for the Mindlink window.
        local isGagged = false
        for gagStr, active in pairs(Mindlink.config.gaggedStrings or {}) do
            if active and continuousText:find(gagStr, 1, true) then
                isGagged = true
                break
            end
        end

        if not isGagged then
            local timeStr = ""
            if type(Mindlink.config.timestamp) == "string" then
                timeStr = getTime(true, Mindlink.config.timestamp)
            elseif Mindlink.config.timestamp then
                timeStr = getTime(true, "[hh:mm:ss] ")
            end
            
            local formattedText = ""
            if chanColorStr then
                formattedText = string.format("<%d,%d,%d>", cR, cG, cB) .. ansi2string(continuousText)
            else
                formattedText = ansi2decho(continuousText):gsub("<reset>", "")
            end
            
            formattedText = Mindlink.applyWordHighlights(formattedText)
            Mindlink.appendChat(targetTab, formattedText, timeStr)
            Mindlink.logMessage(targetTab, continuousText)
        end
    end

    -- 2. Mathematical Highlighting for Main Window
    local cleanLines = {}
    for s in string.gmatch(ansi2string(text), "([^\r\n]+)") do
        table.insert(cleanLines, s:match("^%s*(.-)%s*$") or s)
    end
    if #cleanLines == 0 then return end

    local function applyToMainWindow(lineStr, currentIdx)
        moveCursor("main", 0, currentIdx)
        local fullLine = getCurrentLine("main")
        local startIdx = string.find(fullLine, lineStr, 1, true)
        
        if not startIdx then return currentIdx + 1 end 
        
        local startPos = startIdx - 1 
        
        if Mindlink.config.filterAll or isChannelFiltered or isMuted then
            local currentLineTrimmed = fullLine:match("^%s*(.-)%s*$")
            if currentLineTrimmed == lineStr then
                deleteLine() 
                return currentIdx 
            else
                selectSection("main", startPos, string.len(lineStr))
                replace("") 
                return currentIdx + 1
            end
        elseif Mindlink.config.colorMain then
            local linePainted = false
            
            -- 1. Paint the whole line if linesContaining triggers
            for str, color in pairs(Mindlink.config.highlights.linesContaining) do
                if string.find(lineStr, str, 1, true) then
                    local lR, lG, lB = Mindlink.parseColor(color)
                    selectSection("main", startPos, string.len(lineStr))
                    setFgColor(lR, lG, lB)
                    linePainted = true
                    break
                end
            end
            
            -- 2. Apply Channel Color ONLY if linesContaining didn't override it
            if not linePainted and chanColorStr then
                selectSection("main", startPos, string.len(lineStr))
                setFgColor(cR, cG, cB)
            end
            
            -- 3. Paint Word Highlights on top!
            for word, color in pairs(Mindlink.config.highlights.words) do
                local wR, wG, wB = Mindlink.parseColor(color)
                local escapedWord = word:gsub("([^%w])", "%%%1")
                local pattern = string.match(word, "^%a+$") and ("%f[%a]()" .. escapedWord .. "()%f[%A]") or ("()" .. escapedWord .. "()")
                
                local searchPos = 1
                while true do
                    local matchStart, matchEnd = string.match(lineStr, pattern, searchPos)
                    if not matchStart then break end
                    
                    local actualLen = matchEnd - matchStart
                    local sectionPos = startPos + (matchStart - 1)
                    
                    selectSection("main", sectionPos, actualLen)
                    setFgColor(wR, wG, wB)
                    
                    searchPos = matchEnd
                end
            end
            deselect("main")
            return currentIdx + 1
        end
        return currentIdx + 1
    end

    local found = false
    local lineNum = getLineCount("main")
    
    for i = lineNum, math.max(1, lineNum - 30), -1 do
        moveCursor("main", 0, i)
        local currentLine = getCurrentLine("main")
        
        if string.find(currentLine, cleanLines[1], 1, true) then
            found = true
            local targetIdx = i
            for j = 1, #cleanLines do
                targetIdx = applyToMainWindow(cleanLines[j], targetIdx)
            end
            break
        end
    end
    
    moveCursor("main", 0, getLineCount("main"))
    
    if not found then
        for idx, lineText in ipairs(cleanLines) do
            local safeText = lineText:gsub("([%.%^%$%(%)%[%]%*%+%-%?%|%{%}\\])", "\\%1")
            
            local trigID
            trigID = tempRegexTrigger(safeText, function()
                applyToMainWindow(lineText, getLineNumber())
            end, 1)
            
            tempTimer(3, function() if trigID then killTrigger(trigID) end end)
        end
    end
end

-- =========================================================================
-- Trigger-Based Capture (For Emotes/Color Triggers)
-- =========================================================================
function Mindlink.captureFromTrigger(targetTab)
    local console = Mindlink.consoles[targetTab]
    if not console then return end

    local rawText = line
    if Mindlink.config.ignorePatterns then
        for _, pattern in ipairs(Mindlink.config.ignorePatterns) do
            if string.find(rawText, pattern) then return end
        end
    end

    local timeStr = ""
    if type(Mindlink.config.timestamp) == "string" then
        timeStr = getTime(true, Mindlink.config.timestamp)
    elseif Mindlink.config.timestamp then
        timeStr = getTime(true, "[hh:mm:ss] ")
    end
    local formattedText = ""
    local lastColor = ""
    local lineLen = utf8 and utf8.len(line) or string.len(line)

    for i = 1, lineLen do
        selectSection(i - 1, 1)
        local char = getSelection()
        if char == "" then break end
        local r, g, b = getFgColor()
        local colorTag = string.format("<%d,%d,%d>", r, g, b)
        if colorTag ~= lastColor then
            formattedText = formattedText .. colorTag
            lastColor = colorTag
        end
        formattedText = formattedText .. char
    end
    deselect() 
    
    -- Send fully formatted string to Mindlink Tabs
    formattedText = Mindlink.applyWordHighlights(formattedText)
    Mindlink.appendChat(targetTab, formattedText, timeStr)
    Mindlink.logMessage(targetTab, rawText)

    -- Handle Main Window (Mathematical Word Painting)
    if Mindlink.config.gagMain then
        deleteLine()
    elseif Mindlink.config.colorMain then
        -- 1. Check linesContaining for emotes
        for str, color in pairs(Mindlink.config.highlights.linesContaining) do
            if string.find(rawText, str, 1, true) then
                local lR, lG, lB = Mindlink.parseColor(color)
                selectCurrentLine("main")
                setFgColor(lR, lG, lB)
                break
            end
        end

        -- 2. Word Highlights on top
        for word, color in pairs(Mindlink.config.highlights.words) do
            local wR, wG, wB = Mindlink.parseColor(color)
            local escapedWord = word:gsub("([^%w])", "%%%1")
            local pattern = string.match(word, "^%a+$") and ("%f[%a]()" .. escapedWord .. "()%f[%A]") or ("()" .. escapedWord .. "()")
            
            local searchPos = 1
            while true do
                local matchStart, matchEnd = string.match(rawText, pattern, searchPos)
                if not matchStart then break end
                
                selectSection("main", matchStart - 1, matchEnd - matchStart)
                setFgColor(wR, wG, wB)
                searchPos = matchEnd
            end
        end
        deselect("main")
    end
end

-- =========================================================================
-- Output Gagging Utility (Hides Achaea Config Walls)
-- =========================================================================
function Mindlink.silenceColorConfig()
    local startID
    startID = tempRegexTrigger("^Channel emotes set to \\d+\\.", function()
        deleteLine()
        local gagID
        gagID = tempRegexTrigger("^.*$", function()
            deleteLine()
            if string.find(line, "To restore the defaults, enter CONFIG COLOUR DEFAULT", 1, true) then
                killTrigger(gagID) 
            end
        end)
        tempTimer(2.5, function() if gagID then killTrigger(gagID) end end)
    end, 1)
    tempTimer(2.5, function() if startID then killTrigger(startID) end end)
end

-- =========================================================================
-- Profile Management (External JSON Config)
-- =========================================================================
function Mindlink.saveProfile(silent)
    -- Check and create the master Mindlink folder before saving
    local baseDir = getMudletHomeDir() .. "/Mindlink"
    if not lfs.attributes(baseDir) then lfs.mkdir(baseDir) end
    
    local filepath = baseDir .. "/Mindlink_Profile.json"
    
    -- Export all behavioral and color settings, strictly excluding window UI dimensions
    local exportData = {
        timestamp = Mindlink.config.timestamp,
        colorMain = Mindlink.config.colorMain,
        emoteColor = Mindlink.config.emoteColor,
        filterAll = Mindlink.config.filterAll,
        filteredChannels = Mindlink.config.filteredChannels,
        mutedChannels = Mindlink.config.mutedChannels,
        gaggedStrings = Mindlink.config.gaggedStrings,
        ignorePatterns = Mindlink.config.ignorePatterns,
        allTab = Mindlink.config.allTab,
        tabNames = Mindlink.config.tabNames,
        channelMap = Mindlink.config.channelMap,
        logTabs = Mindlink.config.logTabs,
        colors = Mindlink.config.colors,
        highlights = Mindlink.config.highlights,
        debug = Mindlink.config.debug,
    }
    
    local file = io.open(filepath, "w")
    if file then
        file:write(yajl.to_string(exportData))
        file:close()
        if not silent then Mindlink.echo("Profile settings saved to:\n<gray>" .. filepath .. "<reset>") end
    else
        if not silent then Mindlink.echo("<red>Failed to write profile to disk.<reset>") end
    end
end

function Mindlink.loadProfile(silent)
    -- Point to the new nested location
    local filepath = getMudletHomeDir() .. "/Mindlink/Mindlink_Profile.json"
    local file = io.open(filepath, "r")
    
    if not file then 
        if not silent then Mindlink.echo("<red>Error:<reset> No Mindlink_Profile.json found. A new one will be created automatically.") end
        return 
    end
    
    local contents = file:read("*a")
    file:close()
    
    local success, profile = pcall(yajl.to_value, contents)
    if not success or type(profile) ~= "table" then Mindlink.echo("<red>Error:<reset> Your Mindlink_Profile.json has a formatting error! Check for missing quotes or commas.") return end
    
    -- Direct assignments for simple variables
    if profile.timestamp ~= nil then Mindlink.config.timestamp = profile.timestamp end
    if profile.colorMain ~= nil then Mindlink.config.colorMain = profile.colorMain end
    if profile.emoteColor ~= nil then Mindlink.config.emoteColor = profile.emoteColor end
    if profile.filterAll ~= nil then Mindlink.config.filterAll = profile.filterAll end
    -- Backwards compatibility for old 'gagMain' setting
    if profile.gagMain ~= nil and profile.filterAll == nil then Mindlink.config.filterAll = profile.gagMain end
    if profile.debug ~= nil then Mindlink.config.debug = profile.debug end
    if profile.allTab ~= nil then Mindlink.config.allTab = profile.allTab end

    -- Direct overwrites for tables (Imports the exact shared profile state)
    if profile.filteredChannels then Mindlink.config.filteredChannels = profile.filteredChannels end
    -- Backwards compatibility for old 'hiddenChannels' setting
    if profile.hiddenChannels and not profile.filteredChannels then 
        Mindlink.config.filteredChannels = profile.hiddenChannels 
    end
    if profile.mutedChannels then Mindlink.config.mutedChannels = profile.mutedChannels end
    if profile.gaggedStrings then Mindlink.config.gaggedStrings = profile.gaggedStrings end
    if profile.ignorePatterns then Mindlink.config.ignorePatterns = profile.ignorePatterns end
    if profile.tabNames then Mindlink.config.tabNames = profile.tabNames end
    if profile.channelMap then Mindlink.config.channelMap = profile.channelMap end
    if profile.logTabs then Mindlink.config.logTabs = profile.logTabs end
    if profile.colors then Mindlink.config.colors = profile.colors end
    if profile.highlights then Mindlink.config.highlights = profile.highlights end
    
    if not silent then Mindlink.echo("External profile loaded. Settings applied!") end
end

function Mindlink.cycleChannelMapping(channel)
    if not channel or not Mindlink.config.channelMap[channel] then return end

    local tabs = Mindlink.config.tabNames
    local currentTab = Mindlink.config.channelMap[channel]
    local currentIndex = -1

    for i, tab in ipairs(tabs) do
        if tab == currentTab then
            currentIndex = i
            break
        end
    end

    if currentIndex == -1 then return end -- Should not happen if config is valid

    local nextIndex = currentIndex + 1
    if nextIndex > #tabs then
        nextIndex = 1 -- Loop back to the start
    end

    local newTab = tabs[nextIndex]
    Mindlink.config.channelMap[channel] = newTab

    Mindlink.saveProfile(true) -- Save silently
    Mindlink.showConfig() -- Redraw the dashboard
end

function Mindlink.getSortedGagList()
    local gaggedList = {}
    for str, active in pairs(Mindlink.config.gaggedStrings or {}) do
        if active then table.insert(gaggedList, str) end
    end
    table.sort(gaggedList)
    return gaggedList
end

function Mindlink.toggleConfig(option)
    if option == "filterAll" then
        Mindlink.config.filterAll = not Mindlink.config.filterAll
    elseif option == "colorMain" then
        Mindlink.config.colorMain = not Mindlink.config.colorMain
    elseif option == "debug" then
        Mindlink.config.debug = not Mindlink.config.debug
    else
        return
    end
    Mindlink.saveProfile(true)
    -- Redraw the config window to show the change instantly
    Mindlink.showConfig()
end

-- =========================================================================
-- In-Game Commands & Help Interface
-- =========================================================================
function Mindlink.showHelp()
    cecho("\n<dodger_blue>================================================================================<reset>")
    cecho("\n<dodger_blue>                            M I N D L I N K   H E L P                           <reset>")
    cecho("\n<dodger_blue>================================================================================<reset>\n")
    cecho("  <white>Mindlink<reset> is a telepathic communications ledger, to help you 'catch' messages. ")
    cecho("\n  in a dedicated window outside of the game's main feed. While you can configure")
    cecho("\n  most common settings with the commands below, you'll want to edit the script")
    cecho("\n  directly in order to adjust where the geyser window is placed, or to add new")
    cecho("\n  tabs. Look for the <yellow>Mindlink.config<reset> block at the top of the <white>Mindlink<reset> script.\n")
    
    cecho("\n<cyan>In-Game Commands:<reset>")
    cecho("\n  <white>Customisation<reset>")
    cecho("\n  <yellow>mindlink emote <color><reset>  - Sets a new color # for catching emotes.")
    cecho("\n  <yellow>mindlink filter <chan|all><reset> - Toggles hiding a channel (or all) from the main window.")
    cecho("\n  <yellow>mindlink mute <chan><reset>   - Toggles hiding a channel from ALL windows.")
    cecho("\n  <yellow>mindlink gag <string><reset>    - Hides lines with a specific string from Mindlink tabs.")
    cecho("\n  <yellow>mindlink ungag <string|#><reset> - Removes a string from your gag list.")
    cecho("\n  <yellow>mindlink toggle color<reset>   - Toggles applying custom colors to the main window text.")
    cecho("\n  <white>Information<reset>")
    cecho("\n  <yellow>mindlink config<reset>          - Shows the current configuration dashboard.")
    cecho("\n  <yellow>mindlink gaglist<reset>         - Shows all currently gagged strings.")
    cecho("\n  <white>Profiles<reset>")
    cecho("\n  <yellow>mindlink profile save<reset>   - Manually saves your current configuration.")
    cecho("\n  <yellow>mindlink profile load<reset>   - Manually loads a configuration from a file.")
    cecho("\n  <white>Debugging<reset>")
    cecho("\n  <yellow>mindlink debug<reset>          - Toggles printing raw GMCP channel IDs for setup.")
    
    cecho("\n\n<cyan>How We Catch Emotes (Emote Colours):<reset>")
    cecho("\n  <white>Mindlink<reset> catches emotes automatically by watching a custom colour. The colour")
    cecho("\n  set for emotes in <yellow>CONFIG COLOURS<reset> must be unique. I recommend <DimGray>dark grey (242)<reset>.")
    cecho("\n  To set it, use <yellow>mindlink emote <#><reset> with the number you'd like from the <yellow>COLOURS<reset>")
    cecho("\n  list in-game. <white>Mindlink<reset> will set the colour for you in game and update its")
    cecho("\n  settings to watch for emotes in that colour.")

    cecho("\n<dodger_blue>================================================================================<reset>\n")
end

function Mindlink.showConfig()
    local c = {
        primary = "<dodger_blue>",
        secondary = "<grey>",
        text = "<white>",
        accent1 = "<yellow>",
        accent2 = "<red>",
        green = "<green>",
    }

    cecho("\n" .. c.primary .. "================================================================================<reset>")
    cecho("\n" .. c.primary .. "                         M I N D L I N K   C O N F I G                         <reset>")
    cecho("\n" .. c.primary .. "================================================================================<reset>")

    -- Toggles
    cecho("\n\n  " .. c.accent1 .. "-- Toggles --<reset>")
    local filterAll = Mindlink.config.filterAll and (c.green .. "ON") or (c.accent2 .. "OFF")
    local colorMain = Mindlink.config.colorMain and (c.green .. "ON") or (c.accent2 .. "OFF")
    local debugMode = Mindlink.config.debug and (c.green .. "ON") or (c.accent2 .. "OFF")

    cecho("\n  " .. c.primary .. "Filter All: [")
    cechoLink(filterAll, [[Mindlink.toggleConfig("filterAll")]], "Click to toggle filtering all channels from the main window", true)
    cecho("]<reset>")

    cecho(" | " .. c.primary .. "Color Main: ")
    cechoLink(colorMain, [[Mindlink.toggleConfig("colorMain")]], "Click to toggle custom colors in the main window", true)
    cecho("]<reset>")

    cecho(" | " .. c.primary .. "Debug: ")
    cechoLink(debugMode, [[Mindlink.toggleConfig("debug")]], "Click to toggle GMCP channel debugging", true)
    cecho("]<reset>")
    
    -- Settings
    cecho("\n\n  " .. c.accent1 .. "-- Settings --<reset>")
    cecho("\n  " .. c.primary .. "Emote Color: " .. c.text .. Mindlink.config.emoteColor)

    -- Filtered Channels
    local filtered = {}
    for chan, active in pairs(Mindlink.config.filteredChannels or {}) do
        if active then table.insert(filtered, chan) end
    end
    cecho("\n\n  " .. c.accent1 .. "-- Filtered Channels (Hidden from Main Window) --<reset>")
    if #filtered > 0 then
        cecho("\n  " .. c.text .. table.concat(filtered, ", "))
    else
        cecho("\n  " .. c.secondary .. "None.")
    end

    -- Muted Channels
    local muted = {}
    for chan, active in pairs(Mindlink.config.mutedChannels or {}) do
        if active then table.insert(muted, chan) end
    end
    cecho("\n\n  " .. c.accent1 .. "-- Muted Channels (Hidden Everywhere) --<reset>")
    if #muted > 0 then
        cecho("\n  " .. c.text .. table.concat(muted, ", "))
    else
        cecho("\n  " .. c.secondary .. "None.")
    end

    -- Gagged Strings (Link to the dedicated list command)
    cecho("\n\n  " .. c.accent1 .. "-- Gagged Strings (Hidden from Mindlink Tabs) --<reset>")
    cecho("\n  ")
    cechoLink(c.text .. "[Click to View Gag List]", [[send("mindlink gaglist")]], "Show the interactive list of gagged strings", true)

    -- Channel Mappings
    cecho("\n\n  " .. c.accent1 .. "-- Channel to Tab Mappings --<reset>")
    cecho("\n  " .. c.secondary .. "(Click a mapping to cycle the channel to the next tab)")

    local sortedChans = {}
    for chan, _ in pairs(Mindlink.config.channelMap or {}) do
        table.insert(sortedChans, chan)
    end
    table.sort(sortedChans)

    for _, chan in ipairs(sortedChans) do
        local tabName = Mindlink.config.channelMap[chan]
        cecho(string.format("\n  %s%-10s -> ", c.text, chan))
        cechoLink(string.format("%s[%s]<reset>", c.primary, tabName), string.format([[Mindlink.cycleChannelMapping("%s")]], chan), "Click to cycle this channel's tab", true)
    end

    cecho("\n\n" .. c.primary .. "================================================================================<reset>\n")
end

function Mindlink.showGagList()
    local c = { primary = "<dodger_blue>", secondary = "<grey>", text = "<white>", accent1 = "<yellow>" }

    cecho("\n" .. c.primary .. "================================================================================<reset>")
    cecho("\n" .. c.primary .. "                         M I N D L I N K   G A G L I S T                       <reset>")
    cecho("\n" .. c.primary .. "================================================================================<reset>")

    local gaggedList = Mindlink.getSortedGagList()

    if #gaggedList > 0 then
        cecho("\n  " .. c.secondary .. "(Use 'mindlink ungag <number>' or click to remove)\n")
        for i, str in ipairs(gaggedList) do
            cecho(string.format("  %s%2d. <reset>", c.accent1, i))
            cechoLink(c.text .. '"' .. str .. '"\n', string.format([[send("mindlink ungag %d", false)]], i), "Click to remove this gagged string.", true)
        end
    else
        cecho("\n  " .. c.secondary .. "No strings are currently gagged.")
    end

    cecho("\n\n" .. c.primary .. "================================================================================<reset>\n")
end

-- Master Alias: Route all user commands to functions
function Mindlink.handleCommand(args)
    local cmd = args:lower()
    if cmd == "help" or cmd == "" then
        Mindlink.showHelp()
    elseif cmd == "config" then
        Mindlink.showConfig()
    elseif cmd == "gaglist" then
        Mindlink.showGagList()
    elseif cmd == "toggle color" then
        Mindlink.config.colorMain = not Mindlink.config.colorMain
        local state = Mindlink.config.colorMain and "<green>ON" or "<red>OFF"
        Mindlink.echo("Main Window Coloring is now " .. state .. ".")
        Mindlink.saveProfile(true)
    elseif cmd == "debug" then
        Mindlink.config.debug = not Mindlink.config.debug
        local state = Mindlink.config.debug and "<green>ON" or "<red>OFF"
        Mindlink.echo("GMCP Channel Sniffer is now " .. state .. ".")
        Mindlink.saveProfile(true)
    elseif cmd:sub(1, 7) == "filter " then
        local target = cmd:sub(8):match("^%s*(.-)%s*$") 
        if target == "" then Mindlink.echo("Please specify a channel prefix (e.g., 'ct') or 'all'.")
        elseif target:lower() == "all" then
            Mindlink.config.filterAll = not Mindlink.config.filterAll
            local state = Mindlink.config.filterAll and "<green>ON" or "<red>OFF"
            Mindlink.echo("Main Window Filtering for ALL channels is now " .. state .. ".")
            Mindlink.saveProfile(true)
        else
            Mindlink.config.filteredChannels[target] = not Mindlink.config.filteredChannels[target]
            local state = Mindlink.config.filteredChannels[target] and "<green>FILTERED" or "<red>NOT FILTERED"
            Mindlink.echo("Channel '<yellow>" .. target .. "<reset>' is now " .. state .. "<reset> from the main window.")
            Mindlink.saveProfile(true)
        end
    elseif cmd:sub(1, 5) == "mute " then
        local chan = cmd:sub(6):match("^%s*(.-)%s*$") 
        if chan == "" then Mindlink.echo("Please specify a channel prefix (e.g., <yellow>mindlink mute newbie<reset>).")
        else
            Mindlink.config.mutedChannels[chan] = not Mindlink.config.mutedChannels[chan]
            if Mindlink.config.mutedChannels[chan] then Mindlink.echo("Channel '<yellow>" .. chan .. "<reset>' is now <red>MUTED<reset> everywhere.")
            else Mindlink.echo("Channel '<yellow>" .. chan .. "<reset>' is now <green>UNMUTED<reset>.") end
            Mindlink.saveProfile(true)
        end
    elseif cmd:sub(1, 6) == "ungag " then
        local target = cmd:sub(7):match("^%s*(.-)%s*$")
        if target == "" then Mindlink.echo("Please specify a string or number from 'mindlink gaglist' to ungag.") return end

        Mindlink.config.gaggedStrings = Mindlink.config.gaggedStrings or {}
        local removed = false
        local removedStr = ""

        local num = tonumber(target)
        if num then
            local gaggedList = Mindlink.getSortedGagList()

            if num > 0 and num <= #gaggedList then
                removedStr = gaggedList[num]
                Mindlink.config.gaggedStrings[removedStr] = nil
                removed = true
            end
        else
            if Mindlink.config.gaggedStrings[target] then
                removedStr = target
                Mindlink.config.gaggedStrings[target] = nil
                removed = true
            end
        end

        if removed then
            Mindlink.echo("No longer gagging lines containing: '<yellow>" .. removedStr .. "<reset>'.")
            Mindlink.saveProfile(true)
        else
            Mindlink.echo("Could not find that string or number in your gag list.")
        end
    elseif cmd:sub(1, 4) == "gag " then
        local str = cmd:sub(5):match("^%s*(.-)%s*$") 
        if str == "" then Mindlink.echo("Please specify a string to gag (e.g., <yellow>mindlink gag swings his fists<reset>).")
        else
            Mindlink.config.gaggedStrings = Mindlink.config.gaggedStrings or {}
            if Mindlink.config.gaggedStrings[str] then Mindlink.echo("That string is already on your gag list.")
            else
                Mindlink.config.gaggedStrings[str] = true
                Mindlink.echo("Now gagging lines containing: '<yellow>" .. str .. "<reset>'.")
                Mindlink.saveProfile(true)
            end
        end
    elseif cmd:sub(1, 6) == "emote " then
        local colorNum = cmd:sub(7):match("^%s*(%d+)%s*$")
        if colorNum then
            Mindlink.config.emoteColor = tonumber(colorNum)
            Mindlink.silenceColorConfig()
            send("config colour emotes " .. colorNum, false)
            if Mindlink.emoteTrigger then killTrigger(Mindlink.emoteTrigger) end
            Mindlink.emoteTrigger = tempColorTrigger(Mindlink.config.emoteColor, -1, [[Mindlink.captureFromTrigger("Local")]])
            Mindlink.echo("Emote color set to " .. colorNum .. " and saved.")
            Mindlink.saveProfile(true)
        else
            Mindlink.echo("Please specify a valid XTerm256 color number (0-255).")
        end
    elseif cmd == "profile save" then
        Mindlink.saveProfile()
        
    elseif cmd == "profile load" then
        Mindlink.loadProfile()
        
        -- Rebuild the UI triggers in case the emote color was changed in the JSON
        if Mindlink.emoteTrigger then killTrigger(Mindlink.emoteTrigger) end
        Mindlink.emoteTrigger = tempColorTrigger(Mindlink.config.emoteColor, -1, [[Mindlink.captureFromTrigger("Local")]])
        
        -- Safely hide and destroy the old UI elements to prevent ghost tabs when loading a profile
        -- that may have different tab names.
        if Mindlink.container then Mindlink.container:hide() end
        if Mindlink.tabs then
            for _, tab in pairs(Mindlink.tabs) do tab:hide() end
        end
        if Mindlink.consoles then
            for _, console in pairs(Mindlink.consoles) do console:hide() end
        end
        
        -- Reset the tables and redraw the UI with the newly loaded profile data
        Mindlink.tabs = {}
        Mindlink.consoles = {}
        Mindlink.currentTab = Mindlink.config.allTab
        
        Mindlink.createUI()
        if Mindlink.container then Mindlink.container:show() end
        
        Mindlink.echo("User Interface rebuilt successfully!")
    else
        Mindlink.echo("Unknown command. Type <yellow>mindlink help<reset> for options.")
    end
end

-- =========================================================================
-- Initialization
-- =========================================================================
function Mindlink.init()
    -- Load saved settings from profile on startup
    Mindlink.loadProfile(true)

    for _, handlerID in ipairs(Mindlink.events) do killAnonymousEventHandler(handlerID) end
    Mindlink.events = {}
    if Mindlink.aliasHandler then killAlias(Mindlink.aliasHandler) end

    sendGMCP([[Core.Supports.Add ["Comm.Channel 1"] ]])
    table.insert(Mindlink.events, registerAnonymousEventHandler("gmcp.Comm.Channel.Text", "Mindlink.onGMCPChat"))

    Mindlink.aliasHandler = tempAlias("^mindlink(?: (.*))?$", [[
        local args = matches[2] or "help"
        Mindlink.handleCommand(args)
    ]])

    -- 2. Create the Emote Trigger EXACTLY ONCE
    if Mindlink.emoteTrigger then killTrigger(Mindlink.emoteTrigger) end
    Mindlink.silenceColorConfig()
    send("config colour emotes " .. Mindlink.config.emoteColor, false)
    Mindlink.emoteTrigger = tempColorTrigger(Mindlink.config.emoteColor, -1, [[Mindlink.captureFromTrigger("Local")]])

    -- 3. Create the Ship Announcement Trigger
    if Mindlink.shipTrigger then killTrigger(Mindlink.shipTrigger) end
    -- We anchor this with ^ so it only catches actual announcements, not people quoting them!
    Mindlink.shipTrigger = tempRegexTrigger("^==\\[CAPTAIN'S ANNOUNCEMENT: .*$", [[Mindlink.captureFromTrigger("Local")]])

    -- Add auto-save hooks for clean exit and disconnection
    table.insert(Mindlink.events, registerAnonymousEventHandler("sysExitEvent", function() Mindlink.saveProfile(true) end))
    table.insert(Mindlink.events, registerAnonymousEventHandler("sysDisconnectionEvent", function() Mindlink.saveProfile(true) end))

    Mindlink.createUI()
    Mindlink.echo("Telepathic Ledger Initialized. Type <yellow>mindlink help<reset> for commands.")
end

if gmcp and gmcp.Char and gmcp.Char.Name then
    Mindlink.init()
else
    if Mindlink.loginTrigger then killTrigger(Mindlink.loginTrigger) end
    Mindlink.loginTrigger = tempRegexTrigger("Password correct\\. Welcome to Achaea\\.", function()
        Mindlink.init()
    end, 1)
end