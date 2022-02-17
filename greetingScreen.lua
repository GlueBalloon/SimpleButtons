function greetingScreen()
    
    background(156, 222, 193)

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
