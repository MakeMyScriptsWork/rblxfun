local success, errorMsg = pcall(function()
    print("Script injected successfully!")
end)
if not success then
    warn("Initial print failed: " .. tostring(errorMsg))
end

local version = "v1.3 f"

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
                matches[#matches + 1] = player
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

-- Function to get all players for dropdown, sorted alphabetically
local function getPlayerList()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            playerList[#playerList + 1] = player.Name
        end
    end
    table.sort(playerList)  -- Sort alphabetically
    print("Player list sorted: " .. table.concat(playerList, ", "))
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
    print("Target player updated: " .. targetPlayer.Name .. " (DisplayName: " .. (targetPlayer.DisplayName or "None
