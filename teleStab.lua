local targetPartialName = "Acrylicmonster"  -- Replace with partial or full player name (case-insensitive)
print("v1")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

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
print
