
-- simpleButtons: provides various functions for UI pieces:

--  enables pieces to be initialized with defaults

--  manages how pieces look and behave

simpleButtons = {}
simpleButtons.baseFontSize = math.max(WIDTH, HEIGHT) * 0.027
simpleButtons.ui = {}
simpleButtons.useGrid = false
simpleButtons.gridSize = 15
simpleButtons.secondLineInfoFrom = function(traceback)
    local iterator = string.gmatch(traceback,"(%g*):(%g*): in function '(%g*)'")
    iterator() -- not interested in first line bc it'll always be from here
    local tab, lineNumber, functionName = iterator()
    return {tab = tab, functionName = functionName, lineNumber = functionName, all = tab..","..functionName..","..lineNumber}
end


parameter.boolean("buttons are draggable", false)
--parameter.boolean("snap_to_grid", false, function()
--    simpleButtons.useGrid = snap_to_grid
--end)


simpleButtons.defaultButton = function(bText, traceback)
    simpleButtons.ui[traceback] = {text=bText,
    x=0.5, y=0.5, action=simpleButtons.defaultButtonAction}
    return simpleButtons.ui[traceback]
end


simpleButtons.defaultButtonAction = function()
    print("this is the default button action")
end


simpleButtons.doAction = function(traceback)
    if simpleButtons.ui[traceback].action == nil then
        return
    else
        simpleButtons.ui[traceback].action()
    end
end


simpleButtons.clearRenderFlags = function()
    for _, ui in pairs(simpleButtons.ui) do
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
simpleButtons.evaluateTouchFor = function(traceback, touch)
    if touch == nil then
        touch = CurrentTouch
    end
    if simpleButtons.thisButtonIsActivated(traceback, touch) then
        simpleButtons.makeActivatedButtonRespond(traceback, touch)
    end
end

--thisButtonIsActivated: called to decide if this button should respond to this touch
--precondition: name and touch cannot be nil
--postconditions:
--  activatedButton has been set or unchanged (note that it is never cleared here)
--  boolean returned true if the given button is the activatedButton, false if not
simpleButtons.thisButtonIsActivated = function(traceback, touch)
    --if there is already an activatedButton and this isn't it, return false
    if activatedButton ~= nil and activatedButton ~= traceback then
        return false
    end
    --if there is no activatedButton, see if this should become activatedButton
    if activatedButton == nil then
        --if touch state is BEGAN and touch is inside button, set it to activatedButton
        if touch.state == BEGAN and simpleButtons.touchIsInside(traceback, touch) then
            activatedButton = traceback
        else
            --otherwise return false
            return false
        end
    end
    --here only reached if this is activated button (or has become it), so return true
    return true
end

--simpleButtons.touchIsInside: calculated using touch's distance from this piece
--preconditions: name and touch cannot be nil, and touched object is basically rectangular
simpleButtons.touchIsInside = function(traceback, touch)
    local adjX, adjY = simpleButtons.ui[traceback].x*WIDTH, simpleButtons.ui[traceback].y*HEIGHT
    local xDistance = math.abs(touch.x-adjX)
    local yDistance = math.abs(touch.y-adjY)
    insideX = xDistance < simpleButtons.ui[traceback].width /2
    insideY = yDistance < simpleButtons.ui[traceback].height /2
    if insideX and insideY then
        return true
    else
        return false
    end
end

--makeActivatedButtonRespond: decide how the given button should react to given touch
--precondition: button and touch cannot be nil, button must be activatedButton
simpleButtons.makeActivatedButtonRespond = function(traceback, touch)
    --move button if it should be moved
    if buttons_are_draggable then
        simpleButtons.evaluateDrag(traceback, touch)
    end
    if touch.state == BEGAN or touch.state == MOVING then
        simpleButtons.ui[traceback].isTapped = true
    end
    --if this is an end touch, do a button action, or save new position, or do nothing
    if touch.state == ENDED or touch.state == CANCELLED or not touch then
        if buttons_are_draggable then
            if touch.tapCount == 1 then
                simpleButtons.ui[traceback].isTapped = true
                simpleButtons.doAction(traceback)
            else
                simpleButtons.savePositions()
            end
        elseif simpleButtons.touchIsInside(traceback, touch) then
            simpleButtons.ui[traceback].isTapped = true
            simpleButtons.doAction(traceback)
        end
        activatedButton = nil
    end
end

simpleButtons.evaluateDrag = function (traceback, touch)
    if touch.state == MOVING then
        local x,y = touch.x, touch.y
        --make x and y into percentages of width and height
        x, y = x / WIDTH, y/HEIGHT
        --rounds x and y if using grid
        if simpleButtons.useGrid then
            local divisions = 40
            local gridW, gridH = WIDTH / divisions, HEIGHT / divisions
            x = touch.x + simpleButtons.gridSize - (touch.x + simpleButtons.gridSize) % (simpleButtons.gridSize * 2) 
            y = touch.y + simpleButtons.gridSize - (touch.y + simpleButtons.gridSize) % (simpleButtons.gridSize * 2)
        end   
        simpleButtons.ui[traceback].x = x
        simpleButtons.ui[traceback].y = y
    end
end


simpleButtons.savePositions = function ()
    --[[
    --old method for writing buttons at the bottom of this tab
    --required this line to be put between code and button tables:
    --#*@savedButtonTablesWillBeWrittenAfterHere
    local temp=readProjectTab("SimpleButtons")
    dataString = ""
    local dividerString = "--#*@savedButtonTables"
    dividerString = dividerString.."WillBeWrittenAfterHere"
    local pos, term=string.find(temp,dividerString)
    if pos~=nil then
        local str=string.sub(temp,1,term)
        dataString = dataString..str.."\n\n\n"
    end
]]
    local dataString = ""
for traceback, ui in pairs(simpleButtons.ui) do
dataString = dataString.."simpleButtons.ui[ [["..traceback.."]] ] = \n"
dataString = dataString.."    {text = [["..ui.text.."]],\n"
dataString = dataString.."    x = "..ui.x
dataString = dataString..", y = "..ui.y..",\n"
dataString = dataString.."    action = simpleButtons.defaultButtonAction,\n}\n\n"
end
saveProjectTab("ButtonTables",dataString)
end

--button only actually needs a name to work, the rest have defaults
function button(bText, action, width, height, fontColor, x, y)
--get traceback info 
--buttons have to be indexed by traceback
--this lets different buttons have the same texts
local trace = simpleButtons.secondLineInfoFrom(debug.traceback())
--check for existing table matching key
local tableToDraw = simpleButtons.ui[trace.all]
--reject the table if the text doesn't match, though
if tableToDraw and tableToDraw.text ~= bText then
-- print("found table from trace but text doesn't match "..'"'..bText..'"')
--store table that was found under a modified key, so table doesn't get overwritten
local newKey = trace.all.."+"..tableToDraw.text
simpleButtons.ui[newKey] = tableToDraw
tableToDraw = nil
end
--if there's no matching table look for an identical one
if not tableToDraw then
--Make a function to replace any identical table found
function setTableToDrawUsingNewId(newId, tableToUpdate, oldId)            
    --update table to use new traceback id
    simpleButtons.ui[newId] = tableToUpdate
    --clear the old traceback id
    simpleButtons.ui[oldId] = nil
    --and set this as tableToDraw
    tableToDraw = simpleButtons.ui[newId]
end
--find any buttons that match text
-- print("finding buttons with text: "..bText)
local textMatches = {}
for k, buttonTable in pairs(simpleButtons.ui) do
    if buttonTable.text == bText then
        if type(k) == "string" then
            table.insert(textMatches, buttonTable)
            --add table's key to table (won't be stored permanently, so no worries)
            buttonTable.key = k
            -- print("button matches text:")
            -- print(buttonTable.x)
        else
            -- print("found key that's not a string: ", k)
        end
    end
end 
--  print("found "..#textMatches.." with same text")
--if only 1 button matches text, use its values but replace its key
if #textMatches == 1 then
    setTableToDrawUsingNewId(trace.all, textMatches[1], textMatches[1].key)  
    --if more than one button matches text
elseif #textMatches > 1 then 
    --find out how many match this tab and function
    --print("finding matches for tab and function: "..trace.tab..", "..trace.functionName)
    local matchers = {}
    for _, buttonTable in ipairs(textMatches) do
        --extract the tab and functiom
        local tab, functionName = string.gmatch(buttonTable.key,"(%g*),(%g*),")()
        --   print(buttonTable.text)
        --   print("extracted: ", tab, ", ",functionName)
        --  print("current: ", trace.tab, ", ", trace.functionName)
        --compare to current
        if tab == trace.tab and functionName == trace.functionName then 
            --store matches
            -- print("storing match")
            table.insert(matchers, buttonTable)
        end
    end
    --if only 1 button matches tab and function and text, use it
    if #matchers == 1 then
        -- print("only one match, should use found values") 
        setTableToDrawUsingNewId(trace.all, matchers[1], matchers[1].key)  
        --if more than one button matches tab and function and text
    elseif #matchers > 1 then 
        -- print("more than one match, have to guess!") 
        --just gonna have to guess!
        --find the first one without an 'assigned' value
        for _, buttonTable in ipairs(matchers) do 
            if not buttonTable.assigned then 
                --update it to use *this* traceback id
                setTableToDrawUsingNewId(trace.all, buttonTable, buttonTable.key)
                --mark it 'assigned'
                simpleButtons[trace.all].assigned = true
            end
        end 
    else  
        --  print("no buttons match text, tab, and function") 
    end
end
else 
-- print("found table to draw")
-- print(tableToDraw.x)
end
--if there's still not a tableToDraw, make a new one
if not tableToDraw or tableToDraw.text ~= bText then
tableToDraw = simpleButtons.defaultButton(bText, trace.all)
end
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
width = width or boundsW + (lineHeight * 1.8)
height = height or boundsH + lineHeight
--set button drawing values, using saved values if none passed in
--the saved values should already be percentages
local x,y = x or tableToDraw.x, y or tableToDraw.y
--update the stored values if necessary
if x ~= tableToDraw.x then
simpleButtons.ui[trace.all].x = x
end
if y ~= tableToDraw.y then
simpleButtons.ui[trace.all].y = y
end
if width ~= tableToDraw.width then
simpleButtons.ui[trace.all].width = width
end
if height ~= tableToDraw.height then
simpleButtons.ui[trace.all].height = height
end

--can't use fill() as font color so default to white
fontColor = fontColor or color(255)

--'action' is called outside of this function
if action then
simpleButtons.ui[trace.all].action = action
end

--get the actual x and y from the percentages
x, y = x*WIDTH, y*HEIGHT
pushStyle()
local startingFill = color(fill())
if tableToDraw.isTapped == true then
fill(fontColor)
stroke(startingFill)
end
local radius = height/2
if radius > 30 then
radius = 30
end
--draw the button
roundedRectangle{
x=x,y=y,w=width,h=height,
radius=radius
}
--draw the text
if tableToDraw.isTapped == true then
fill(startingFill)
else
fill(fontColor)
end
text(bText, x, y)
popStyle()
simpleButtons.ui[trace.all].isTapped = false
--handle touches (wherein action gets called or not)
simpleButtons.evaluateTouchFor(trace.all)
--set the flag that shows we rendered (used with blurring)
simpleButtons.ui[trace.all].didRenderAlready = true
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

