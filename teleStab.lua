local targetName = "BudgetLord"  -- Replace with the EXACT player name (case-sensitive)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Wait for local character if not loaded
local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
print("Local character loaded.")

-- Find target player
local targetPlayer = Players:FindFirstChild(targetName)
if not targetPlayer then
    print("Target player not found.")
    return
end

-- Wait for target character if not loaded
local targetChar = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
print("Target character loaded.")

local function getRoot(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if root then
        root.Anchored = false  -- Ensure not anchored
    end
    return root
end

local myRoot = getRoot(myChar)
local targetRoot = getRoot(targetChar)

if not myRoot or not targetRoot then
    print("Root part not found.")
    return
end

-- Assume the tool is already equipped
local equippedTool = myChar:FindFirstChildWhichIsA("Tool")
if not equippedTool then
    print("No tool equipped.")
    return
end
print("Tool found: " .. equippedTool.Name)

-- Save original position
local originalCFrame = myRoot.CFrame
print("Original position saved.")

-- Function to force teleport by setting CFrame repeatedly using RenderStepped
local function forceTeleport(targetCFrame, duration)
    duration = duration or 0.2  -- Increased to 0.2 seconds
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        pcall(function()
            myRoot.Anchored = false
            myRoot.CFrame = targetCFrame
        end)
        if tick() - startTime >= duration then
            connection:Disconnect()
        end
    end)
    -- Wait for the duration
    while tick() - startTime < duration do
        RunService.RenderStepped:Wait()
    end
end

-- Function to calculate behind CFrame
local function getBehindCFrame()
    local distance = 3  -- Studs behind, adjust if needed
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local targetPosition = targetRoot.Position
    return CFrame.lookAt(behindPosition, targetPosition)
end

-- Main sequence wrapped in pcall for error catching
local success, err = pcall(function()
    -- First attack sequence
    print("Starting first teleport and attack")
    local behindCFrame = getBehindCFrame()
    forceTeleport(behindCFrame)
    wait(0.1)  -- Extra sync delay
    equippedTool:Activate()  -- Stab/attack
    print("First attack activated.")

    -- Teleport away (back to original)
    print("Teleporting back")
    forceTeleport(originalCFrame)

    -- Wait half a second
    wait(0.5)

    -- Second attack sequence
    print("Starting second teleport and attack")
    behindCFrame = getBehindCFrame()  -- Recalculate in case target moved
    forceTeleport(behindCFrame)
    wait(0.1)
    equippedTool:Activate()  -- Stab again
    print("Second attack activated.")

    -- Optional: Teleport back again
    print("Final teleport back")
    forceTeleport(originalCFrame)
end)

if not success then
    print("Error in script execution: " .. err)
end
