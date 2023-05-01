ROW, COLUMN, ICONS = 1, 2, 3

function window(title, contents, w, h, x, y)
    --insert window title after content type 
    local padding, hi
    if contents[1] == COLUMN then
        goto column
    elseif contents[1] == ICONS then
        goto icons
    end
    
    ::column::
    if true then
        local padding = SB.standardLineHeight() * 0.5
        local width, height = SB.contentDimensions(contents)
        local minWidth = textSize("min window width is biiiiig")
        local width = math.max(width, minWidth)
        local paddedH = height + ((#contents + 3) * padding)
        local paddedW = width + (padding * 2)
        pushStyle()
        fill(29, 180, 224, 162)
        local container = button("", nil, paddedW, paddedH, nil, x, y, {isWindow = true, contents = contents})
        popStyle()
        local x, y = container.x * WIDTH, container.y * HEIGHT
        
        local windowTop = y + (paddedH * 0.5)
        local spacedY = windowTop - padding
        pushStyle() noFill()
        local titleButton = button(title, nil, paddedH, padding * 2, nil, x, spacedY - padding)
        popStyle()
        spacedY = spacedY - (padding * 3)
        pushStyle()
        fill(178, 213, 224, 162)
        for i=2, #contents do 
            local _, thisH = SB.buttonDimensionsFor(contents[i])
            local thisB = button(contents[i], nil, width, nil, nil, x, spacedY - (thisH * 0.5))
            spacedY = spacedY - thisH - padding
        end
        return 
    end
    
    ::icons::
    pushStyle()
    fill(255)
    
    local _, titleH = textSize(title)
    text(title, WIDTH/2, HEIGHT - (titleH * 1.25))
    local iconSpaceW = WIDTH / 6
    local iconSpaceH = HEIGHT / 2.5
    local iconSize = iconSpaceW * 0.7
    local x = iconSpaceW / 2
    
    textAlign(CENTER)
    textWrapWidth(iconSpaceW * 0.95)
    for ii = 1, math.ceil((#contents - 1) / 6) do
        x = iconSpaceW / 2
        for i = 1, 6 do
            local index = i + 1 + ((ii - 1) * 6)
            if contents[index] then
                local spriteY = HEIGHT - iconSpaceH / 2
                spriteY = spriteY - (iconSpaceH * (ii - 1)) - titleH
                
                sprite(contents[index][1], x, spriteY, iconSize, iconSize)
                
                local textW, textH = textSize(contents[index][2])
                local textY = spriteY - ((iconSize + textH) * 0.6)
                
                text(contents[index][2], x, textY)
                
                x = x + iconSpaceW
                -- sprite(asset.builtin.Blocks.Brick_Grey,x,iconSpaceH)
                --      sprite(asset.builtin.Blocks.Blank_White)
            end 
        end
    end
    popStyle()
end

--used in window experiment:
--[[
SB.contentDimensions = function(content) 
    local pieces = {} 
    for i=2, #content do 
        local dimensions = {SB.buttonDimensionsFor(content[i])}
        table.insert(pieces, dimensions)
    end 
    local totalW, totalH = 0, 0
    if content[1] == COLUMN then 
        for _, piece in ipairs(pieces) do 
            totalH = totalH + piece[2]
            totalW = math.max(totalW, piece[1])
        end
    end
    -- print(totalW, totalH) 
    return totalW, totalH
end
]]