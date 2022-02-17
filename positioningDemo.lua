function positioningDemo()
    background(156, 222, 218)
    
    button([[
Positioning is wayyy simple too!
Just tap "buttons are draggable" 
in the Parameters panel and
drag 'em around!]])

button("Try it!")

button("They always remember their positions between launches.")

button([[
You can also manually set x & y if you want,
but then you can't drag them.]], nil, nil, nil, nil, WIDTH/2, HEIGHT*0.15)
    
    button("start", function() currentScreen = greetingScreen end)

end
