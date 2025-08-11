print("Script injected successfully!")  -- Debug to confirm injection
print("v1.1")
local targetPartialName = "Acrylicmonster"  -- Replace with partial or full player name (case-insensitive)

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

-- Wait for local character
local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
print("Local character loaded: " .. myChar.Name)

-- Find target players
local targetPlayers = getPlayersByName(targetPartialName)
if #targetPlayers == 0 then
    print("No matching target player found after " .. maxAttempts .. " attempts.")
    return
end

-- Take the first matching player
local targetPlayer = targetPlayers[1]
print("Target player found: " .. targetPlayer.Name .. " (DisplayName: " .. (targetPlayer.DisplayName or "None") .. ")")

-- Wait for target character
local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
print("Target character loaded: " .. targetChar.Name)

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
local targetRoot = getRoot(targetChar)

if not myRoot or not targetRoot then
    print("Root part not found.")
    return
end

-- Check for equipped tool
local equippedTool = myChar:FindFirstChildWhichIsA("Tool")
if not equippedTool then
    print("No tool equipped.")
    return
end
print("Tool found: " .. equippedTool.Name)

-- Save original position
local originalPosition = myRoot.Position
print("Original position saved: " .. tostring(originalPosition))

-- Function to calculate behind CFrame, updated each call
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

-- Attack function, updates target character each time
local function performAttack()
    -- Re-check target character
    targetChar = targetPlayer.Character
    if not targetChar then
        print("Target character not found during attack.")
        return
    end
    targetRoot = getRoot(targetChar)
    if not targetRoot then
        print("Target root not found during attack.")
        return
    end

    local success, err = pcall(function()
        -- First attack sequence
        print("Starting first teleport and attack")
        forceTeleport(targetRoot)
        wait(0.2)
        equippedTool:Activate()
        print("First attack activated.")

        -- Teleport back
        print("Teleporting back")
        local backCFrame = CFrame.new(originalPosition)
        forceTeleport({Position = originalPosition, CFrame = backCFrame}, 0.3)

        -- Wait half a second
        wait(0.5)

        -- Second attack sequence
        print("Starting second teleport and attack")
        forceTeleport(targetRoot)
        wait(0.2)
        equippedTool:Activate()
        print("Second attack activated.")

        -- Final back
        print("Final teleport back")
        forceTeleport({Position = originalPosition, CFrame = backCFrame}, 0.3)
    end)

    if not success then
        print("Error in attack sequence: " .. err)
    end
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game.CoreGui
screenGui.Name = "AttackGui"
screenGui.ResetOnSpawn = false
print("GUI created in " .. screenGui.Parent.Name)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
frame.BorderSizePixel = 2
frame.Active = true  -- Enable dragging
frame.Draggable = true  -- Make GUI movable
frame.Parent = screenGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0.5, 0)
button.Position = UDim2.new(0.1, 0, 0.1, 0)
button.Text = "Execute Attack"
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

-- Resize handle
local resizeButton = Instance.new("TextButton")
resizeButton.Size = UDim2.new(0, 10, 0, 10)
resizeButton.Position = UDim2.new(1, -10, 1, -10)
resizeButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
resizeButton.Text = ""
resizeButton.Parent = frame
print("Resize handle created.")

-- Resize functionality
local dragging = false
local lastMousePos
local lastFrameSize
resizeButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        lastMousePos = input.Position
        lastFrameSize = frame.Size
    end
end)

resizeButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - lastMousePos
        local newSizeX = lastFrameSize.X.Offset + delta.X
        local newSizeY = lastFrameSize.Y.Offset + delta.Y
        frame.Size = UDim2.new(0, math.max(100, newSizeX), 0, math.max(50, newSizeY))
        -- Adjust button sizes to stay proportional
        button.Size = UDim2.new(0.8, 0, 0.5, 0)
        button.Position = UDim2.new(0.1, 0, 0.1, 0)
        closeButton.Position = UDim2.new(1, -25, 0, 5)
        resizeButton.Position = UDim2.new(1, -10, 1, -10)
    end
end))

-- Attack button functionality
table.insert(connections, button.MouseButton1Click:Connect(function()
    print("Attack button clicked!")
    performAttack()
end))

-- Close button functionality
table.insert(connections, closeButton.MouseButton1Click:Connect(function()
    print("Close button clicked! Destroying GUI and cleaning up.")
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    screenGui:Destroy()
    -- Attempt to stop script execution
    if getfenv().script then
        getfenv().script:Destroy()
    end
end))

-- Fallback keybind (press F)
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        print("F key pressed!")
        performAttack()
    end
end))
print("Keybind set for F key.")
