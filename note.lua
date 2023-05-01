function note()
    background(156, 218, 222)
    pushStyle()
    textWrapWidth(WIDTH/1.5)
    button([[Note: SimpleButtons will create a "ButtonTables" tab in your project. 

Don't be alarmed--this is just how it tracks your custom button positions.]] )
    popStyle()
    button("start", function() currentScreen = greetingScreen end)
end
