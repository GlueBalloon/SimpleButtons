function greetingScreen()
    
    background(156, 222, 193)
    
    --[[
    window("screen-size window", {ICONS, 
        {asset.builtin.Blocks.Brick_Grey, "helpers"},
        {asset.builtin.Blocks.Brick_Red, "geese"},
        {asset.builtin.Blocks.Sand, "nice people"},
        {asset.builtin.Blocks.Snow, "Portugal"},
        {asset.builtin.Blocks.Stone, "ranch dressing"},
        {asset.builtin.Blocks.Stone_Browniron_Alt, "coal"},
        {asset.builtin.Blocks.Dirt, "mixers"},
        {asset.builtin.Blocks.Dirt_Sand, "nimble bits"},
        {asset.builtin.Blocks.Fence_Stone, "Halloween"}
    })
    
    window("window title", {COLUMN, "button 1", "button 2"})
    if true then return end
    ]]
    
    

    pushStyle()
    font("Verdana-BoldItalic")
    fontSize(fontSize() * 3)
    button("Hi!")
    
    popStyle()
    
    button("This is a SimpleButton!")
    
    button("It sizes itself to fit any text...")
    
    button([[
...it can even
accommodate
a text block...]] )
    
pushStyle()
    fontSize(fontSize() * 0.9)
    button([[
...and you can also manually 
set the button dimensions 
if you want.]], nil, WIDTH * 0.7, WIDTH * 0.18 )
    popStyle()
    
    button("next", function() currentScreen = actionsDemo end)
    
end
