function attributesDemo()
    background(156, 201, 222)
    
    pushStyle()
    fill(220, 72, 152)
    
    button([[
Simple buttons are 
"Codea-like". They work 
mostly just like Codea's
other 2D elements.]])

    fill(137, 183, 205)
    stroke(237, 240, 241)
    strokeWidth(5)

button(
[[They get their fill
color from fill().]])

strokeWidth(38)

button("StrokeWidth from strokeWidth().")

stroke(48, 156, 240, 206)

button("Stroke color from stroke().")

font("AmericanTypewriter-Bold")

button("Font from font().")

fontSize(simpleButtons.baseFontSize * 1.8)

button("And font size from fontSize()")

fontSize(simpleButtons.baseFontSize * 0.9)

button("(and you can set a custom font color too)", nil, nil, nil, color(28, 86, 141))

popStyle()
    button("next", function() currentScreen = screenChangingDemo end)
end
