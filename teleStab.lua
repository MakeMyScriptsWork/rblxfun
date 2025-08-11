local targetPartialName = "H0lyDamned"  -- Replace with partial or full player name (case-insensitive)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Function to get players by partial name
local function getPlayersByName(name)
    name = name:lower()
    local matches = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(name, 1, true) or (player.DisplayName and player.DisplayName:lower():find(name, 1, true)) then
            table.insert(matches, player)
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
    print("No matching target player found.")
    return
end

-- Take the first matching player
local targetPlayer = targetPlayers[1]
print("Target player found: " .. targetPlayer.Name)

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

-- Function to force teleport
local function forceTeleport(targetCFrame, duration)
    duration = duration or 0.3  -- Short duration to mimic click teleport
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        pcall(function()
            myRoot.CFrame = targetCFrame
            myRoot.Velocity = Vector3.new(0, 0, 0)
            myRoot.Anchored = false
        end)
        if tick() - startTime >= duration then
            connection:Disconnect()
        end
    end)
    while tick() - startTime < duration do
        RunService.RenderStepped:Wait()
    end
end

-- Function to calculate behind CFrame, updated each call
local function getBehindCFrame(targetRoot)
    local distance = 3  -- Studs behind
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local landingPosition = Vector3.new(behindPosition.X, targetRoot.Position.Y, behindPosition.Z)  -- Match target's Y exactly
    local targetPosition = targetRoot.Position
    print("Teleport target position: " .. tostring(landingPosition))
    return CFrame.lookAt(landingPosition, targetPosition)
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
        local behindCFrame = getBehindCFrame(targetRoot)
        forceTeleport(behindCFrame)
        wait(0.2)
        equippedTool:Activate()
        print("First attack activated.")

        -- Teleport back
        print("Teleporting back")
        forceTeleport(CFrame.new(originalPosition))

        -- Wait half a second
        wait(0.5)

        -- Second attack sequence
        print("Starting second teleport and attack")
        behindCFrame = getBehindCFrame(targetRoot)  -- Recalculate
        forceTeleport(behindCFrame)
        wait(0.2)
        equippedTool:Activate()
        print("Second attack activated.")

        -- Final back
        print("Final teleport back")
        forceTeleport(CFrame.new(originalPosition))
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
frame.Parent = screenGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0.6, 0)
button.Position = UDim2.new(0.1, 0, 0.2, 0)
button.Text = "Execute Attack"
button.TextColor3 = Color3.new(1, 1, 1)
button.BackgroundColor3 = Color3.new(0, 0.5, 0)
button.Parent = frame
print("Button created.")

button.MouseButton1Click:Connect(function()
    print("Button clicked!")
    performAttack()
end)

-- Fallback keybind (press F)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        print("F key pressed!")
        performAttack()
    end
end)
print("Keybind set for F key.")
