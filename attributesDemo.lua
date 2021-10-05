function attributesDemo()
    background(156, 201, 222)
    
    pushStyle()
    
    button(
    [[Simple buttons work mostly 
just like Codea's
other 2D elements.]])

fill(171, 178, 196)

button(
[[They get their fill
color from fill().]])

strokeWidth(19)

button("StrokeWidth from strokeWidth().")

stroke(185, 97, 211)

button("Stroke color from stroke().")

font("AmericanTypewriter-Bold")

button("Font from font().")

fontSize(simpleButtons.baseFontSize * 1.4)

button("And font size from fontSize()")

fontSize(simpleButtons.baseFontSize * 0.9)

button("(but you can set a custom font color too)", nil, nil, nil, color(28, 86, 141))

popStyle()
    button("next", function() currentScreen = screenChangingDemo end)
end
