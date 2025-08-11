local targetName = "flawed661"  -- Replace with the actual player name
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local targetPlayer = Players:FindFirstChild(targetName)
local myChar = LocalPlayer.Character
local targetChar = targetPlayer.Character
local myHRP = myChar:FindFirstChild("HumanoidRootPart")
local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")-- Assume the tool is already equipped in the character's hand
local equippedTool = myChar:FindFirstChildWhichIsA("Tool")
local originalCFrame = myHRP.CFrame-- Function to teleport behind target
local function teleportBehind()
    local behindOffset = targetHRP.CFrame * CFrame.new(0, 0, 3)  -- 3 studs behind, adjust if needed
    myHRP.CFrame = behindOffset * CFrame.Angles(0, math.pi, 0)  -- Face the target
end-- First attack sequence
teleportBehind()
wait(0.1)  -- Small delay to ensure teleport completes
equippedTool:Activate()  -- Stab/attack-- Teleport away (back to original)
myHRP.CFrame = originalCFrame-- Wait half a second
wait(0.5)-- Second attack sequence
teleportBehind()
wait(0.1)
equippedTool:Activate()  -- Stab again-- Optional: Teleport back again
myHRP.CFrame = originalCFrame







