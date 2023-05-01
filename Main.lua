
function setup()
    supportedOrientations(LANDSCAPE_ANY)
    
    textMode(CENTER)
    fill(109, 167, 214)
    fontSize(SB.baseFontSize)
    
    currentScreen = greetingScreen
    
    parameter.action("restore default positions", function()
        SB.restoreDefaultPositions()
    end)
    
    testFindDeletableButtons()
end

function draw()    
    currentScreen()
end
