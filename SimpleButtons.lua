
-- simpleButtons: provides various functions for UI pieces:

--  enables pieces to be initialized with defaults

--  manages how pieces look and behave

SB = {}
SB.standardLineHeight = function() 
    pushStyle()
    textWrapWidth(0)
    _, lineHeight = textSize("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    popStyle()
    return lineHeight
end
SB.buttonDimensionsFor = function(thisText) 
    local boundsW, boundsH = textSize(thisText)
    lineHeight = SB.standardLineHeight()
    boundsW = boundsW + (lineHeight * 1.8)
    boundsH = boundsH + lineHeight 
    return boundsW, boundsH
end

SB.baseFontSize = math.max(WIDTH, HEIGHT) * 0.02
SB.cornerRadius = SB.baseFontSize * 1.25
SB.marginPaddingH = SB.baseFontSize * 0.55
SB.marginPaddingW = SB.baseFontSize
SB.ui = {}
SB.useGrid = false
SB.gridSpacing = math.min(WIDTH, HEIGHT) / 80
SB.touchOffset = {x = 0, y = 0}
SB.deletableButtonsChecked = false
SB.deletableButtons = {}

SB.hasCheckedForDependency = false
SB.isBeingRunAsDependency = function()
    local tabExists = false
    local localTabs = listProjectTabs()
    for _, tabName in ipairs(localTabs) do
        if tabName == "ButtonTables" then tabExists = true end
    end
    if tabExists then
        local tabData = readProjectTab("ButtonTables")
        local tabsMatch = tabData ~= readProjectTab("SimpleButtons:ButtonTables")
        return tabsMatch, tabData
    else
        return true
    end
end


-- Function to create a table of tab contents indexed by tab names, excluding the ButtonTables tab
SB.codeIndexedByTabExcludingButtons = function()
    local projectTabNames = listProjectTabs()
    local codeByTab = {}
    
    for _, tabName in ipairs(projectTabNames) do
        if tabName ~= "ButtonTables" then
            codeByTab[tabName] = readProjectTab(tabName)
        end
    end
    
    return codeByTab
end



SB.allButtonDataStrings = function()
    local buttonDataStrings = {}
    for traceback, ui in pairs(SB.ui) do
        buttonDataStrings[traceback] = SB.formatButtonDataString(traceback, ui)
    end
    return buttonDataStrings
end

SB.tabExists = function(tab, projectTabs)
    for _, existingTab in ipairs(projectTabs) do
        if tab == existingTab then
            return true
        end
    end
    return false
end

SB.textPatternFound = function(text, functionCode)
    local pattern = "SB.button%s-%(%s-%{%s-text%s-=%s-%[%[" .. text .. "%]%]%s-%}%s-%)"
    local patternFound = functionCode:find(pattern)
    return patternFound ~= nil
end

SB.extractFunctionCode = function(tab, functionName)
    local tabCode = readProjectTab(tab)
    local pattern = "function%s+" .. functionName .. "%s-%b()%s-[^%z]*end"
    local functionCode = tabCode:match(pattern)
    --[[
    print("Extracting function code for tab: " .. tab .. " and function: " .. functionName)
    print("tabCode: " .. tabCode)
    print("pattern: " .. pattern)
    ]]
    if functionCode then
        --print("functionCode: " .. functionCode)
        return functionCode
    end
end


function SB.removeWhitespace(code)
    return code:gsub("%s+", "")
end


function SB.buttonTextFound(traceback, ui)
    local tab, functionName = string.gmatch(traceback, "(%g*),(%g*),")()
    local functionCode = SB.extractFunctionCode(tab, functionName)
    
    if functionCode then
        local buttonTextFound = SB.textPatternFound(ui.text, functionCode)
        if buttonTextFound then
            return true
        end
    end
    
    return false
end

SB.deletableButtonTables = function ()
    if SB.didSearchForDeletables then
        return
    end
    SB.didSearchForDeletables = true
    
    local projectTabs = listProjectTabs()
    local uiData = SB.ui
    
    local buttonsWithNoTabs = SB.uiWithNonValidTabs(uiData, projectTabs)
    local buttonsWithNoFunctions = SB.uiWithNonValidFunctions(uiData)
    local buttonsWithNoTexts = SB.uiWithNonValidTexts(uiData)
    
    local combinedButtonTable = SB.combineButtonTables(buttonsWithNoTabs, buttonsWithNoFunctions, buttonsWithNoTexts)
    
    return combinedButtonTable
end

-- Function to find buttons with no corresponding tabs
SB.uiWithNonValidTabs = function(uiData, projectTabs)
    local buttonsWithNoTabs = {}
    for traceback, ui in pairs(uiData) do
        local tab, functionName = string.gmatch(traceback, "(%g*),(%g*),")()
        if not SB.tabExists(tab, projectTabs) then
            buttonsWithNoTabs[traceback] = true
        end
    end
    return buttonsWithNoTabs
end

-- Function to find buttons with no corresponding functions in their tabs
SB.uiWithNonValidFunctions = function(uiData, projectTabs)
    local buttonsWithNoFunctions = {}
    for traceback, ui in pairs(uiData) do
        local tab, functionName = string.gmatch(traceback, "(%g*),(%g*),")()
        local tabExists = SB.tabExists(tab, projectTabs)
        
        if tabExists then
            local status, functionCode = pcall(SB.extractFunctionCode, tab, functionName)
            if not status then
                buttonsWithNoFunctions[traceback] = true
            end
        end
        --[[
        print("traceback: " .. traceback)
        print("tab: " .. tab)
        print("functionName: " .. functionName)
        print("tabExists: " .. tostring(tabExists))
        print("functionCode: " .. tostring(functionCode))
        ]]
    end
    return buttonsWithNoFunctions
end

-- Function to find buttons with no corresponding texts in their functions
function SB.uiWithNonValidTexts(uiData, projectTabs)
    local buttonsWithNoTexts = {}
    local count = 0
    for k, v in pairs(projectTabs) do
        print("projectTabs "..count, k, v == nil)
        count = count + 1
    end
    print(count)
    count = 0
    for k, v in pairs(uiData) do
        print("uiData "..count, k, v == nil)
        count = count + 1
    end
    print(count)
    for k, buttonTable in pairs(uiData) do
        local buttonText = buttonTable.text
        local textFound = false
        for tabName, code in pairs(projectTabs) do
            print(tabName, k, buttonText)
            local isInCode = SB.hasStringWithAnyDemarcation(buttonText, code, "button(", ")")
            -- print("Testing with tab:", tabName) -- Add this print statement
            -- print("Is in code:", isInCode) -- Add this print statement
            if isInCode then
                textFound = true
                break
            end
        end
        if not textFound then
            buttonsWithNoTexts[k] = buttonTable
            print("Button with no text found:", k)
        end
    end
    return buttonsWithNoTexts
end




SB.isStringInQuotesInString = function(stringToFind, stringToSearch)
    local pattern = "%\"" .. stringToFind .. "%\""
    if string.find(stringToSearch, pattern) then
        return true
    end
    return false
end

SB.isStringInBracketsInString = function(stringToFind, stringToSearch)
    local pattern = "%[%[" .. stringToFind .. "%]%]"
    if string.find(stringToSearch, pattern) then
        return true
    end
    return false
end

SB.isStringInButtonCallWithSpaces = function(stringToFind, stringToSearch)
    local pattern = "button%(%s*" .. stringToFind .. "%s*%)"
    if string.find(stringToSearch, pattern) then
        return true
    end
    return false
end

-- Function to check if the given string exists in the target string with any demarcation
SB.hasStringWithAnyDemarcation = function(stringToFind, stringToSearch, precedingText, terminatingText)
    return SB.isStringInQuotesInString(stringToFind, stringToSearch, precedingText, terminatingText)
    or SB.isStringInBracketsInString(stringToFind, stringToSearch, precedingText, terminatingText)
    or SB.isStringInButtonCallWithSpaces(stringToFind, stringToSearch, precedingText, terminatingText)
end



-- Function to combine button tables
SB.combineButtonTables = function(...)
    local combinedButtonTable = {}
    local buttonTables = {...}
    for _, buttonTable in ipairs(buttonTables) do
        for traceback, value in pairs(buttonTable) do
            combinedButtonTable[traceback] = value
        end
    end
    return combinedButtonTable
end

--[[
SB.deletableButtonTables = function ()
if SB.didSearchForDeletables then
return
end
SB.didSearchForDeletables = true

local projectTabs = listProjectTabs()
local deletableButtons = {}    
for traceback, ui in pairs(SB.ui) do
local tab, functionName = string.gmatch(traceback, "(%g*),(%g*),?%d*")()

print("traceback: " .. traceback)
print("tab: " .. tab)
print("functionName: " .. functionName)

-- Check if the tab exists
local tabExists = SB.tabExists(tab, projectTabs)
print("tabExists: " .. tostring(tabExists))

if tabExists then
local functionCode = SB.extractFunctionCode(tab, functionName)

if functionCode then
print("functionCode: " .. functionCode)
local buttonTextFound = SB.textPatternFound(ui.text, functionCode)
print("buttonTextFound: " .. tostring(buttonTextFound))

if not buttonTextFound then
deletableButtons[traceback] = true
end
else
deletableButtons[traceback] = true
end
else
deletableButtons[traceback] = true
end
end
return deletableButtons        
end
]]










SB.loadLocalTabIfDependency = function()
    local isDependency, localTabData = SB.isBeingRunAsDependency() 
    if isDependency and localTabData ~= nil then
        local dataLoader = load(localTabData)
        dataLoader()
    end
    SB.hasCheckedForDependency = true
end


SB.secondLineInfoFrom = function(traceback)
    local iterator = string.gmatch(traceback,"(%g*):(%g*): in function '(%g*)'")
    iterator() -- not interested in first line bc it'll always be from here
    local tab, lineNumber, functionName = iterator()
    return {tab = tab, functionName = functionName, lineNumber = functionName, all = tab..","..functionName..","..lineNumber}
end


parameter.boolean("buttons are draggable", false)
parameter.boolean("snap_to_grid", false, function()
    SB.useGrid = snap_to_grid
end)


SB.defaultButton = function(bText, traceback)
    SB.ui[traceback] = {text=bText,
    x=0.5, y=0.5, action=SB.defaultButtonAction}
    return SB.ui[traceback]
end


SB.defaultButtonAction = function()
    print("this is the default button action")
end


SB.doAction = function(traceback)
    if SB.ui[traceback].action == nil then
        return
    else
        SB.ui[traceback].action()
    end
end



SB.clearRenderFlags = function()
    for _, ui in pairs(SB.ui) do
        ui.didRenderAlready = false --now see if rendering is triggered at the right time
    end
end

--evaluateTouchFor: called by each button inside the button() function
--precondition: to use CurrentTouch, pass nothing to the touch value
--postcondition: one of these:
--  a new activatedButton is set (if touch began on this piece)
--  activatedButton has been cleared (touch ended)
--  a button tap has occurred (for detecting button presses in editable mode)
--  a button has been moved (activatedButton was dragged in editable mode)
--  nothing (this piece did not interact with the touch)
SB.evaluateTouchFor = function(traceback, touch)
    if touch == nil then
        touch = CurrentTouch
    end
    if SB.thisButtonIsActivated(traceback, touch) then
        SB.makeActivatedButtonRespond(traceback, touch)
    end
end

--thisButtonIsActivated: called to decide if this button should respond to this touch
--precondition: name and touch cannot be nil
--postconditions:
--  activatedButton has been set or unchanged (note that it is never cleared here)
--  boolean returned true if the given button is the activatedButton, false if not
SB.thisButtonIsActivated = function(traceback, touch)
    --if there is already an activatedButton and this isn't it, return false
    if activatedButton ~= nil and activatedButton ~= traceback then
        return false
    end
    --if there is no activatedButton, see if this should become activatedButton
    if activatedButton == nil then
        --if touch state is BEGAN and touch is inside button, set it to activatedButton
        if touch.state == BEGAN and SB.touchIsInside(traceback, touch) then
            activatedButton = traceback
        else
            --otherwise return false
            return false
        end
    end
    --here only reached if this is activated button (or has become it), so return true
    return true
end

--SB.touchIsInside: calculated using touch's distance from this piece
--preconditions: name and touch cannot be nil, and touched object is basically rectangular
SB.touchIsInside = function(traceback, touch)
    local adjX, adjY = SB.ui[traceback].x*WIDTH, SB.ui[traceback].y*HEIGHT
    local xDistance = math.abs(touch.x-adjX)
    local yDistance = math.abs(touch.y-adjY)
    insideX = xDistance < SB.ui[traceback].width /2
    insideY = yDistance < SB.ui[traceback].height /2
    if insideX and insideY then
        return true
    else
        return false
    end
end

--makeActivatedButtonRespond: decide how the given button should react to given touch
--precondition: button and touch cannot be nil, button must be activatedButton
SB.makeActivatedButtonRespond = function(traceback, touch)
    if touch.state == BEGAN then
        SB.touchOffset.x = touch.x - (SB.ui[traceback].x * WIDTH)
        SB.touchOffset.y = touch.y - (SB.ui[traceback].y * HEIGHT)
    end
    
    --move button if it should be moved
    if buttons_are_draggable then
        SB.evaluateDrag(traceback, touch)
    end
    if touch.state == BEGAN or touch.state == MOVING then
        SB.ui[traceback].isTapped = true
    end
    --if this is an end touch, do a button action, or save new position, or do nothing
    if touch.state == ENDED or touch.state == CANCELLED or not touch then
        if buttons_are_draggable then
            if touch.tapCount == 1 then
                SB.ui[traceback].isTapped = true
                SB.doAction(traceback)
            else
                SB.savePositions()
            end
        elseif SB.touchIsInside(traceback, touch) then
            SB.ui[traceback].isTapped = true
            SB.doAction(traceback)
        end
        activatedButton = nil
    end
end

SB.evaluateDrag = function (traceback, touch)
    if touch.state == MOVING then
        local x, y = touch.x - SB.touchOffset.x, touch.y - SB.touchOffset.y
        
        --rounds x and y if using grid
        if SB.useGrid then
            local gridSpacing = SB.gridSpacing
            x = x + gridSpacing - (x + gridSpacing) % (gridSpacing * 2) 
            y = y + gridSpacing - (y + gridSpacing) % (gridSpacing * 2)
        end   
        
        --make x and y into percentages of width and height
        x, y = x / WIDTH, y / HEIGHT
        --store x and y on tables
        SB.ui[traceback].x = x
        SB.ui[traceback].y = y
    end
end

SB.formatButtonDataString = function (traceback, ui)
    return "SB.ui[ [[" .. traceback .. "]] ] = \n" ..
    "    {text = [[" .. ui.text .. "]],\n" ..
    "    x = " .. ui.x .. ", y = " .. ui.y .. ",\n" ..
    "    width = " .. (ui.width or "nil") .. ", height = " .. (ui.height or "nil") .. ",\n" ..
    "    action = SB.defaultButtonAction\n}\n\n"
end

SB.writeDeletableButtons = function (dataString, deletableDataString, deletableComment)
    local buttonTablesTab = readProjectTab("ButtonTables")
    local commentStart, commentEnd = buttonTablesTab:find(deletableComment)
    
    if commentStart then
        -- If the comment exists, replace the content after the comment with deletableDataString
        return buttonTablesTab:sub(1, commentEnd) .. "\n\n" .. deletableDataString
    else
        -- If the comment does not exist, add it to the end of the dataString and append deletableDataString
        return dataString .. deletableComment .. "\n\n" .. deletableDataString
    end
end

SB.savePositions = function ()
    local dataString = ""
    local deletableDataString = ""
    local deletableComment = "--BUTTONS NOT FOUND IN SOURCE CODE, MAY BE DELETABLE:"
    
    for traceback, ui in pairs(SB.ui) do
        local buttonData = SB.formatButtonDataString(traceback, ui)
        
        if SB.deletableButtons[traceback] then
            deletableDataString = deletableDataString .. buttonData
        else
            dataString = dataString .. buttonData
        end
    end
    
    local combinedDataString = SB.writeDeletableButtons(dataString, deletableDataString, deletableComment)
    saveProjectTab("ButtonTables", combinedDataString)
end

SB.removeExistingDeletableSection = function(buttonTablesTab, deletableComment)
    local commentStart, commentEnd = buttonTablesTab:find(deletableComment)
    
    if not commentStart then
        return buttonTablesTab
    else
        return buttonTablesTab:sub(1, commentStart - 1)
    end
end



-- Gets the table with the same trace
function SB.findTableWithSameTrace(trace, bText)
    local tableToDraw = SB.ui[trace]
    if tableToDraw and tableToDraw.text ~= bText then
        local newKey = trace.."+"..tableToDraw.text
        SB.ui[newKey] = tableToDraw
        tableToDraw = nil
    end
    return tableToDraw
end

-- Finds all the buttons that match the given text
function SB.setTextMatches(bText)
    local textMatches = {}
    for k, buttonTable in pairs(SB.ui) do
        if buttonTable.text == bText then
            if type(k) == "string" then
                table.insert(textMatches, buttonTable)
                buttonTable.key = k
            end
        end
    end 
    return textMatches
end

-- Finds tables that match the given tab and function
function SB.findTableByTabAndFunction(textMatches, trace)
    local matchers = {}
    for _, buttonTable in ipairs(textMatches) do
        local tab, functionName = string.gmatch(buttonTable.key,"(%g*),(%g*),")()
        if tab == trace.tab and functionName == trace.functionName then 
            table.insert(matchers, buttonTable)
        end
    end
    return matchers
end


function SB.setTableToDrawUsingNewId(newId, tableToUpdate, oldId)
    SB.ui[newId] = tableToUpdate
    SB.ui[oldId] = nil
    return SB.ui[newId]
end

function SB.findTableToDraw(trace, bText)
    local tableToDraw = SB.findTableWithSameTrace(trace, bText)
    
    if not tableToDraw then
        local textMatches = SB.setTextMatches(bText)
        
        if #textMatches == 1 then
            tableToDraw = SB.setTableToDrawUsingNewId(trace, textMatches[1], textMatches[1].key)  
        elseif #textMatches > 1 then 
            local matchers = SB.findTableByTabAndFunction(textMatches, trace)
            
            if #matchers == 1 then
                tableToDraw = SB.setTableToDrawUsingNewId(trace, matchers[1], matchers[1].key)  
            elseif #matchers > 1 then 
                for _, buttonTable in ipairs(matchers) do 
                    if not buttonTable.assigned then 
                        tableToDraw = SB.setTableToDrawUsingNewId(trace, buttonTable, buttonTable.key)
                        SB.ui[trace].assigned = true
                    end
                end 
            end
        end
    end
    return tableToDraw
end

--button only actually needs a name to work, the rest have defaults
function button(bText, action, width, height, fontColor, x, y, specTable, imageAsset, radius)
    if not SB.deletableButtonsChecked then
        SB.deletableButtonsChecked = true
        SB.deletableButtons = SB.deletableButtonTables()
    end
    
    --get traceback info 
    --buttons have to be indexed by traceback
    --this lets different buttons have the same texts
    local trace = debug.traceback()
    local tableToDraw = SB.findTableToDraw(trace, bText)
    --if there's not a tableToDraw, make a new one
    if not tableToDraw or tableToDraw.text ~= bText then
        tableToDraw = SB.defaultButton(bText, trace)
    end
    tableToDraw.specTable = specTable
    --if x and y were explicitly stated, they should be ordinary numbers
    --so make them into percentages
    if x then x = x/WIDTH end
    if y then y = y/HEIGHT end
    --get the bounds of the button text if any dimension is undefined
    local boundsW, boundsH, lineHeight
    if width == nil or height == nil then
        boundsW, boundsH = textSize(bText)
        _, lineHeight = textSize("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    end
    width = width or boundsW + (SB.marginPaddingW * 2)
    height = height or boundsH + (SB.marginPaddingH * 2)
    --set empty specTable if none
    specTable = specTable or {}
    --set button drawing values, using saved values if none passed in
    --the saved values should already be percentages
    local x,y = x or tableToDraw.x, y or tableToDraw.y
    --update the stored values if necessary
    if x ~= tableToDraw.x or y ~= tableToDraw.y or 
    width ~= tableToDraw.width or height ~= tableToDraw.height then 
        SB.ui[trace].x = x
        SB.ui[trace].y = y
        SB.ui[trace].width = width
        SB.ui[trace].height = height
    end
    
    --can't use fill() as font color so default to white
    fontColor = fontColor or color(255)
    
    --'action' is called outside of this function
    if action then
        SB.ui[trace].action = action
    end
    
    --get the actual x and y from the percentages
    x, y = x*WIDTH, y*HEIGHT
    
    pushStyle()
    
    local startingFill = color(fill())
    if tableToDraw.isTapped == true and not specTable.isWindow then
        fill(fontColor)
        stroke(startingFill)
    end
    
    --prepare blur and/or image
    local texture, texCoordinates = nil, nil
    if SB.screenBlur and SB.screenBlur ~= 0 then 
        texture = SB.screenBlur
        texCoordinates = vec4(x,y,width,height)
    end
    if imageAsset ~= nil then
        texture = nil
        texCoordinates = nil
        pushStyle()
        fill(236, 76, 67, 0)
        stroke(236, 76, 67, 0)
    end
    
    --draw button
    roundedRectangle{
        x=x,y=y,w=width,h=height,radius=radius or SB.cornerRadius,
        tex=texture,
    texCoord=texCoordinates}
    
    --draw the text
    
    if tableToDraw.isTapped == true then
        fill(startingFill)
    else
        fill(fontColor)
    end
    --if there's an image, draw only that
    if imageAsset ~= nil then
        popStyle()
        sprite(imageAsset, x, y, width, height)
    else --otherwise draw text
        text(bText, x, y)
        popStyle()
    end
    SB.ui[trace].isTapped = false
    --handle touches (wherein action gets called or not)
    SB.evaluateTouchFor(trace)
    --set the flag that shows we rendered (used with blurring)
    SB.ui[trace].didRenderAlready = true
    return SB.ui[trace], trace
end

--[[
true mesh rounded rectangle. Original by @LoopSpace
with anti-aliasing, optional fill and stroke components, optional texture that preserves aspect ratio of original image, automatic mesh caching
usage: RoundedRectangle{key = arg, key2 = arg2}
required: x;y;w;h:  dimensions of the rectangle
optional: radius:   corner rounding radius, defaults to 6;
corners:  bitwise flag indicating which corners to round, defaults to 15 (all corners).
Corners are numbered 1,2,4,8 starting in lower-left corner proceeding clockwise
eg to round the two bottom corners use: 1 | 8
to round all the corners except the top-left use: ~ 2
tex:      texture image
texCoord: vec4 specifying x,y,width,and height to use as texture coordinates
scale:    size of rect (using scale)
use standard fill(), stroke(), strokeWidth() to set body fill color, outline stroke color and stroke width
]]
local __RRects = {}
function roundedRectangle(t)
    local s = t.radius or 8
    local c = t.corners or 15
    local w = math.max(t.w+1,2*s)+1
    local h = math.max(t.h,2*s)+2
    local hasTexture = 0
    local texCoord = t.texCoord or vec4(0,0,1,1) --default to bottom-left-most corner, full with and height
    if t.tex then hasTexture = 1 end
    local label = table.concat({w,h,s,c,hasTexture,texCoord.x,texCoord.y},",")
    if not __RRects[label] then
        local rr = mesh()
        rr.shader = shader(rrectshad.vert, rrectshad.frag)
        
        local v = {}
        local no = {}
        
        local n = math.max(3, s//2)
        local o,dx,dy
        local edge, cent = vec3(0,0,1), vec3(0,0,0)
        for j = 1,4 do
            dx = 1 - 2*(((j+1)//2)%2)
            dy = -1 + 2*((j//2)%2)
            o = vec2(dx * (w * 0.5 - s), dy * (h * 0.5 - s))
            --  if math.floor(c/2^(j-1))%2 == 0 then
            local bit = 2^(j-1)
            if c & bit == bit then
                for i = 1,n do
                    
                    v[#v+1] = o
                    v[#v+1] = o + vec2(dx * s * math.cos((i-1) * math.pi/(2*n)), dy * s * math.sin((i-1) * math.pi/(2*n)))
                    v[#v+1] = o + vec2(dx * s * math.cos(i * math.pi/(2*n)), dy * s * math.sin(i * math.pi/(2*n)))
                    no[#no+1] = cent
                    no[#no+1] = edge
                    no[#no+1] = edge
                end
            else
                v[#v+1] = o
                v[#v+1] = o + vec2(dx * s,0)
                v[#v+1] = o + vec2(dx * s,dy * s)
                v[#v+1] = o
                v[#v+1] = o + vec2(0,dy * s)
                v[#v+1] = o + vec2(dx * s,dy * s)
                local new = {cent, edge, edge, cent, edge, edge}
                for i=1,#new do
                    no[#no+1] = new[i]
                end
            end
        end
        -- print("vertices", #v)
        --  r = (#v/6)+1
        rr.vertices = v
        
        rr:addRect(0,0,w-2*s,h-2*s)
        rr:addRect(0,(h-s)/2,w-2*s,s)
        rr:addRect(0,-(h-s)/2,w-2*s,s)
        rr:addRect(-(w-s)/2, 0, s, h - 2*s)
        rr:addRect((w-s)/2, 0, s, h - 2*s)
        --mark edges
        local new = {cent,cent,cent, cent,cent,cent,
            edge,cent,cent, edge,cent,edge,
            cent,edge,edge, cent,edge,cent,
            edge,edge,cent, edge,cent,cent,
        cent,cent,edge, cent,edge,edge}
        for i=1,#new do
            no[#no+1] = new[i]
        end
        rr.normals = no
        --texture
        if true==false then
            if t.tex then
                rr.shader.fragmentProgram = rrectshad.fragTex
                rr.texture = t.tex
                
                
                local w,h = t.tex.width,t.tex.height
                local textureOffsetX,textureOffsetY = texCoord.x,texCoord.y
                
                local coordTable = {}
                for i,v in ipairs(rr.vertices) do
                    coordTable[i] = vec2((v.x + textureOffsetX)/w, (v.y + textureOffsetY)/h)
                end
                rr.texCoords = coordTable
            end
        end
        local sc = 1/math.max(2, s)
        rr.shader.scale = sc --set the scale, so that we get consistent one pixel anti-aliasing, regardless of size of corners
        __RRects[label] = rr
    end
    __RRects[label].shader.fillColor = color(fill())
    if strokeWidth() == 0 then
        __RRects[label].shader.strokeColor = color(fill())
    else
        __RRects[label].shader.strokeColor = color(stroke())
    end
    
    if t.resetTex then
        __RRects[label].texture = t.resetTex
        t.resetTex = nil
    end
    local sc = 0.25/math.max(2, s)
    __RRects[label].shader.strokeWidth = math.min( 1 - sc*3, strokeWidth() * sc)
    pushMatrix()
    translate(t.x,t.y)
    scale(t.scale or 1)
    __RRects[label]:draw()
    popMatrix()
end

rrectshad ={
    vert=[[
    uniform mat4 modelViewProjection;
    
    attribute vec4 position;
    
    //attribute vec4 color;
    attribute vec2 texCoord;
    attribute vec3 normal;
    
    //varying lowp vec4 vColor;
    varying highp vec2 vTexCoord;
    varying vec3 vNormal;
    
    void main()
    {
    //  vColor = color;
    vTexCoord = texCoord;
    vNormal = normal;
    gl_Position = modelViewProjection * position;
    }
    ]],
    frag=[[
    precision highp float;
    
    uniform lowp vec4 fillColor;
    uniform lowp vec4 strokeColor;
    uniform float scale;
    uniform float strokeWidth;
    
    //varying lowp vec4 vColor;
    varying highp vec2 vTexCoord;
    varying vec3 vNormal;
    
    void main()
    {
    lowp vec4 col = mix(strokeColor, fillColor, smoothstep((1. - strokeWidth) - scale * 0.5, (1. - strokeWidth) - scale * 1.5 , vNormal.z)); //0.95, 0.92,
    col = mix(vec4(col.rgb, 0.), col, smoothstep(1., 1.-scale, vNormal.z) );
    // col *= smoothstep(1., 1.-scale, vNormal.z);
    gl_FragColor = col;
    }
    ]],
    fragTex=[[
    precision highp float;
    
    uniform lowp sampler2D texture;
    uniform lowp vec4 fillColor;
    uniform lowp vec4 strokeColor;
    uniform float scale;
    uniform float strokeWidth;
    
    //varying lowp vec4 vColor;
    varying highp vec2 vTexCoord;
    varying vec3 vNormal;
    
    void main()
    {
    vec4 pixel = texture2D(texture, vTexCoord) * fillColor;
    lowp vec4 col = mix(strokeColor, pixel, smoothstep(1. - strokeWidth - scale * 0.5, 1. - strokeWidth - scale * 1.5, vNormal.z)); //0.95, 0.92,
    // col = mix(vec4(0.), col, smoothstep(1., 1.-scale, vNormal.z) );
    col *= smoothstep(1., 1.-scale, vNormal.z);
    gl_FragColor = col;
    }
    ]]
}

