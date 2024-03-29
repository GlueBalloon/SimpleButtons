
function setup() 
    
    testMatchTableCounts()
    testMatchTableContents()
    testAppendUiTablesTo()
    testAppendSectionHeadingTo()
    testTablesWithUniqueTexts()
    testStartOfButtonTablesString()
    
--[[
    testSaveUniqueButtonTables()
    testGetTextValues()
    testSortUITables()
]]
    
    --[[
    testUiWithNonValidTexts()
    
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
    testHasStringWithAnyDemarcation()
    testUiWithNonValidFunctions()
    testCombineButtonTables()
    testDeletableButtonTables()
    ]]
    
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
    if currentScreen then
        currentScreen()
    end
end

function testGetTextValues()
    local luaString1 = "SB.ui[ [[stack traceback: SimpleButtons:303: in function 'button']] ] = \n" ..
    "{text = [[" .. "It sizes itself to fit any text..." .. "]],\n" ..
    "x = 0.42742890995261, y = 0.675,\n" ..
    "width = 240.76, height = 38.568,\n" ..
    "action = SB.defaultButtonAction\n}\n"
    
    local luaString2 = "SB.ui[ [[stack traceback: SimpleButtons:303: in function 'button']] ] = \n" ..
    "{text = [[" .. "    ...it can even\n    accommodate\na text block..." .. "]],\n" ..
    "x = 0.67002369668246, y = 0.6,\n" ..
    "width = 158.76, height = 77.568,\n" ..
    "action = SB.defaultButtonAction\n}\n"
    
    local luaString = luaString1 .. luaString2
    
    local texts = getTextValues(luaString)
    assert(#texts == 2, "Expected to find 2 text values")
    assert(texts[1] == "It sizes itself to fit any text...", "First text value doesn't match")
    assert(texts[2] == "    ...it can even\n    accommodate\na text block...", "Second text value doesn't match")
    
    print("passed testGetTextValues")
end

function getTextValues(luaString)
local textValues = {}
local pattern = "text%s=%s%[%[(.-)%]%]"  -- Pattern to find the text values in the lua string

for textValue in string.gmatch(luaString, pattern) do
table.insert(textValues, textValue)
end

return textValues
end

-- Function to get the text values from the UI tables
function getTextValuesFromUITables(uiTables)
    local textValues = {}
    for _, table in ipairs(uiTables) do
        textValues[#textValues + 1] = table.text
    end
    return textValues
end





function testTablesWithUniqueTexts()
    -- Setup
    local inputUI = {
        ["traceback1"] = { text = "Hello" },
        ["traceback2"] = { text = "Hello" },
        ["traceback3"] = { text = "World" }
    }
    
    -- Call the function
    local uniqueButtonTextTables, duplicateButtonTextTables = SB.tablesWithUniqueTexts(inputUI)
    
    -- Check the results
    assert(#uniqueButtonTextTables == 1, "Expected one unique button text table, got "..#uniqueButtonTextTables)
    for _, table in pairs(uniqueButtonTextTables) do
        assert(table.text == "World", "Expected unique button text to be 'World'")
    end
    
    assert(#duplicateButtonTextTables == 2, "Expected two duplicate button text tables")
    for _, table in pairs(duplicateButtonTextTables) do
        assert(table.text == "Hello", "Expected duplicate button text to be 'Hello'")
    end
    
    print("passed testTablesWithUniqueTexts")
end




local function generateTestButton(text, index, inputUI, testCode)
    local traceback = "Traceback " .. text .. " " .. index
    local uiTable = SB.defaultButton(text)
    inputUI[traceback] = uiTable
    
    -- Replace SB.ui[...] declaration with SB.button(...) call
    local buttonCode = SB.formatButtonDataString(traceback, uiTable)
    buttonCode = buttonCode:gsub("SB.ui%[ %[%[.*%]%] %] = ", "SB.button(")
    buttonCode = buttonCode:gsub("\n%}\n\n", ")")
    testCode = testCode .. buttonCode
    
    return inputUI, testCode
end

local function generateTestData(numUnique, numDuplicates, numNotMatched)
    local inputUI = {}
    local testCode = [[
    function sayHello()
    ]]

    -- Generate unique tables and matching code
    for i = 1, numUnique do
        local text = "Unique " .. i
        inputUI, testCode = generateTestButton(text, i, inputUI, testCode)
    end
    
    -- Generate duplicate tables and matching code
    for i = 1, numDuplicates do
        local text = "Duplicate"
        local uiTable = SB.defaultButton(text)
        if i == 1 then
            inputUI, testCode = generateTestButton(text, i, inputUI, testCode)
        else
            local traceback = "Traceback " .. text .. " " .. i
            inputUI[traceback] = uiTable
        end
    end
    
    -- Generate not matched tables (no matching code)
    for i = 1, numNotMatched do
        local text = "Not Matched " .. i
        local traceback = "Traceback " .. text .. " " .. i
        local uiTable = SB.defaultButton(text)
        inputUI[traceback] = uiTable
    end
    
    testCode = testCode .. 'end\n'
    
    return inputUI, testCode, numDuplicates, numUnique
end




-- Test function
function testMatchTableCounts()
    -- Setup
    local numUnique = math.random(1, 9)
    local numDuplicates = math.random(1, 9)
    local numNotMatched = math.random(1, 9)
    local inputUI, testCode, expectedDuplicates, expectedUniques = generateTestData(numUnique, numDuplicates, numNotMatched)
    
    -- Call the function
    local matchedTexts, notMatchedTexts = SB.tablesWithTextsFoundAndNot(inputUI, testCode)
    
    -- Check the results
    assert(#matchedTexts == expectedDuplicates + expectedUniques, "Expected " .. (expectedDuplicates + expectedUniques) .. " matched button text tables")
    assert(#notMatchedTexts == numNotMatched, "Expected " .. numNotMatched .. " not matched button text tables")
    
    print("passed testMatchTableCounts")
end

-- Test function
function testMatchTableContents()
    -- Setup
    local numUnique = math.random(1, 9)
    local numDuplicates = math.random(1, 9)
    local numNotMatched = math.random(1, 9)
    local inputUI, testCode, expectedDuplicates, expectedUniques = generateTestData(numUnique, numDuplicates, numNotMatched)
    
    -- Call the function
    local matchedTexts, notMatchedTexts = SB.tablesWithTextsFoundAndNot(inputUI, testCode)
    
    -- Create lookup tables for easy checking
    local matchedTextsLookup, notMatchedTextsLookup = {}, {}
    for _, tbl in ipairs(matchedTexts) do
        matchedTextsLookup[tbl.text] = true
    end
    for _, tbl in ipairs(notMatchedTexts) do
        notMatchedTextsLookup[tbl.text] = true
    end
    
    -- Check the results
    for _, tbl in pairs(inputUI) do
        if notMatchedTextsLookup[tbl.text] then
            assert(notMatchedTextsLookup[tbl.text], "Expected '" .. tbl.text .. "' to be in not matched button texts")
            assert(not matchedTextsLookup[tbl.text], "Expected '" .. tbl.text .. "' to not be in matched button texts")
        else
            assert(matchedTextsLookup[tbl.text], "Expected '" .. tbl.text .. "' to be in matched button texts")
            assert(not notMatchedTextsLookup[tbl.text], "Expected '" .. tbl.text .. "' to not be in not matched button texts")
        end
    end
    
    print("passed testMatchTableContents")
end

function testAppendUiTablesTo()
    -- Setup
    local targetString = "-- Existing data\n"
    local uiTables = {
        ["traceback for Hello, World!"] = SB.defaultButton("Hello, World!"),
        ["traceback for Hello, Test!"] = SB.defaultButton("Hello, Test!")
    }
    
    -- Call the function
    local result = SB.appendUiTablesTo(targetString, uiTables)
    
    -- Check the results
    local expected = "-- Existing data\n"
    for traceback, ui in pairs(uiTables) do
        expected = expected ..
        "SB.ui[ [[" .. traceback .. "]] ] = \n" ..
        "    {text = [[" .. ui.text .. "]],\n" ..
        "    x = " .. ui.x .. ", y = " .. ui.y .. ",\n" ..
        "    width = " .. tostring(ui.width) .. ", height = " .. tostring(ui.height) .. ",\n" ..
        "    action = SB.defaultButtonAction\n}\n\n"
    end
    
    --Print both the result and the expected strings for debugging
    --print("Expected:\n" .. expected)
    --print("Result:\n" .. result)
    
    assert(result == expected, "Expected formatted string did not match:\n"..result)
    
    print("passed testAppendUiTablesTo")
end




function testAppendSectionHeadingTo()
    local targetString = "Some existing text\n\n"
    local headingText = "MY NEW SECTION"
    local expectedOutput = "Some existing text\n\n-- MY NEW SECTION --\n\n"
    
    local result = SB.appendSectionHeadingTo(targetString, headingText)
    
    assert(result == expectedOutput, "Expected '" .. expectedOutput .. "', got '" .. result .. "'")
    
    print("Passed testAppendSectionHeadingTo")
end

function testSortUITables()
    -- Setup
    math.randomseed(os.time()) -- for generating different numbers each time
    local numUnique = math.random(1, 5) -- assuming a range from 1 to 5
    local numDuplicates = math.random(1, 5)
    local numNotMatched = math.random(1, 5)
    local inputUI, testCode = generateTestData(numUnique, numDuplicates, numNotMatched)
    
    -- Call the function to test
    local uniqueUITables, duplicateUITables, notMatchedUITables = SB.sortUITables(inputUI, testCode)
    
    -- Check the lengths of the returned tables
    assert(#uniqueUITables == numUnique, "Expected " .. numUnique .. " unique tables, got " .. #uniqueUITables)
    assert(#duplicateUITables == numDuplicates, "Expected " .. numDuplicates .. " duplicate tables, got " .. #duplicateUITables)
    assert(#notMatchedUITables == numNotMatched, "Expected " .. numNotMatched .. " not matched tables, got " .. #notMatchedUITables)
    
    -- Check the contents of the unique tables
    for i, table in ipairs(uniqueUITables) do
        assert(table.text == "Unique " .. i, "Expected unique table with text 'Unique " .. i .. "', got '" .. table.text .. "'")
    end
    
    -- Check the contents of the duplicate tables
    for _, table in ipairs(duplicateUITables) do
        assert(table.text == "Duplicate", "Expected duplicate table with text 'Duplicate', got '" .. table.text .. "'")
    end
    
    -- Check the contents of the not matched tables
    for i, table in ipairs(notMatchedUITables) do
        assert(table.text == "Not Matched " .. i, "Expected not matched table with text 'Not Matched " .. i .. "', got '" .. table.text .. "'")
    end
    
    print("Passed testSortUITables")
end

function testStartOfButtonTablesString()
    local numUnique, numDuplicates, numNotMatched = math.random(2, 5), math.random(2, 5), math.random(2, 5)
    local inputUI, testCode = generateTestData(numUnique, numDuplicates, numNotMatched)
    local uniques, duplicates, notMatched = SB.sortUITables(inputUI, testCode)
    
    local resultString = SB.stringForButtonTablesTab(uniques, duplicates, notMatched)
    local resultsTexts = getTextValues(resultString)
    
    -- Extract unique texts
    local uniqueTextValues = getTextValuesFromUITables(uniques)
    
    checkFirstNResultsMatchUniqueTexts(resultsTexts, uniqueTextValues, numUnique)
    
    checkUniqueTextsNotInRemainingResults(resultsTexts, uniqueTextValues, numUnique)
    
    checkNoTextsFromDuplicatesOrNotMatchedInResults(resultsTexts, duplicates, notMatched)
    
    print("Passed testStringForButtonTablesTab")
end

-- Check that the first numUnique results match the unique texts
function checkFirstNResultsMatchUniqueTexts(resultsTexts, uniqueTextValues, numUnique)
    for i = 1, numUnique do
        if resultsTexts[i] == nil then
            assert(false, "resultsTexts["..i.."] is nil")
        end
        assert(tableContains(uniqueTextValues, resultsTexts[i]), "Expected to find unique text '"..resultsTexts[i].."' in the first part of results texts")
    end
end

-- Check that the unique texts don't appear in the rest of the results texts
function checkUniqueTextsNotInRemainingResults(resultsTexts, uniqueTextValues, numUnique)
    local restOfResultsTexts = {}
    for i = numUnique + 1, #resultsTexts do
        table.insert(restOfResultsTexts, resultsTexts[i])
    end
    for i, text in ipairs(uniqueTextValues) do
        assert(not tableContains(restOfResultsTexts, text), "Expected not to find unique text '"..text.."' in the rest of results texts")
    end
end

-- Check that no texts from duplicates or notMatched are in resultsTexts
function checkNoTextsFromDuplicatesOrNotMatchedInResults(resultsTexts, duplicates, notMatched)
    local duplicateTexts = getTextValuesFromUITables(duplicates)
    local notMatchedTexts = getTextValuesFromUITables(notMatched)
    
    for i, text in ipairs(duplicateTexts) do
        assert(not tableContains(resultsTexts, text), "Expected not to find duplicate text '"..text.."' in results texts")
    end
    
    for i, text in ipairs(notMatchedTexts) do
        assert(not tableContains(resultsTexts, text), "Expected not to find not matched text '"..text.."' in results texts")
    end
end




function testSaveUniqueButtonTables()

    -- Setup
    local numUnique, numDuplicates, numNotMatched = 3, 2, 2
    local inputUI, testCode = generateTestData(numUnique, numDuplicates, numNotMatched)
    local uniqueUITables = SB.tablesWithUniqueTexts(inputUI)
    local uniqueTextValues = getTextValuesFromUITables(uniqueUITables)

    local matchedTexts, notMatchedTexts = SB.tablesWithTextsFoundAndNot(inputUI, testCode)
    local oldButtonTablesContent = readProjectTab("ButtonTables")

    
    -- Monkey patch allCodeExcludingButtonsAndBackup to include dynamically-generated texts
    local originalAllCodeExcludingButtonsAndBackup = SB.allCodeExcludingButtonsAndBackup
    SB.allCodeExcludingButtonsAndBackup = function()
        return testCode
    end
    
    -- Save uniques
    SB.savePositions()
    
    -- Get the new ButtonTables content
    local newButtonTablesContent = readProjectTab("ButtonTables")
   -- print("newButtonTablesContent: \n" .. newButtonTablesContent)
    
    -- Clean up: restore the old content and undo monkey-patch
    saveProjectTab("ButtonTables", oldButtonTablesContent)
    SB.allCodeExcludingButtonsAndBackup = originalAllCodeExcludingButtonsAndBackup
    
    -- Parse the new ButtonTables content to get the text values
    local foundTexts = getTextValues(newButtonTablesContent)
    print("foundTexts: ")
    for i, text in ipairs(foundTexts) do
        print(i .. ": " .. text)
    end
    

    
    -- Check that the first numUnique found texts match all the unique texts
    for i = 1, numUnique do
        if foundTexts[i] == nil then
            assert(false, "foundTexts["..i.."] is nil")
        end
        assert(tableContains(uniqueTextValues, foundTexts[i]), "Expected to find unique text '"..foundTexts[i].."' in the first part of found texts")
    end
    
    -- Check that the unique texts don't appear in the rest of the found texts
    for i = numUnique + 1, #foundTexts do
        assert(not tableContains(uniqueTexts, foundTexts[i]), "Expected not to find unique text in the rest of found texts")
    end
    
    print("passed testSaveUniqueButtonTables")
end

-- Helper function to check if a table contains a value
function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
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
    local testFunctionCode = "function " .. 
    testFunctionName ..
    "()\n    SB.button({text = [[Test Button]]})\nend"
    
    saveProjectTab(testTabName, testFunctionCode)
    
    local expectedCode = testFunctionCode
    local extractedCode = 
    SB.extractFunctionCode(testTabName,
    testFunctionName)
    
    assert(extractedCode,
    "No function code was extracted")
    assert(extractedCode == expectedCode, 
    "Function code does not match the expected code")
    
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
    
    print("Buttons with no functions: ")
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
    
    local stashedFlagValue = SB.deletableButtonsChecked
    SB.deletableButtonsChecked = true
    
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
    testUI[spacesKey] = spacesTable
    
    local wrongStringTable, wrongStringKey =
    button("Wrong string")
    someOtherFunction("Some other string")
    testUI[wrongStringKey] = wrongStringTable
    
    local invalidTable, invalidKey =
    button(variableInsteadOfLiteral)
    someOtherFunction("Some other string")
    testUI[invalidKey] = invalidTable
    
    -- Button with invalid function
    local invalidFunctionTable, invalidFunctionKey =
    button("Test Invalid Function String")
    someOtherFunction("Some other string")
    
    -- Invalid function: replace the function name with "nonExistentFunction"
    local firstCommaPos = invalidFunctionKey:find(",", 1, true)
    if firstCommaPos then
        local secondCommaPos = invalidFunctionKey:find(",", firstCommaPos + 1, true)
        if secondCommaPos then
            invalidFunctionKey = invalidFunctionKey:sub(1, firstCommaPos) .. "nonExistentFunction" .. invalidFunctionKey:sub(secondCommaPos)
            testUI[invalidFunctionKey] = invalidFunctionTable
        else
            print("No second comma found in invalidFunctionKey: ", invalidFunctionKey)
        end
    else
        print("No first comma found in invalidFunctionKey: ", invalidFunctionKey)
    end
    
    -- Button with invalid tab
    local invalidTabTable, invalidTabKey =
    button("Test Invalid Tab String")
    someOtherFunction("Some other string")
    
    -- Invalid tab: replace the tab name with "InvalidTabName"
    firstCommaPos = invalidTabKey:find(",", 1, true)
    if firstCommaPos then
        invalidTabKey = "InvalidTabName" .. invalidTabKey:sub(firstCommaPos)
        testUI[invalidTabKey] = invalidTabTable
    else
        print("No first comma found in invalidTabKey")
    end
    
    SB.deletableButtonsChecked = stashedFlagValue
    
    return testUI
end

function testHasStringWithAnyDemarcation()
    local testUI = generateTestUI()
    local codeByTab = SB.codeIndexedByTabExcludingButtons()
    local fullCode = ""
    for _, tabCode in pairs(codeByTab) do
        fullCode = fullCode .. " " .. tabCode
    end
    
    for trace, tableValue in pairs(testUI) do
        local stringToFind = tableValue.text
        assert(SB.hasStringWithAnyDemarcation(stringToFind, fullCode, "button(", ")"),
        "String " .. stringToFind .. " not found")
    end
    cleanUpSBUI(testUI)
    print("passed testHasStringWithAnyDemarcation")
end

function testUiWithNonValidTexts()
    local testUI = generateTestUI()
    local codeByTab = SB.codeIndexedByTabExcludingButtons()
    local buttonsWithNoTexts = SB.uiWithNonValidTexts(testUI, codeByTab)
    
    for trace, tableValue in pairs(testUI) do
        local text = tableValue.text
        if text == "buttonMadeWithVarName" then
            assert(buttonsWithNoTexts[trace], "Button with no text not found")
        else
            assert(not buttonsWithNoTexts[trace], "Button with existing text incorrectly marked")
        end
    end
    cleanUpSBUI(testUI)
    print("passed testUiWithNonValidTexts")
end

function cleanUpSBUI(uiData)
    for traceback, _ in pairs(uiData) do
        SB.ui[traceback] = nil
    end
end

function testDeletableButtonTables()
    -- Set up test data
    local testUI = generateTestUI()
    
    -- Call the function to be tested
    local deletableButtonTables = SB.deletableButtonTables()
    
    -- Check that the returned table contains the correct keys
    for traceback, _ in pairs(testUI) do
        if traceback:find("InvalidTabName", 1, true) or traceback:find("nonExistentFunction", 1, true) or traceback:find("variableInsteadOfLiteral", 1, true) then
            assert(deletableButtonTables[traceback], "Button with invalid tab, function, or text not found in deletableButtonTables")
        else
            assert(not deletableButtonTables[traceback], "Button with valid tab, function, and text incorrectly marked as deletable")
        end
    end
    
    cleanUpSBUI(testUI)
    print("passed testDeletableButtonTables")
end

