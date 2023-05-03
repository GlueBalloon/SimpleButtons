
function setup()
    
    testTabExists()
    testExtractFunctionCode()
    testTextPatternFound()
    testButtonTextFound()
    
    if true then return end
    
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

function testTabExists()
    local projectTabs = {"Main", "Tab1", "Tab2"}
    local existingTab = "Main"
    local nonexistentTab = "NonexistentTab"
    
    local tabExists = SB.tabExists(existingTab, projectTabs)
    local tabDoesNotExist = not SB.tabExists(nonexistentTab, projectTabs)
    
    assert(tabExists, "Existing tab not found")
    assert(tabDoesNotExist, "Nonexistent tab found")
    print("passed testTabExists")
end

function testExtractFunctionCode()
    local tabCode = "function testFunction1() end\nfunction testFunction2() end"
    local existingFunction = "testFunction1"
    local nonexistentFunction = "nonexistentFunction"
    
    local functionCodeExists = SB.extractFunctionCode(existingFunction, tabCode)
    local functionCodeDoesNotExist = not SB.extractFunctionCode(nonexistentFunction, tabCode)
    
    assert(functionCodeExists, "Existing function code not found")
    assert(functionCodeDoesNotExist, "Nonexistent function code found")
    print("passed testExtractFunctionCode")
end

function testTextPatternFound()
    local functionCode = "SB.button({text = [[Test Button]]})"
    local existingText = "Test Button"
    local nonexistentText = "Nonexistent Text"
    
    local textExists = SB.textPatternFound(existingText, functionCode)
    local textDoesNotExist = not SB.textPatternFound(nonexistentText, functionCode)
    
    assert(textExists, "Existing text not found")
    assert(textDoesNotExist, "Nonexistent text found")
    print("passed testTextPatternFound")
end

function testButtonTextFound()
    local testTabName = "TestTab"
    local testFuncName = "testFunction"
    
    local testTabCode = "function "..testFuncName.."()\n    SB.button({text = [[" .. ui.text .. "]]})\nend"
    saveProjectTab(testTabName, testTabCode)
    
    local existingTraceback = testTabName .. "," .. testFuncName .. ",1"
    local ui = {
        text = "Test Button",
        x = 0.5, y = 0.5,
        width = 100, height = 50,
        action = SB.defaultButtonAction
    }
    
    local buttonTextExists = SB.buttonTextFound(existingTraceback, ui)
    assert(buttonTextExists, "Existing button text not found")
    
    -- Clean up the test tab
    saveProjectTab(testTabName, "")
    
    print("passed testButtonTextFound")
end