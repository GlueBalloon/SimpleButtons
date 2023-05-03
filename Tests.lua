function testCreateButtonDataString()
    local traceback = "testTab,testFunction,1"
    local ui = {
        text = "Test Button",
        x = 0.5, y = 0.5,
        width = 100, height = 50,
        action = SB.defaultButtonAction
    }
    
    local expectedString = "SB.ui[ [[" .. traceback .. "]] ] = \n" ..
    "    {text = [[" .. ui.text .. "]],\n" ..
    "    x = " .. ui.x .. ", y = " .. ui.y .. ",\n" ..
    "    width = " .. (ui.width or "nil") .. ", height = " .. (ui.height or "nil") .. ",\n" ..
    "    action = SB.defaultButtonAction\n}\n\n"
    
    local resultString = SB.formatButtonDataString(traceback, ui)
    assert(resultString == expectedString, "Button data string does not match the expected string")
    print("passed testCreateButtonDataString")
end

function testRemoveExistingDeletableSection()
    local deletableComment = "--BUTTONS NOT FOUND IN SOURCE CODE, MAY BE DELETABLE:"
    local buttonTablesTab = "SB.ui[1] = { ... }\n\n" .. deletableComment .. "\nSB.ui[2] = { ... }\n\nSB.ui[3] = { ... }\n\n"
    local expectedTab = "SB.ui[1] = { ... }\n\n"
    
    local resultTab = SB.removeExistingDeletableSection(buttonTablesTab, deletableComment)
    
    assert(resultTab == expectedTab, "Existing deletable section not removed correctly")
    print("passed testRemoveExistingDeletableSection")
end

function testWriteDeletableButtons()
    local deletableButtons = {
        ["nonexistentTab,nonexistentFunc,1"] = {
            text = "*test table* Fake Button 1",
            x = 0.5, y = 0.5,
            width = 100, height = 50,
            action = SB.defaultButtonAction
        },
        ["Main,nonexistentFunc,2"] = {
            text = "*test table* Fake Button 2",
            x = 0.6, y = 0.6,
            width = 100, height = 50,
            action = SB.defaultButtonAction
        }
    }
    
    local resultString = SB.writeDeletableButtons(deletableButtons)
    
    for traceback, _ in pairs(deletableButtons) do
        local pattern = "SB.ui%[%[("..traceback..")%]%]"
        assert(string.find(resultString, pattern), "Deletable button not found in the result string")
    end
    print("passed testWriteDeletableButtons")
end

function testCheckForDeletableButtons()
    local fakeButtonTableTraceback = "nonexistentTab,nonexistentFunc,1"
    local existingTab = "Main" -- Change this to the name of an existing tab in your project if necessary
    local existingFunc = ""
    local tabContent = readProjectTab(existingTab)
    for funcName in string.gmatch(tabContent, "function%s+(%w+)") do
        existingFunc = funcName
        break
    end
    local realButtonTableTraceback = existingTab..","..existingFunc..",3"
    
    assert(SB.checkForDeletableButtons(fakeButtonTableTraceback), "Fake button table not identified as deletable")
    assert(not SB.checkForDeletableButtons(realButtonTableTraceback), "Real button table identified as deletable")
end