
function setup()
    supportedOrientations(LANDSCAPE_ANY)
    
    textMode(CENTER)
    fill(109, 167, 214)
    fontSize(simpleButtons.baseFontSize)
    
    currentScreen = greetingScreen
    
    parameter.action("restore default positions", function()
        simpleButtons.restoreDefaultPositions()
    end)

end

function draw()
    
    currentScreen()

end
