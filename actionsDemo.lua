function actionsDemo()
    background(156, 218, 222)
    button("This button demonstrates button actions (check the output).", function()       
        print("See? I'm an action defined right in the button() call!")
    end)
    button("next", function() currentScreen = attributesDemo end)
end
