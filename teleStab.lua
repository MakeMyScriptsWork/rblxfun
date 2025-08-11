local targetName = "Dometrix0"  -- Replace with the EXACT player name (case-sensitive)local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local targetPlayer = Players:FindFirstChild(targetName)if not targetPlayer or not targetPlayer.Character or not LocalPlayer.Character then
    print("Target player or character not found.")
    return
endlocal function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
endlocal myChar = LocalPlayer.Character
local targetChar = targetPlayer.Character
local myRoot = getRoot(myChar)
local targetRoot = getRoot(targetChar)if not myRoot or not targetRoot then
    print("Root part not found.")
    return
end-- Assume the tool is already equipped
local equippedTool = myChar:FindFirstChildWhichIsA("Tool")
if not equippedTool then
    print("No tool equipped.")
    return
end-- Save original position
local originalCFrame = myRoot.CFrame-- Function to teleport behind target
local function teleportBehind()
    local distance = 3  -- Studs behind, adjust if needed
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * distance
    local targetPosition = targetRoot.Position
    myRoot.CFrame = CFrame.lookAt(behindPosition, targetPosition)
end-- First attack sequence
teleportBehind()
wait(0.1)  -- Small delay for sync
equippedTool:Activate()  -- Stab/attack-- Teleport away (back to original)
myRoot.CFrame = originalCFrame-- Wait half a second
wait(0.5)-- Second attack sequence
teleportBehind()
wait(0.1)
equippedTool:Activate()  -- Stab again-- Optional: Teleport back again
myRoot.CFrame = originalCFrame

