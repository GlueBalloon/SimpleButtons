function greetingScreen()
    
    background(156, 222, 193)
    
    button("Hi!")    
    button("This is a SimpleButton!")
    button("It sizes itself to fit any text...")
    button([[
    ...it can even
    accommodate
a text block...]] )
button([[
...and you can also manually 
set the button dimensions 
if you want.]], nil, WIDTH * 0.6, WIDTH * 0.2 )   
button("next", function() currentScreen = actionsDemo end)   

end
