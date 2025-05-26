local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "BaseBallEnimEvent"
RemoteEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

RemoteEvent.OnServerEvent:Connect(function(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local batClone = ReplicatedStorage:WaitForChild("BaseballBat"):Clone()
    batClone.Parent = character
    character:WaitForChild("Humanoid"):EquipTool(batClone)
end)
