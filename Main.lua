
function setup()
    
    testTabExists()
    testExtractFunctionCode()
    testTextPatternFound()
    testPatternMatching()
    testButtonTextFound()

    testFindButtonsWithNoTabs()
    testFindButtonsWithNoFunctions()
    testFindButtonsWithNoTexts()
    testCombineButtonTables()
   -- testCheckForDeletableButtons()
    
    supportedOrientations(LANDSCAPE_ANY)
    
    textMode(CENTER)
    fill(109, 167, 214)
    fontSize(SB.baseFontSize)
    
    currentScreen = greetingScreen
    
    parameter.action("restore default positions", function()
        SB.restoreDefaultPositions()
    end)
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
    local testTabName = "TestTab"
    local testFunctionName = "testFunction"
    local testFunctionCode = "function " .. testFunctionName .. "()\n    SB.button({text = [[Test Button]]})\nend"
    
    saveProjectTab(testTabName, testFunctionCode)
    
    local expectedCode = SB.removeWhitespace(testFunctionCode)
    local actualCode = SB.removeWhitespace(SB.extractFunctionCode(testTabName, testFunctionName))
    
    print("Normalized expectedCode:", expectedCode)
    print("Normalized actualCode:", actualCode)
    
    assert(actualCode == expectedCode, "Function code does not match the expected code")
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
    local testTab = "TestTab"
    local testFunc = "testFunction"
    local testTraceback = testTab .. "," .. testFunc .. ",1"
    
    local ui = {
        text = "Test Button",
        x = 0.5, y = 0.5,
        width = 100, height = 50,
        action = SB.defaultButtonAction
    }
    
    -- Create a test tab with a test function containing the button text
    local testTabContent = "function " .. testFunc .. "()\n    SB.button({text = [[" .. ui.text .. "]]})\nend"
    saveProjectTab(testTab, testTabContent)
    
    local buttonTextExists = SB.buttonTextFound(testTraceback, ui)
    
    -- Add some print statements for debugging
    if not buttonTextExists then
        local tab, functionName = string.gmatch(testTraceback, "(%g*),(%g*),")()
        local functionCode = SB.extractFunctionCode(tab, functionName)
        local pattern = "SB%.button%b()%s-%b{}%s-%b{}%s-%[%[" .. ui.text .. "%]%]"
        local buttonTextFound = functionCode:find(pattern)
        
        print("traceback:", testTraceback)
        print("tab:", tab)
        print("functionName:", functionName)
        print("functionCode:", functionCode)
        print("pattern:", pattern)
        print("buttonTextFound:", tostring(buttonTextFound))
    end
    
    assert(buttonTextExists, "Existing button text not found")
    
    -- Clean up by deleting the test tab
    saveProjectTab(testTab, "")
    
    print("passed testButtonTextFound")
end


function testPatternMatching()
    local sampleFunctionCode = [[
    function testFunc()
        SB.button(
        {text = "Hello", x = 100, y = 100},
        {width = 100, height = 100},
        {action = function() print("Clicked!") end}
        )
    end
]]

local buttonText = "Hello"
local pattern = "SB%.button%s-%(%s-%{%s-text%s-=%s-%[%[" .. buttonText .. "%]%]"
local matchFound = sampleFunctionCode:find(pattern)
if not matchFound then
pattern = "SB%.button%s-%(%s-%{%s-text%s-=%s-\"" .. buttonText .. "\""
matchFound = sampleFunctionCode:find(pattern)
end
assert(matchFound, "Pattern not matched")
print("passed testPatternMatching")
end

function testCheckForDeletableButtons()
    -- Set up test data
    local testTabs = {
        {name = "Tab1", content = "function buttonFunc1()\n    SB.button({text = [[Button1]]})\nend"},
        {name = "Tab2", content = "function buttonFunc2()\n    SB.button({text = [[Button2]]})\nend"},
        {name = "Tab3", content = "function buttonFunc3()\n    SB.button({text = [[NonExistentButton]]})\nend"}
    }
    
    -- Save test tabs
    for _, tab in ipairs(testTabs) do
        saveProjectTab(tab.name, tab.content)
    end
    
    -- Set up test UI data
    local uiData = {
        {traceback = "Tab1,buttonFunc1,1", text = "Button1", deletable = false},
        {traceback = "Tab2,buttonFunc2,1", text = "Button2", deletable = false},
        {traceback = "Tab3,buttonFunc3,1", text = "NonExistentButton", deletable = true}
    }
    
    -- Update the SB.ui table with the test UI data
    for _, ui in ipairs(uiData) do
        SB.ui[ui.traceback] = {text = ui.text}
    end
    
    -- Call checkForDeletableButtons and validate the results
    local deletableButtons = SB.checkForDeletableButtons()
    for _, ui in ipairs(uiData) do
        local shouldBeDeletable = ui.deletable
        local isDeletable = deletableButtons[ui.traceback] or false
        print("traceback: " .. ui.traceback)
        print("shouldBeDeletable: " .. tostring(shouldBeDeletable))
        print("isDeletable: " .. tostring(isDeletable))
        assert(isDeletable == shouldBeDeletable, "Button deletion status mismatch")
    end
    
    -- Clean up by deleting the test tabs
    for _, tab in ipairs(testTabs) do
        saveProjectTab(tab.name, "")
    end
    
    print("passed testCheckForDeletableButtons")
end



-- Test functions
function testFindButtonsWithNoTabs()
    -- Set up test data
    local projectTabs = {"Tab1", "Tab2"}
    local uiData = {
        ["Tab1,buttonFunc1,1"] = {text = "Button1"},
        ["Tab3,buttonFunc3,1"] = {text = "NonExistentButton"}
    }
    
    local buttonsWithNoTabs = SB.findButtonsWithNoTabs(uiData, projectTabs)
    assert(buttonsWithNoTabs["Tab3,buttonFunc3,1"], "Button with no tab not found")
    assert(not buttonsWithNoTabs["Tab1,buttonFunc1,1"], "Button with existing tab incorrectly marked")
    print("passed testFindButtonsWithNoTabs")
end

function testFindButtonsWithNoFunctions()
    -- Set up test data
    local projectTabs = {"Tab1", "Tab2", "Tab3"}
    local uiData = {
        ["Tab1,buttonFunc1,1"] = {text = "Button1"},
        ["Tab2,nonExistentFunction,1"] = {text = "NonExistentFunctionButton"}
    }
    
    -- Save test tabs
    saveProjectTab("Tab1", "function buttonFunc1()\n    SB.button({text = [[Button1]]})\nend")
    saveProjectTab("Tab2", "function buttonFunc2()\n    SB.button({text = [[Button2]]})\nend")
    
    local buttonsWithNoFunctions = SB.findButtonsWithNoFunctions(uiData, projectTabs)
    
    print("Buttons with no functions:")
    for traceback, _ in pairs(buttonsWithNoFunctions) do
        print(traceback)
    end
    
    assert(buttonsWithNoFunctions["Tab2,nonExistentFunction,1"], "Button with no function not found")
    assert(not buttonsWithNoFunctions["Tab1,buttonFunc1,1"], "Button with existing function incorrectly marked")
    
    -- Clean up by deleting the test tabs
    saveProjectTab("Tab1", "")
    saveProjectTab("Tab2", "")
    
    print("passed testFindButtonsWithNoFunctions")
end


function testFindButtonsWithNoTexts()
    -- Set up test data
    local projectTabs = {"Tab1", "Tab2", "Tab3"}
    local uiData = {
        ["Tab1,buttonFunc1,1"] = {text = "Button1"},
        ["Tab2,buttonFunc2,1"] = {text = "NonExistentTextButton"}
    }
    
    local buttonsWithNoTexts = SB.findButtonsWithNoTexts(uiData, projectTabs)
    assert(buttonsWithNoTexts["Tab2,buttonFunc2,1"], "Button with no text not found")
    assert(not buttonsWithNoTexts["Tab1,buttonFunc1,1"], "Button with existing text incorrectly marked")
    print("passed testFindButtonsWithNoTexts")
end

function testCombineButtonTables()
    local buttonTable1 = {["Tab1,buttonFunc1,1"] = true}
    local buttonTable2 = {["Tab2,buttonFunc2,1"] = true}
    local combinedButtonTable = SB.combineButtonTables(buttonTable1, buttonTable2)
    
    assert(combinedButtonTable["Tab1,buttonFunc1,1"], "Button from table1 not found in combined table")
    assert(combinedButtonTable["Tab2,buttonFunc2,1"], "Button from table2 not found in combined table")
    print("passed testCombineButtonTables")
end

--[[
SB.deletableButtonTables = function ()
if SB.didSearchForDeletables then
return
else
SB.didSearchForDeletables = true
end

local buttonDataStrings = SB.allButtonDataStrings()
local projectTabs = listProjectTabs()
local functionNames = SB.functionNamesFrom(projectTabs)

local uiWithNonValidTabs = SB.uiWithNonValidTabs(buttonDataStrings, projectTabs)
local uiWithNonValidFunctions = SB.uiWithNonValidFunctions(buttonDataStrings, functionNames)
local uiWithNonValidTexts = SB.uiWithNonValidTexts(buttonDataStrings)
local uiPossibleDuplicates = SB.uiPossibleDuplicates(buttonDataStrings)

local deletables = SB.combineButtonTables(uiWithNonValidTabs, uiWithNonValidFunctions, uiWithNonValidTexts, uiPossibleDuplicates)
return deletables
end

]]
    