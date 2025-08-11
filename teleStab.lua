local targetPartialName = "F0x"  -- Replace with partial or full player name (case-insensitive)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Function to get players by partial name (similar to Infinite Yield's getPlayer)
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

-- Wait for local character if not loaded
local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
print("Local character loaded.")

-- Find target players
local targetPlayers = getPlayersByName(targetPartialName)
if #targetPlayers == 0 then
    print("No matching target player found.")
    return
end

-- Take the first matching player
local targetPlayer = targetPlayers[1]
print("Target player found: " .. targetPlayer.Name)

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

-- Save original pivot
local originalPivot = myChar:GetPivot()
print("Original position saved.")

-- Function to force pivot by setting repeatedly
local function forcePivot(targetCFrame, duration)
    duration = duration or 0.5  -- 0.5 seconds to override reverts
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        pcall(function()
            myChar:PivotTo(targetCFrame)
            myRoot.Velocity = Vector3.new(0, 0, 0)  -- Reset velocity to prevent flinging
            myRoot.Anchored = false
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

-- Function to calculate behind CFrame with raycast for ground
local function getBehindCFrame()
    local distance = 3  -- Studs behind
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local targetPosition = targetRoot.Position
    
    -- Raycast down to find ground
    local rayOrigin = behindPosition + Vector3.new(0, 50, 0)
    local rayDirection = Vector3.new(0, -100, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {myChar, targetChar}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    
    local landingPosition = behindPosition
    if rayResult then
        landingPosition = rayResult.Position + Vector3.new(0, myChar:GetExtentsSize().Y / 2 + 0.1, 0)
    else
        print("No ground found; using air position.")
        landingPosition = behindPosition + Vector3.new(0, 3, 0)
    end
    
    return CFrame.lookAt(landingPosition, targetPosition)
end

-- Main sequence wrapped in pcall
local success, err = pcall(function()
    -- First attack sequence
    print("Starting first teleport and attack")
    local behindCFrame = getBehindCFrame()
    forcePivot(behindCFrame)
    wait(0.2)
    equippedTool:Activate()
    print("First attack activated.")

    -- Teleport back
    print("Teleporting back")
    forcePivot(originalPivot)

    -- Wait half a second
    wait(0.5)

    -- Second attack sequence
    print("Starting second teleport and attack")
    behindCFrame = getBehindCFrame()  -- Recalculate
    forcePivot(behindCFrame)
    wait(0.2)
    equippedTool:Activate()
    print("Second attack activated.")

    -- Final back
    print("Final teleport back")
    forcePivot(originalPivot)
end)

if not success then
    print("Error in script execution: " .. err)
end

