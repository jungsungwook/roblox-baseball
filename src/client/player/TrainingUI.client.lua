local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 원격 이벤트 대기
local trainingRemote = ReplicatedStorage:WaitForChild("TrainingRemote")
local startTrainingEvent = trainingRemote:WaitForChild("StartTraining")
local endTrainingEvent = trainingRemote:WaitForChild("EndTraining")
local disableMovementEvent = trainingRemote:WaitForChild("DisableMovement")

-- 움직임 제한 상태
local movementDisabled = false
local connections = {}

-- 훈련 UI
local trainingGui = nil

-- 움직임 제한/해제 함수
local function setMovementEnabled(enabled)
    movementDisabled = not enabled
    
    if enabled then
        -- 움직임 활성화
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        
        -- 이벤트 연결 해제
        for _, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        connections = {}
        
    else
        -- 움직임 비활성화
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        
        -- 키 입력 무시
        connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            -- 움직임 키들 무시
            if input.KeyCode == Enum.KeyCode.W or 
               input.KeyCode == Enum.KeyCode.A or
               input.KeyCode == Enum.KeyCode.S or
               input.KeyCode == Enum.KeyCode.D or
               input.KeyCode == Enum.KeyCode.Space then
                -- 아무것도 하지 않음 (키 입력 무시)
                return
            end
        end)
        
        -- 마우스 움직임도 제한
        connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                -- 마우스 움직임도 어느 정도 제한할 수 있지만, 완전히 막지는 않음
            end
        end)
    end
end

-- 훈련 UI 생성
local function createTrainingUI()
    -- 기존 UI가 있다면 제거
    if trainingGui then
        trainingGui:Destroy()
    end
    
    -- 새 GUI 생성
    trainingGui = Instance.new("ScreenGui")
    trainingGui.Name = "TrainingUI"
    trainingGui.Parent = playerGui
    trainingGui.ResetOnSpawn = false
    
    -- 메인 프레임
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 240, 0, 80)
    mainFrame.Position = UDim2.new(0.5, -120, 1, -100) -- 하단 중앙
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = trainingGui
    
    -- 메인 프레임 모서리
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    -- 제목 라벨
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "훈련 중"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame
    
    -- 나가기 버튼
    local exitButton = Instance.new("TextButton")
    exitButton.Name = "ExitButton"
    exitButton.Size = UDim2.new(0, 80, 0, 30)
    exitButton.Position = UDim2.new(1, -90, 0.5, -15)
    exitButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    exitButton.BorderSizePixel = 0
    exitButton.Text = "나가기"
    exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    exitButton.TextSize = 12
    exitButton.Font = Enum.Font.Gotham
    exitButton.Parent = mainFrame
    
    -- 버튼 모서리
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = exitButton
    
    -- 버튼 호버 효과 (심플한 효과)
    exitButton.MouseEnter:Connect(function()
        local colorTween = TweenService:Create(exitButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        })
        colorTween:Play()
    end)
    
    exitButton.MouseLeave:Connect(function()
        local colorTween = TweenService:Create(exitButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        })
        colorTween:Play()
    end)
    
    -- 버튼 클릭 이벤트
    exitButton.MouseButton1Click:Connect(function()
        -- 서버에 훈련 종료 요청
        endTrainingEvent:FireServer()
    end)
    
    -- UI 등장 애니메이션 (심플한 효과)
    mainFrame.Position = UDim2.new(0.5, -120, 1, 20)
    local showTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -120, 1, -100)
    })
    showTween:Play()
end

-- 훈련 UI 제거
local function removeTrainingUI()
    if trainingGui then
        local mainFrame = trainingGui:FindFirstChild("MainFrame")
        if mainFrame then
            -- UI 사라지는 애니메이션
            local hideTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0.5, -120, 1, 20)
            })
            hideTween:Play()
            
            hideTween.Completed:Connect(function()
                trainingGui:Destroy()
                trainingGui = nil
            end)
        else
            trainingGui:Destroy()
            trainingGui = nil
        end
    end
end

-- 서버 이벤트 연결
startTrainingEvent.OnClientEvent:Connect(function()
    createTrainingUI()
    print("훈련이 시작되었습니다!")
end)

endTrainingEvent.OnClientEvent:Connect(function()
    removeTrainingUI()
    print("훈련이 종료되었습니다!")
end)

disableMovementEvent.OnClientEvent:Connect(function(disable)
    setMovementEnabled(not disable)
    if disable then
        print("움직임이 제한되었습니다.")
    else
        print("움직임 제한이 해제되었습니다.")
    end
end)

-- 플레이어가 리스폰될 때 UI 정리
player.CharacterRemoving:Connect(function()
    if trainingGui then
        trainingGui:Destroy()
        trainingGui = nil
    end
    setMovementEnabled(true)
end) 