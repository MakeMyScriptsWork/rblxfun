while true do
     for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
         if player ~= game.Players.LocalPlayer and player.Character then
             local root = player.Character:FindFirstChild("HumanoidRootPart")
             if root and root:IsA("BasePart") then
                 root.Size = Vector3.new(15, 15, 15)
                 root.Transparency = 0.4
             end
         end
     end
     wait(5)
 end
