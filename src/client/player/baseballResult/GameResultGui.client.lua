local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvent 연결
local gameResultEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("GameResultEvent")

-- GUI 생성 함수
local function createGameResultGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameResultGui"
    screenGui.Parent = playerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 15 -- 로딩 화면(DisplayOrder 10)보다 높게 설정
    
    -- 배경 어둡게 하기
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- 메인 결과 창
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0, 400, 0, 300)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    resultFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    resultFrame.BorderSizePixel = 0
    resultFrame.Parent = screenGui
    
    -- 모서리 둥글게
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = resultFrame
    
    -- 제목
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "게임 결과"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = resultFrame
    
    -- 등급 표시
    local gradeLabel = Instance.new("TextLabel")
    gradeLabel.Name = "GradeLabel"
    gradeLabel.Size = UDim2.new(1, -40, 0, 40)
    gradeLabel.Position = UDim2.new(0, 20, 0, 60)
    gradeLabel.BackgroundTransparency = 1
    gradeLabel.Text = "등급"
    gradeLabel.TextColor3 = Color3.new(1, 1, 1)
    gradeLabel.TextScaled = true
    gradeLabel.Font = Enum.Font.GothamBold
    gradeLabel.Parent = resultFrame
    
    -- 거리 표시
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, -40, 0, 30)
    distanceLabel.Position = UDim2.new(0, 20, 0, 110)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "거리: 0 스터드"
    distanceLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = resultFrame
    
    -- 보상 표시
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Name = "RewardLabel"
    rewardLabel.Size = UDim2.new(1, -40, 0, 30)
    rewardLabel.Position = UDim2.new(0, 20, 0, 150)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "보상: 0 골드"
    rewardLabel.TextColor3 = Color3.new(1, 1, 0)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.Parent = resultFrame
    
    -- 메시지 표시
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -40, 0, 50)
    messageLabel.Position = UDim2.new(0, 20, 0, 190)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = ""
    messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.Parent = resultFrame
    
    -- 닫기 버튼
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 100, 0, 35)
    closeButton.Position = UDim2.new(0.5, -50, 1, -50)
    closeButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    closeButton.Text = "확인"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = resultFrame
    
    -- 닫기 버튼 모서리 둥글게
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    return screenGui, resultFrame, gradeLabel, distanceLabel, rewardLabel, messageLabel, closeButton
end

-- 결과 표시 함수
local function showGameResult(resultData)
    -- 기존 GUI 제거
    local existingGui = playerGui:FindFirstChild("GameResultGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui, resultFrame, gradeLabel, distanceLabel, rewardLabel, messageLabel, closeButton = createGameResultGui()
    
    -- 데이터 설정
    gradeLabel.Text = resultData.grade
    gradeLabel.TextColor3 = resultData.gradeColor
    distanceLabel.Text = string.format("거리: %.1f 스터드", resultData.distance)
    rewardLabel.Text = string.format("보상: %d 골드", resultData.moneyReward)
    messageLabel.Text = resultData.message
    
    -- 애니메이션 효과
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local sizeTween = TweenService:Create(resultFrame, tweenInfo, {
        Size = UDim2.new(0, 400, 0, 300)
    })
    sizeTween:Play()
    
    -- 닫기 버튼 이벤트
    closeButton.MouseButton1Click:Connect(function()
        local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(screenGui, fadeInfo, {
            Enabled = false
        })
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
    
    -- ESC 키로 닫기
    local escConnection
    escConnection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Escape then
            escConnection:Disconnect()
            closeButton.MouseButton1Click:Fire()
        end
    end)
end

-- 서버에서 결과 받기
gameResultEvent.OnClientEvent:Connect(function(resultData)
    showGameResult(resultData)
end) 