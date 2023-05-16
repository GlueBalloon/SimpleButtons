
function setup()    
    testTabExists()
    testExtractFunctionCode()
    testTextPatternFound()
    testPatternMatching()
    testButtonTextFound()
    testCodeIndexedByTabExcludingButtons()
    testUiWithNonValidTabs()
    testIsStringInQuotesInString()
    testIsStringInBracketsInString()
    testIsStringInButtonCallWithSpaces()
    testIsStringInStringUsingAnyDemarcation()
    testUiWithNonValidTexts()
    testCombineButtonTables()
    --testdeletableButtonTables()
    --testUiWithNonValidFunctions()
    
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
    
    --print("Normalized expectedCode:", expectedCode)
    --print("Normalized actualCode:", actualCode)
    
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
        
        --[[
        print("traceback:", testTraceback)
        print("tab:", tab)
        print("functionName:", functionName)
        print("functionCode:", functionCode)
        print("pattern:", pattern)
        print("buttonTextFound:", tostring(buttonTextFound))
        ]]
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

function testdeletableButtonTables()
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
    
    -- Call deletableButtonTables and validate the results
    local deletableButtons = SB.deletableButtonTables()
    for _, ui in ipairs(uiData) do
        local shouldBeDeletable = ui.deletable
        local isDeletable = deletableButtons[ui.traceback] or false
        -- print("traceback: " .. ui.traceback)
        -- print("shouldBeDeletable: " .. tostring(shouldBeDeletable))
        -- print("isDeletable: " .. tostring(isDeletable))
        assert(isDeletable == shouldBeDeletable, "Button deletion status mismatch")
    end
    
    -- Clean up by deleting the test tabs
    for _, tab in ipairs(testTabs) do
        saveProjectTab(tab.name, "")
    end
    
    print("passed testdeletableButtonTables")
end



-- Test functions
function testUiWithNonValidTabs()
    -- Set up test data
    local projectTabs = {"Tab1", "Tab2"}
    local uiData = {
        ["Tab1,buttonFunc1,1"] = {text = "Button1"},
        ["Tab3,buttonFunc3,1"] = {text = "NonExistentButton"}
    }
    
    local buttonsWithNoTabs = SB.uiWithNonValidTabs(uiData, projectTabs)
    assert(buttonsWithNoTabs["Tab3,buttonFunc3,1"], "Button with no tab not found")
    assert(not buttonsWithNoTabs["Tab1,buttonFunc1,1"], "Button with existing tab incorrectly marked")
    print("passed testUiWithNonValidTabs")
end

function testUiWithNonValidFunctions()
    -- Set up test data
    local projectTabs = {"Tab1", "Tab2", "Tab3"}
    local uiData = {
        ["Tab1,buttonFunc1,1"] = {text = "Button1"},
        ["Tab2,nonExistentFunction,1"] = {text = "NonExistentFunctionButton"}
    }
    
    -- Save test tabs
    saveProjectTab("Tab1", "function buttonFunc1()\n    SB.button({text = [[Button1]]})\nend")
    saveProjectTab("Tab2", "function buttonFunc2()\n    SB.button({text = [[Button2]]})\nend")
    
    local buttonsWithNoFunctions = SB.uiWithNonValidFunctions(uiData, projectTabs)
    
    -- print("Buttons with no functions:")
    for traceback, _ in pairs(buttonsWithNoFunctions) do
        print(traceback)
    end
    
    assert(buttonsWithNoFunctions["Tab2,nonExistentFunction,1"], "Button with no function not found")
    assert(not buttonsWithNoFunctions["Tab1,buttonFunc1,1"], "Button with existing function incorrectly marked")
    
    -- Clean up by deleting the test tabs
    saveProjectTab("Tab1", "")
    saveProjectTab("Tab2", "")
    
    print("passed testUiWithNonValidFunctions")
end

function testCombineButtonTables()
    local buttonTable1 = {["Tab1,buttonFunc1,1"] = true}
    local buttonTable2 = {["Tab2,buttonFunc2,1"] = true}
    local combinedButtonTable = SB.combineButtonTables(buttonTable1, buttonTable2)
    
    assert(combinedButtonTable["Tab1,buttonFunc1,1"], "Button from table1 not found in combined table")
    assert(combinedButtonTable["Tab2,buttonFunc2,1"], "Button from table2 not found in combined table")
    print("passed testCombineButtonTables")
end

function generateTestUI()
    local codeByTab = SB.codeIndexedByTabExcludingButtons()
    local validTable, validKey = button("buttonMadeWithString")
    local varNameForString = "buttonMadeWithVarName"
    local notValidTable, notValidKey = button(varNameForString)
    local testUI = {
        [validKey] = validTable,
        [notValidKey] = notValidTable
    }
    return testUI, codeByTab, validKey, notValidKey
end

function testUiWithNonValidTexts()
    -- Set up test data
    local testUI, codeByTab, validKey, notValidKey = generateTestUI()
    
    local stashedFlagValue = SB.deletableButtonsChecked
    SB.deletableButtonsChecked = true
    
    -- reset flag
    SB.deletableButtonsChecked = stashedFlagValue
    
    print("Code for validKey:", codeByTab[validKey])
    print("Code for notValidKey:", codeByTab[notValidKey])
    
    local buttonsWithNoTexts = SB.uiWithNonValidTexts(testUI, codeByTab)
    
    assert(buttonsWithNoTexts[notValidKey], "Button with no text not found")
    assert(not buttonsWithNoTexts[validKey], "Button with existing text incorrectly marked")
    print("passed testUiWithNonValidTexts")
end



function testIsStringInQuotesInString()
    local stringToFind = "Test String"
    local codeWithQuotes = [[
        button("Test String")
        someOtherFunction("Some other string")
    ]]
    local codeWithoutString = [[
        button("Another string")
        someOtherFunction("Some other string")
    ]]

    assert(SB.isStringInQuotesInString(stringToFind, codeWithQuotes), "String with quotes not found")
    assert(not SB.isStringInQuotesInString(stringToFind, codeWithoutString), "Nonexistent string found")

    print("passed testIsStringInQuotesInString")
end

function testIsStringInBracketsInString()
    local stringToFind = "Test String"
    local codeWithDoubleBrackets = [[
        button(]] .. "[[" .. stringToFind .. "]]" .. [[)
        someOtherFunction(]] .. "[[" .. "Some other string" .. "]]" .. [[)
    ]]
    local codeWithoutString = [[
        button([["Another string"]] .. "]]" .. [[)
        someOtherFunction([["Some other string"]] .. "]]" .. [[)
    ]]

    assert(SB.isStringInBracketsInString(stringToFind, codeWithDoubleBrackets), "String with double brackets not found")
    assert(not SB.isStringInBracketsInString(stringToFind, codeWithoutString), "Nonexistent string found")

    print("passed testIsStringInBracketsInString")
end

function testIsStringInButtonCallWithSpaces()
    local stringToFind = "%\"" .. "Test String" .. "%\""
    local codeWithSpaces = [[
        button( "Test String" )
        someOtherFunction( "Some other string" )
    ]]
    local codeWithoutString = [[
        button("Another string")
        someOtherFunction("Some other string")
    ]]

    assert(SB.isStringInButtonCallWithSpaces(stringToFind, codeWithSpaces), "String with spaces not found")
    assert(not SB.isStringInButtonCallWithSpaces(stringToFind, codeWithoutString), "Nonexistent string found")

    print("passed testIsStringInButtonCallWithSpaces")
end

function testIsStringInStringUsingAnyDemarcation()
    local stringToFind = "Test String"
    local codeWithQuotes = [[
    button("Test String")
    someOtherFunction("Some other string")
]]
local codeWithDoubleBrackets = [[
button(]] .. "[[" .. stringToFind .. "]]" .. [[)
someOtherFunction(]] .. "[[" .. "Some other string" .. "]]" .. [[)
]]
local codeWithSpaces = [[
button( ]] .. "\"" .. stringToFind .. "\"" .. [[ )
someOtherFunction( ]] .. "[[" .. "Some other string" .. "]]" .. [[ )
]]
local codeWithoutString = [[
button("Another string")
someOtherFunction("Some other string")
]]

assert(SB.isStringInStringUsingAnyDemarcation(stringToFind, codeWithQuotes, "button(", ")"), "String with quotes not found")
assert(SB.isStringInStringUsingAnyDemarcation(stringToFind, codeWithDoubleBrackets, "button(", ")"), "String with double brackets not found")
assert(SB.isStringInStringUsingAnyDemarcation(stringToFind, codeWithSpaces, "button(", ")"), "String with spaces not found")
assert(not SB.isStringInStringUsingAnyDemarcation(stringToFind, codeWithoutString, "button(", ")"), "Nonexistent string found")
print("codeWithQuotes:", codeWithQuotes)
print("codeWithDoubleBrackets:", codeWithDoubleBrackets)
print("codeWithSpaces:", codeWithSpaces)
print("codeWithoutString:", codeWithoutString)
print("passed testIsStringInStringUsingAnyDemarcation")
end


function testCodeIndexedByTabExcludingButtons()
    -- Get code indexed by tab excluding ButtonTables tab
    local codeByTab = SB.codeIndexedByTabExcludingButtons()
    
    -- Get the list of project tabs
    local projectTabNames = listProjectTabs()
    
    -- Check if ButtonTables is not in the returned table
    assert(codeByTab["ButtonTables"] == nil, "ButtonTables tab should not be indexed")
    
    -- Make sure all tab names are in the keys for the returned table
    for _, tabName in ipairs(projectTabNames) do
        if tabName ~= "ButtonTables" then
            assert(codeByTab[tabName] ~= nil, "Tab " .. tabName .. " not found in returned table")
        end
    end
    
    -- Go through the table and compare the contents
    for tabName, tabCode in pairs(codeByTab) do
        local projectTabCode = readProjectTab(tabName)
        assert(tabCode == projectTabCode, "Code for tab " .. tabName .. " does not match")
    end
    
    print("passed testCodeIndexedByTabExcludingButtons")
end

function generateTestUI()

    local testUI = {}
    local variableInsteadOfLiteral = 
        "variableInsteadOfLiteral"
    local someOtherFunction = function() end
    
    local quotesTable, quotesKey = 
        button("Test Quotes String")
    someOtherFunction("Some other string")
    testUI[quotesKey] = quotesTable
    
    local doubleBracketsTable, doubleBracketsKey =
        button([[Test Double Brackets String]])
    someOtherFunction([[Some other string]])
    testUI[doubleBracketsKey] = 
        doubleBracketsTable
    
    local spacesTable, spacesKey = 
        button(  "Test Spaces String"  )
    someOtherFunction(  "Some other string"   )
    testUI[spacesTable] = spacesKey
    
    local wrongStringTable, wrongStringKey =
        button("Wrong string")
    someOtherFunction("Some other string")
    testUI[wrongStringTable] = wrongStringKey
    
    local invalidTable, invalidKey =
        button(variableInsteadOfLiteral)
    someOtherFunction("Some other string")
    testUI[invalidTable] = invalidKey
    
    return testUI
end

function testIsStringInStringUsingAnyDemarcation()
    local testUI = generateTestUI()
    local codeByTab = SB.codeIndexedByTabExcludingButtons()
    local fullCode = table.concat(codeByTab)
    
    for trace, tableValue in pairs(testUI) do
        local stringToFind = tableValue.text
        assert(SB.isStringInStringUsingAnyDemarcation(stringToFind, fullCode, "button(", ")"),
        "String " .. stringToFind .. " not found")
    end
    
    print("passed testIsStringInStringUsingAnyDemarcation")
end

function testUiWithNonValidTexts()
    local testUI = generateTestUI()
    local codeByTab = codeIndexedByTabExcludingButtons()
    
    local buttonsWithNoTexts = SB.uiWithNonValidTexts(testUI, codeByTab)
    
    for trace, tableValue in pairs(testUI) do
        local text = tableValue.text
        if text == "buttonMadeWithVarName" then
            assert(buttonsWithNoTexts[trace], "Button with no text not found")
        else
            assert(not buttonsWithNoTexts[trace], "Button with existing text incorrectly marked")
        end
    end
    
    print("passed testUiWithNonValidTexts")
end

