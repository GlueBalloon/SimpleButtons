
function testFindDeletableButtons()
    local originalUI = SB.ui
    
    -- Backup ButtonTables tab content
    local buttonTablesBackup = readProjectTab("ButtonTables")
    saveProjectTab("TestButtonTablesBackup", buttonTablesBackup)
    
    -- Find an existing tab and an existing function within that tab
    local existingTab = "Main" -- Change this to the name of an existing tab in your project if necessary
    local existingFunc = ""
    local tabContent = readProjectTab(existingTab)
    for funcName in string.gmatch(tabContent, "function%s+(%w+)") do
        existingFunc = funcName
        break
    end
    assert(existingFunc ~= "", "No function found in the existing tab")
    
    -- Create fake button tables
    local fakeButtonTables = {
        ["nonexistentTab,nonexistentFunc,1"] = {
            text = "*test table* Fake Button 1",
            x = 0.5, y = 0.5,
            width = 100, height = 50,
            action = SB.defaultButtonAction
        },
        [existingTab..",nonexistentFunc,2"] = {
            text = "*test table* Fake Button 2",
            x = 0.6, y = 0.6,
            width = 100, height = 50,
            action = SB.defaultButtonAction
        },
        [existingTab..","..existingFunc..",3"] = {
            text = "*test table* Nonexistent Text",
            x = 0.7, y = 0.7,
            width = 100, height = 50,
            action = SB.defaultButtonAction
        }
    }
    
    -- Find a real button table that's not deletable
    local realButtonTable = nil
    for traceback, ui in pairs(originalUI) do
        if not SB.checkForDeletableButtons(traceback) then
            realButtonTable = {traceback = traceback, ui = ui}
            break
        end
    end
    assert(realButtonTable ~= nil, "No real button table found")
    
    -- Replace SB.ui with fake button tables and the real button table
    SB.ui = fakeButtonTables
    SB.ui[realButtonTable.traceback] = realButtonTable.ui
    
    -- Call savePositions()
    SB.savePositions()
    
    -- Read the updated ButtonTables tab
    local buttonTablesContent = readProjectTab("ButtonTables")
    
    -- Check if the fake button tables are placed under the "deletable" section
    for traceback, _ in pairs(fakeButtonTables) do
        local pattern = "%-%- BUTTONS NOT FOUND IN SOURCE CODE, MAY BE DELETABLE:%s-[\n]+.*SB.ui%[%[("..traceback..")%]%]"
        assert(string.find(buttonTablesContent, pattern), "Fake button table not found in the deletable section")
    end
    
    -- Check if the real button table is NOT placed under the "deletable" section
    local realButtonTablePattern = "%-%- BUTTONS NOT FOUND IN SOURCE CODE, MAY BE DELETABLE:%s*SB.ui%[%[("..realButtonTable.traceback..")%]%]"
    assert(not string.find(buttonTablesContent, realButtonTablePattern), "Real button table found in the deletable section")
    
    -- Restore the original SB.ui
    SB.ui = originalUI
    
    -- Restore ButtonTables tab from backup and save it
    local buttonTablesBackupContent = readProjectTab("TestButtonTablesBackup")
    saveProjectTab("ButtonTables", buttonTablesBackupContent)
    
    -- Inform the user that the test has completed
    print("Test completed")
end

