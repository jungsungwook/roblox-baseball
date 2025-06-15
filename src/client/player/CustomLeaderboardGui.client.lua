local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvent 연결
local CustomLeaderboardEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CustomLeaderboardEvent")

-- 리더보드 UI 변수
local leaderboardGui
local isLeaderboardOpen = false
local leaderboardButton
local currentLeaderboardData = {}
local updateLabel -- 갱신 시간 표시용

-- 갱신 시간 관리
local UPDATE_INTERVAL = 300 -- 5분 (300초)
local lastUpdateTime = tick()
local updateConnection

-- Forward declarations
local closeLeaderboard

-- 갱신 시간 업데이트 함수
local function updateTimeDisplay()
    if not updateLabel then return end
    
    local currentTime = tick()
    local timeSinceUpdate = currentTime - lastUpdateTime
    local timeRemaining = UPDATE_INTERVAL - timeSinceUpdate
    
    if timeRemaining <= 0 then
        updateLabel.Text = "갱신 중..."
        lastUpdateTime = currentTime -- 리셋
    else
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        updateLabel.Text = string.format("%d:%02d 남음", minutes, seconds)
    end
end

-- 리더보드 토글 버튼 생성
local function createLeaderboardButton()
    local buttonGui = Instance.new("ScreenGui")
    buttonGui.Name = "CustomLeaderboardButtonGui"
    buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    buttonGui.Parent = playerGui
    
    leaderboardButton = Instance.new("TextButton")
    leaderboardButton.Name = "LeaderboardButton"
    leaderboardButton.Size = UDim2.new(0.08, 0, 0.12, 0)
    leaderboardButton.Position = UDim2.new(0.02, 0, 0.55, 0) -- 가방 버튼 아래
    leaderboardButton.BackgroundColor3 = Color3.new(0.3, 0.2, 0.5)
    leaderboardButton.Text = "순위"
    leaderboardButton.TextColor3 = Color3.new(1, 1, 1)
    leaderboardButton.TextScaled = true
    leaderboardButton.Font = Enum.Font.GothamBold
    leaderboardButton.Parent = buttonGui
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = leaderboardButton
    
    -- 버튼 클릭 이벤트
    leaderboardButton.MouseButton1Click:Connect(function()
        toggleLeaderboard()
    end)
end

-- 리더보드 UI 생성
local function createLeaderboardGui()
    leaderboardGui = Instance.new("ScreenGui")
    leaderboardGui.Name = "CustomLeaderboardGui"
    leaderboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    leaderboardGui.Parent = playerGui
    
    -- 메인 프레임 (화면 왼쪽)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.35, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = leaderboardGui
    
    -- 둥근 모서리
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- 제목 바
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(1, 0, 0.12, 0)
    titleFrame.Position = UDim2.new(0, 0, 0, 0)
    titleFrame.BackgroundColor3 = Color3.new(0.3, 0.2, 0.5)
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleFrame
    
    -- 제목
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.65, 0, 1, 0)
    titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "최장 거리 TOP 10"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleFrame
    
    -- 갱신 표시
    updateLabel = Instance.new("TextLabel")
    updateLabel.Name = "UpdateLabel"
    updateLabel.Size = UDim2.new(0.25, 0, 0.6, 0)
    updateLabel.Position = UDim2.new(0.67, 0, 0.2, 0)
    updateLabel.BackgroundTransparency = 1
    updateLabel.Text = "5:00 남음"
    updateLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    updateLabel.TextScaled = true
    updateLabel.Font = Enum.Font.Gotham
    updateLabel.Parent = titleFrame
    
    -- 닫기 버튼
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.7, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0.15, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- 스크롤 프레임
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "LeaderboardScrollFrame"
    scrollFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    scrollFrame.Position = UDim2.new(0.025, 0, 0.13, 0)
    scrollFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = mainFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 8)
    scrollCorner.Parent = scrollFrame
    
    -- UIListLayout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = scrollFrame
    
    -- 닫기 버튼 이벤트
    closeButton.MouseButton1Click:Connect(function()
        closeLeaderboard()
    end)
    
    -- ESC 키로 닫기
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Escape and isLeaderboardOpen then
            closeLeaderboard()
        end
    end)
    
    return scrollFrame
end

-- 리더보드 항목 생성
local function createLeaderboardEntry(rank, playerData, scrollFrame)
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "Entry" .. rank
    entryFrame.Size = UDim2.new(1, -10, 0, 50)
    entryFrame.LayoutOrder = rank
    entryFrame.Parent = scrollFrame
    
    -- 순위별 색상 설정
    local backgroundColor
    if rank == 1 then
        backgroundColor = Color3.new(1, 0.8, 0) -- 금색
    elseif rank == 2 then
        backgroundColor = Color3.new(0.7, 0.7, 0.7) -- 은색
    elseif rank == 3 then
        backgroundColor = Color3.new(0.8, 0.5, 0.2) -- 동색
    else
        backgroundColor = Color3.new(0.2, 0.2, 0.3) -- 기본색
    end
    entryFrame.BackgroundColor3 = backgroundColor
    entryFrame.BorderSizePixel = 0
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entryFrame
    
    -- 순위 표시
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
    rankLabel.Position = UDim2.new(0, 0, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = tostring(rank)
    rankLabel.TextColor3 = Color3.new(0, 0, 0)
    rankLabel.TextSize = 18 -- 고정 크기로 변경
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.Parent = entryFrame
    
    -- 플레이어 이름
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerData.name
    nameLabel.TextColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = 16 -- 고정 크기로 변경
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd -- 긴 이름 잘림 처리
    nameLabel.Parent = entryFrame
    
    -- 거리 표시
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(0.35, 0, 1, 0)
    distanceLabel.Position = UDim2.new(0.65, 0, 0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = string.format("%.1f 스터드", playerData.distance)
    distanceLabel.TextColor3 = Color3.new(0, 0, 0)
    distanceLabel.TextSize = 14 -- 고정 크기로 변경
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
    distanceLabel.Parent = entryFrame
end

-- 리더보드 데이터 업데이트
local function updateLeaderboardDisplay(scrollFrame)
    -- 기존 항목들 제거
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("Entry") then
            child:Destroy()
        end
    end
    
    -- 데이터가 없을 때
    if #currentLeaderboardData == 0 then
        local noDataLabel = Instance.new("TextLabel")
        noDataLabel.Name = "NoDataLabel"
        noDataLabel.Size = UDim2.new(1, 0, 0, 100)
        noDataLabel.BackgroundTransparency = 1
        noDataLabel.Text = "아직 기록이 없습니다."
        noDataLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
        noDataLabel.TextScaled = true
        noDataLabel.Font = Enum.Font.Gotham
        noDataLabel.Parent = scrollFrame
        return
    end
    
    -- 리더보드 항목 생성
    for rank, playerData in ipairs(currentLeaderboardData) do
        createLeaderboardEntry(rank, playerData, scrollFrame)
    end
    
    -- 스크롤 프레임 크기 조정
    local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if listLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end
end

-- 리더보드 열기
local function openLeaderboard()
    if isLeaderboardOpen then return end
    
    isLeaderboardOpen = true
    local scrollFrame = createLeaderboardGui()
    
    -- 현재 데이터로 리더보드 업데이트
    updateLeaderboardDisplay(scrollFrame)
    
    -- 실시간 갱신 타이머 시작
    if updateConnection then
        updateConnection:Disconnect()
    end
    updateConnection = RunService.Heartbeat:Connect(updateTimeDisplay)
    
    -- 애니메이션 효과
    local mainFrame = leaderboardGui.MainFrame
    mainFrame.Position = UDim2.new(-0.35, 0, 0.15, 0) -- 화면 밖에서 시작
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local slideTween = TweenService:Create(mainFrame, tweenInfo, {
        Position = UDim2.new(0.02, 0, 0.15, 0)
    })
    slideTween:Play()
end

-- 리더보드 닫기
closeLeaderboard = function()
    if not isLeaderboardOpen or not leaderboardGui then return end
    
    -- 실시간 갱신 타이머 중지
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    local mainFrame = leaderboardGui.MainFrame
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local slideTween = TweenService:Create(mainFrame, tweenInfo, {
        Position = UDim2.new(-0.35, 0, 0.15, 0)
    })
    
    slideTween:Play()
    slideTween.Completed:Connect(function()
        if leaderboardGui then
            leaderboardGui:Destroy()
            leaderboardGui = nil
        end
        updateLabel = nil -- 참조 제거
        isLeaderboardOpen = false
    end)
end

-- 리더보드 토글
function toggleLeaderboard()
    if isLeaderboardOpen then
        closeLeaderboard()
    else
        openLeaderboard()
    end
end

-- 서버에서 리더보드 데이터 수신
CustomLeaderboardEvent.OnClientEvent:Connect(function(leaderboardData, serverResetTime)
    currentLeaderboardData = leaderboardData or {}
    
    -- 서버에서 리셋 시간을 받았다면 동기화
    if serverResetTime then
        lastUpdateTime = serverResetTime
    end
    
    print("[커스텀 리더보드] 데이터 수신: " .. #currentLeaderboardData .. "명")
    
    -- 리더보드가 열려있다면 즉시 업데이트
    if isLeaderboardOpen and leaderboardGui then
        local scrollFrame = leaderboardGui.MainFrame:FindFirstChild("LeaderboardScrollFrame")
        if scrollFrame then
            updateLeaderboardDisplay(scrollFrame)
        end
    end
end)

-- 초기화
createLeaderboardButton() 