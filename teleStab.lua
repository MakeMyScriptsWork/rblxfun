local targetName = "flawed661"  -- Replace with the actual player name
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
TextChatService.TextChannels.RBXSystem:DisplaySystemMessage("Test")
local LocalPlayer = Players.LocalPlayer
local targetPlayer = Players:FindFirstChild(targetName)if not targetPlayer or not targetPlayer.Character or not LocalPlayer.Character then
    TextChatService.TextChannels.RBXSystem:DisplaySystemMessage("Target player or character not found.")
    return
end
    local myChar = LocalPlayer.Character
local targetChar = targetPlayer.Character
local myHRP = myChar:FindFirstChild("HumanoidRootPart")
local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")if not myHRP or not targetHRP then
    print("HumanoidRootPart not found.")
    TextChatService.TextChannels.RBXSystem:DisplaySystemMessage("HumanoidRootPart not found.")
    return
end-- Assume the tool is already equipped in the character's hand
local equippedTool = myChar:FindFirstChildWhichIsA("Tool")
if not equippedTool then
    TextChatService.TextChannels.RBXSystem:DisplaySystemMessage("No tool equipped.")
    return
end-- Save original position
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






