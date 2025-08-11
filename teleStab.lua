local targetName = "BudgetLord"  -- Replace with the EXACT player name (case-sensitive)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local targetPlayer = Players:FindFirstChild(targetName)

if not targetPlayer or not targetPlayer.Character or not LocalPlayer.Character then
    print("Target player or character not found.")
    return
end

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local myChar = LocalPlayer.Character
local targetChar = targetPlayer.Character
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

-- Save original position
local originalCFrame = myRoot.CFrame

-- Function to force teleport by setting CFrame repeatedly to override potential server reverts
local function forceTeleport(targetCFrame, duration)
    duration = duration or 0.1  -- Default 0.1 seconds
    local startTime = tick()
    local connection = RunService.Heartbeat:Connect(function()
        myRoot.CFrame = targetCFrame
        if tick() - startTime >= duration then
            connection:Disconnect()
        end
    end)
    -- Wait for the duration
    while tick() - startTime < duration do
        RunService.Heartbeat:Wait()
    end
end

-- Function to calculate behind CFrame
local function getBehindCFrame()
    local distance = 3  -- Studs behind, adjust if needed
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local targetPosition = targetRoot.Position
    return CFrame.lookAt(behindPosition, targetPosition)
end

-- First attack sequence
print("Starting first teleport and attack")
local behindCFrame = getBehindCFrame()
forceTeleport(behindCFrame)
wait(0.1)  -- Extra sync delay
equippedTool:Activate()  -- Stab/attack

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

-- Optional: Teleport back again
print("Final teleport back")
forceTeleport(originalCFrame)
