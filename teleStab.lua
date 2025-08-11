local targetName = "astrocarloss"  -- Replace with the EXACT player name (case-sensitive)

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
    duration = duration or 0.3  -- Increased to 0.3 seconds
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

-- Function to calculate behind position and raycast to ground like click teleport
local function getBehindCFrame()
    local distance = 4  -- Increased studs behind, adjust if needed
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local targetPosition = targetRoot.Position
    
    -- Raycast down from above the behind position to find ground
    local rayOrigin = behindPosition + Vector3.new(0, 50, 0)  -- Start 50 studs above
    local rayDirection = Vector3.new(0, -100, 0)  -- Down 100 studs
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {myChar, targetChar}  -- Ignore self and target
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    
    local landingPosition = behindPosition
    if rayResult then
        landingPosition = rayResult.Position + Vector3.new(0, myChar:GetExtentsSize().Y / 2 + 0.1, 0)  -- Above ground
    else
        print("No ground found behind target; using air position.")
        landingPosition = behindPosition + Vector3.new(0, 3, 0)  -- Fallback to air
    end
    
    return CFrame.lookAt(landingPosition, targetPosition)
end

-- Main sequence wrapped in pcall for error catching
local success, err = pcall(function()
    -- First attack sequence
    print("Starting first teleport and attack")
    local behindCFrame = getBehindCFrame()
    forceTeleport(behindCFrame)
    wait(0.2)  -- Increased sync delay
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
    wait(0.2)
    equippedTool:Activate()  -- Stab again
    print("Second attack activated.")

    -- Optional: Teleport back again
    print("Final teleport back")
    forceTeleport(originalCFrame)
end)

if not success then
    print("Error in script execution: " .. err)
end

