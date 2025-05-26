local Players = game:GetService("Players")
local MainScreenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainScreenGui")
local MoneyFrame = MainScreenGui:WaitForChild("Frame"):WaitForChild("MoneyFrame")
local PowerStatFrame = MainScreenGui:WaitForChild("Frame"):WaitForChild("PowerStatFrame")

local MainGuiEvent = game.ReplicatedStorage:WaitForChild("Remote"):WaitForChild("MainGuiRemoteEvent")

MainGuiEvent.OnClientEvent:Connect(function(money, power)
    MoneyFrame:WaitForChild("Frame"):WaitForChild("TextLabel").Text = money
    PowerStatFrame:WaitForChild("Frame"):WaitForChild("TextLabel").Text = power
end)