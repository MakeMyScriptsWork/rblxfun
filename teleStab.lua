local success, errorMsg = pcall(function()
    print("Script injected successfully!")
end)
if not success then
    warn("Initial print failed: " .. tostring(errorMsg))
end

local version = "v1.1 d"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Table to store connections for cleanup
local connections = {}

-- Function to get players by partial name with retry
local function getPlayersByName(name)
    name = name:lower()
    local matches = {}
    local attempts = 0
    local maxAttempts = 10  -- Retry for 10 seconds
    while #matches == 0 and attempts < maxAttempts do
        print("Attempt " .. (attempts + 1) .. " to find player: " .. name)
        for _, player in ipairs(Players:GetPlayers()) do
            local playerName = player.Name:lower()
            local displayName = player.DisplayName and player.DisplayName:lower() or "None"
            print("Player: Name=" .. player.Name .. ", DisplayName=" .. displayName)
            if playerName:find(name, 1, true) or displayName:find(name, 1, true) then
                table.insert(matches, player)
            end
        end
        if #matches == 0 then
            attempts = attempts + 1
            print("No matches found. Waiting 1 second...")
            wait(1)
        end
    end
    return matches
end

-- Function to get all players for dropdown
local function getPlayerList()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then  -- Exclude local player
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

-- Wait for local character
local success, myChar = pcall(function()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end)
if not success or not myChar then
    print("Failed to load local character: " .. tostring(myChar))
    return
end
print("Local character loaded: " .. myChar.Name)

local function getRoot(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if root then
        root.Anchored = false
        print("Root found for " .. char.Name .. ": " .. root.Name)
    else
        print("No root found for " .. char.Name)
    end
    return root
end

local myRoot = getRoot(myChar)
if not myRoot then
    print("Local player root part not found.")
    return
end

-- Default target player (set via dropdown)
local targetPlayer = nil
local targetChar = nil
local targetRoot = nil

-- Function to update target player
local function updateTargetPlayer(name)
    local targetPlayers = getPlayersByName(name)
    if #targetPlayers == 0 then
        print("No matching target player found for: " .. name)
        return false
    end
    targetPlayer = targetPlayers[1]
    print("Target player updated: " .. targetPlayer.Name .. " (DisplayName: " .. (targetPlayer.DisplayName or "None") .. ")")
    local success, char = pcall(function()
        return targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
    end)
    if not success or not char then
        print("Failed to load target character: " .. tostring(char))
        return false
    end
    targetChar = char
    print("Target character loaded: " .. targetChar.Name)
    targetRoot = getRoot(targetChar)
    return targetRoot ~= nil
end

-- Save original position (default return point)
local returnPosition = myRoot.Position
print("Default return position saved: " .. tostring(returnPosition))

-- Function to calculate behind CFrame
local function getBehindCFrame(targetRoot)
    local distance = 3  -- Studs behind
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local landingPosition = Vector3.new(behindPosition.X, targetRoot.Position.Y, behindPosition.Z)  -- Match target's Y
    local targetPosition = targetRoot.Position
    print("Teleport target position: " .. tostring(landingPosition))
    return CFrame.lookAt(landingPosition, targetPosition)
end

-- Function to force teleport with rapid updates
local function forceTeleport(targetRoot, duration)
    duration = duration or 0.5  -- Duration for each teleport phase
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        pcall(function()
            local targetCFrame = getBehindCFrame(targetRoot)  -- Recalculate every frame (~10ms at 60 FPS)
            myRoot.CFrame = targetCFrame
            myRoot.Velocity = Vector3.new(0, 0, 0)
            myRoot.Anchored = false
        end)
        if tick() - startTime >= duration then
            connection:Disconnect()
        end
    end)
    table.insert(connections, connection)
    while tick() - startTime < duration do
        RunService.RenderStepped:Wait()
    end
end

-- Attack function
local function performAttack(dropdown)
    if not targetPlayer or not targetChar then
        print("No target player selected. Select a player from the dropdown.")
        return
    end
    -- Re-check target character
    targetChar = targetPlayer.Character
    if not targetChar then
        print("Target character not found during attack.")
        updateDropdown(dropdown)
        return
    end
    targetRoot = getRoot(targetChar)
    if not targetRoot then
        print("Target root not found during attack.")
        return
    end
    -- Check for equipped tool during attack
    local equippedTool = myChar:FindFirstChildWhichIsA("Tool")
    if not equippedTool then
        print("No tool equipped. Please equip a tool to attack.")
        return
    end

    local success, err = pcall(function()
        -- First attack sequence
        print("Starting first teleport and attack")
        equippedTool:Activate()
        forceTeleport(targetRoot)
        print("First attack activated.")

        -- Teleport back
        print("Teleporting back")
        local backCFrame = CFrame.new(returnPosition)
        forceTeleport({Position = returnPosition, CFrame = backCFrame}, 0.3)

        -- Wait half a second
        wait(0.5)

        -- Second attack sequence
        print("Starting second teleport and attack")
        equippedTool:Activate()
        forceTeleport(targetRoot)
        print("Second attack activated.")

        -- Final back
        print("Final teleport back")
        forceTeleport({Position = returnPosition, CFrame = backCFrame}, 0.3)
    end)

    if not success then
        print("Error in attack sequence: " .. err)
    end

    -- Check if target still exists after attack
    if not Players:FindFirstChild(targetPlayer.Name) then
        print("Target player left. Refreshing dropdown.")
        updateDropdown(dropdown)
    end
end

-- Create GUI
local success, guiError = pcall(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game.CoreGui
    screenGui.Name = "AttackGui"
    screenGui.ResetOnSpawn = false
    print("GUI created in " .. screenGui.Parent.Name)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 150)  -- Smaller size
    frame.Position = UDim2.new(0.1, 0, 0.5, -75)  -- Further left
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    frame.BorderSizePixel = 2
    frame.Active = true  -- Enable dragging
    frame.Draggable = true  -- Make GUI movable
    frame.Parent = screenGui

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0.2, 0)
    button.Position = UDim2.new(0.1, 0, 0.45, 0)
    button.Text = "Execute Attack " .. version
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = Color3.new(0, 0.5, 0)
    button.Parent = frame
    print("Attack button created.")

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.BackgroundColor3 = Color3.new(1, 0, 0)
    closeButton.Parent = frame
    print("Close button created.")

    local setReturnButton = Instance.new("TextButton")
    setReturnButton.Size = UDim2.new(0, 20, 0, 20)
    setReturnButton.Position = UDim2.new(1, -50, 0, 5)
    setReturnButton.Text = "R"
    setReturnButton.TextColor3 = Color3.new(1, 1, 1)
    setReturnButton.BackgroundColor3 = Color3.new(0, 0, 1)
    setReturnButton.Parent = frame
    print("Return point button created.")

    -- Create dropdown
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(0.8, 0, 0.2, 0)
    dropdownButton.Position = UDim2.new(0.1, 0, 0.15, 0)
    dropdownButton.Text = "Select a player"
    dropdownButton.TextColor3 = Color3.new(1, 1, 1)
    dropdownButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    dropdownButton.Parent = frame
    print("Dropdown button created.")

    local dropdownFrame = Instance.new("ScrollingFrame")
    dropdownFrame.Size = UDim2.new(0.8, 0, 0.4, 0)
    dropdownFrame.Position = UDim2.new(0.1, 0, 0.35, 0)
    dropdownFrame.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    dropdownFrame.Visible = false
    dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropdownFrame.ScrollBarThickness = 4
    dropdownFrame.Parent = frame
    print("Dropdown frame created.")

    local selectButton = Instance.new("TextButton")
    selectButton.Size = UDim2.new(0.8, 0, 0.2, 0)
    selectButton.Position = UDim2.new(0.1, 0, 0.75, 0)
    selectButton.Text = "Select Player"
    selectButton.TextColor3 = Color3.new(1, 1, 1)
    selectButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0)
    selectButton.Parent = frame
    print("Select player button created.")

    -- Dropdown functionality
    local function toggleDropdown()
        dropdownFrame.Visible = not dropdownFrame.Visible
        print("Dropdown toggled: " .. tostring(dropdownFrame.Visible))
    end

    local function clearDropdown()
        for _, child in ipairs(dropdownFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        print("Dropdown cleared.")
    end

    local function updateDropdown()
        clearDropdown()
        local playerList = getPlayerList()
        local yOffset = 0
        for i, name in ipairs(playerList) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, -4, 0, 20)
            option.Position = UDim2.new(0, 2, 0, yOffset)
            option.Text = name
            option.TextColor3 = Color3.new(1, 1, 1)
            option.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
            option.Parent = dropdownFrame
            table.insert(connections, option.MouseButton1Click:Connect(function()
                dropdownButton.Text = name
                dropdownFrame.Visible = false
                print("Selected player from dropdown: " .. name)
                updateTargetPlayer(name)
            end))
            yOffset = yOffset + 22
        end
        dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
        print("Dropdown updated with " .. #playerList .. " players.")
    end

    -- Initial dropdown population
    updateDropdown()

    -- Periodic dropdown refresh (every 30 seconds)
    table.insert(connections, spawn(function()
        while screenGui.Parent do
            wait(30)
            print("Refreshing dropdown...")
            updateDropdown()
        end
    end))

    -- Button connections
    table.insert(connections, button.MouseButton1Click:Connect(function()
        print("Attack button clicked!")
        performAttack(dropdownFrame)
    end))

    table.insert(connections, selectButton.MouseButton1Click:Connect(function()
        print("Select player button clicked! Attempting to set target: " .. dropdownButton.Text)
        updateTargetPlayer(dropdownButton.Text)
    end))

    table.insert(connections, dropdownButton.MouseButton1Click:Connect(function()
        print("Dropdown button clicked!")
        toggleDropdown()
    end))

    table.insert(connections, setReturnButton.MouseButton1Click:Connect(function()
        returnPosition = myRoot.Position
        print("Return position updated: " .. tostring(returnPosition))
    end))

    table.insert(connections, closeButton.MouseButton1Click:Connect(function()
        print("Close button clicked! Destroying GUI and cleaning up.")
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        connections = {}
        screenGui:Destroy()
        if getfenv().script then
            getfenv().script:Destroy()
        end
    end))

    -- Fallback keybind (press F)
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F then
            print("F key pressed!")
            performAttack(dropdownFrame)
        end
    end))

    return screenGui
end)

if not success then
    warn("GUI creation failed: " .. tostring(guiError))
    return
end

local screenGui = success -- Assign the returned screenGui
print("Keybind set for F key.")
