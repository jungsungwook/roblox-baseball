local Players = game:GetService("Players")
local MainScreenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainScreenGui")
local MoneyFrame = MainScreenGui:WaitForChild("Frame"):WaitForChild("MoneyFrame")
local PowerStatFrame = MainScreenGui:WaitForChild("Frame"):WaitForChild("PowerStatFrame")

local MainGuiEvent = game.ReplicatedStorage:WaitForChild("Remote"):WaitForChild("MainGuiRemoteEvent")

MainGuiEvent.OnClientEvent:Connect(function(money, power, trainingMultiplier)
    MoneyFrame:WaitForChild("Frame"):WaitForChild("TextLabel").Text = money
    PowerStatFrame:WaitForChild("Frame"):WaitForChild("TextLabel").Text = power
    
    -- TrainingMultiplier UI가 있다면 업데이트 (옵셔널)
    local trainingFrame = MainScreenGui:FindFirstChild("Frame") and MainScreenGui.Frame:FindFirstChild("TrainingMultiplierFrame")
    if trainingFrame then
        trainingFrame:WaitForChild("Frame"):WaitForChild("TextLabel").Text = string.format("%.1fx", trainingMultiplier)
    end
end)