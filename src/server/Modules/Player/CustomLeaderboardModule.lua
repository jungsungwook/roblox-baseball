local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataModule = require(script.Parent.PlayerDataModule)
local CustomLeaderboardModule = {}

-- DataStore 설정
local leaderboardDataStore = DataStoreService:GetDataStore("GlobalLeaderboard")
local LEADERBOARD_KEY = "TopDistances"

-- TOP10 리더보드 데이터
CustomLeaderboardModule.TopPlayers = {}
local UPDATE_INTERVAL = 300 -- 5분 (300초)
local lastResetTime = tick() -- 마지막 리셋 시간

-- 전광판 스크린 참조
local leaderboardScreens = {}

-- RemoteEvent 생성/연결
local function setupRemoteEvents()
    local remoteFolder = ReplicatedStorage:WaitForChild("Remote")
    
    local customLeaderboardEvent = remoteFolder:FindFirstChild("CustomLeaderboardEvent")
    if not customLeaderboardEvent then
        customLeaderboardEvent = Instance.new("RemoteEvent")
        customLeaderboardEvent.Name = "CustomLeaderboardEvent"
        customLeaderboardEvent.Parent = remoteFolder
    end
    
    return customLeaderboardEvent
end

local customLeaderboardEvent = setupRemoteEvents()

-- 전광판 스크린 찾기 및 설정
local function setupLeaderboardScreens()
    local leaderboardFolder = workspace:FindFirstChild("LeaderBoard")
    if not leaderboardFolder then
        warn("[전광판] LeaderBoard 폴더를 찾을 수 없습니다.")
        return
    end
    
    -- Model_1과 Model_2에서 Screen 파트 찾기
    for _, model in pairs(leaderboardFolder:GetChildren()) do
        if model:IsA("Model") and (model.Name == "Model_1" or model.Name == "Model_2") then
            local screen = model:FindFirstChild("Screen")
            if screen and screen:IsA("BasePart") then
                table.insert(leaderboardScreens, screen)
                print(string.format("[전광판] %s의 Screen 파트 발견: %s", model.Name, screen.Name))
            end
        end
    end
    
    print(string.format("[전광판] 총 %d개의 스크린 발견", #leaderboardScreens))
end

-- 전광판에 리더보드 UI 생성
local function createScreenLeaderboard(screen)
    -- 기존 SurfaceGui 제거
    local existingGuiFront = screen:FindFirstChild("LeaderboardGuiFront")
    local existingGuiBack = screen:FindFirstChild("LeaderboardGuiBack")
    if existingGuiFront then existingGuiFront:Destroy() end
    if existingGuiBack then existingGuiBack:Destroy() end
    
    -- 앞면 SurfaceGui 생성
    local surfaceGuiFront = Instance.new("SurfaceGui")
    surfaceGuiFront.Name = "LeaderboardGuiFront"
    surfaceGuiFront.Face = Enum.NormalId.Front
    surfaceGuiFront.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGuiFront.PixelsPerStud = 10
    surfaceGuiFront.Parent = screen
    
    -- 뒷면 SurfaceGui 생성
    local surfaceGuiBack = Instance.new("SurfaceGui")
    surfaceGuiBack.Name = "LeaderboardGuiBack"
    surfaceGuiBack.Face = Enum.NormalId.Back
    surfaceGuiBack.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGuiBack.PixelsPerStud = 10
    surfaceGuiBack.Parent = screen
    
    -- 앞면과 뒷면에 동일한 UI 생성
    local function createLeaderboardUI(surfaceGui)
        -- 배경 프레임
        local backgroundFrame = Instance.new("Frame")
        backgroundFrame.Name = "Background"
        backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
        backgroundFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.15)
        backgroundFrame.BorderSizePixel = 0
        backgroundFrame.Parent = surfaceGui
        
        -- 제목
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundColor3 = Color3.new(0.1, 0.3, 0.6)
        titleLabel.BorderSizePixel = 0
        titleLabel.Text = "🏆 TOP 3 최장 거리 🏆"
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.TextSize = 500
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = backgroundFrame
        
        -- 갱신 시간 표시
        local updateLabel = Instance.new("TextLabel")
        updateLabel.Name = "UpdateTime"
        updateLabel.Size = UDim2.new(1, 0, 0.08, 0)
        updateLabel.Position = UDim2.new(0, 0, 0.15, 0)
        updateLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
        updateLabel.BorderSizePixel = 0
        updateLabel.Text = "다음 갱신: 5:00"
        updateLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        updateLabel.TextSize = 350
        updateLabel.Font = Enum.Font.Gotham
        updateLabel.Parent = backgroundFrame
        
        -- TOP 3 컨테이너
        local top3Container = Instance.new("Frame")
        top3Container.Name = "Top3Container"
        top3Container.Size = UDim2.new(1, 0, 0.77, 0)
        top3Container.Position = UDim2.new(0, 0, 0.23, 0)
        top3Container.BackgroundTransparency = 1
        top3Container.Parent = backgroundFrame
        
        return top3Container, updateLabel
    end
    
    local frontContainer, frontUpdateLabel = createLeaderboardUI(surfaceGuiFront)
    local backContainer, backUpdateLabel = createLeaderboardUI(surfaceGuiBack)
    
    return {
        front = {gui = surfaceGuiFront, container = frontContainer, update = frontUpdateLabel},
        back = {gui = surfaceGuiBack, container = backContainer, update = backUpdateLabel}
    }
end

-- 전광판 TOP3 플레이어 카드 생성
local function createPlayerCard(rank, playerData, container)
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "PlayerCard" .. rank
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = container
    
    -- 순위별 위치와 크기 설정
    if rank == 1 then
        -- 1등: 가운데, 가장 크게
        cardFrame.Size = UDim2.new(0.35, 0, 0.9, 0)
        cardFrame.Position = UDim2.new(0.325, 0, 0.05, 0)
        cardFrame.BackgroundColor3 = Color3.new(1, 0.8, 0) -- 금색
    elseif rank == 2 then
        -- 2등: 왼쪽
        cardFrame.Size = UDim2.new(0.28, 0, 0.75, 0)
        cardFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
        cardFrame.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8) -- 은색
    elseif rank == 3 then
        -- 3등: 오른쪽
        cardFrame.Size = UDim2.new(0.28, 0, 0.75, 0)
        cardFrame.Position = UDim2.new(0.7, 0, 0.15, 0)
        cardFrame.BackgroundColor3 = Color3.new(0.8, 0.5, 0.2) -- 동색
    end
    
    -- 모서리 둥글게
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = cardFrame
    
    -- 순위 표시
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "Rank"
    rankLabel.Size = UDim2.new(1, 0, 0.2, 0)
    rankLabel.Position = UDim2.new(0, 0, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rank == 1 and "🥇" or (rank == 2 and "🥈" or "🥉")
    rankLabel.TextColor3 = Color3.new(0, 0, 0)
    rankLabel.TextSize = rank == 1 and 600 or 450
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.Parent = cardFrame
    
    -- 프로필 이미지
    local profileFrame = Instance.new("Frame")
    profileFrame.Name = "ProfileFrame"
    profileFrame.Size = UDim2.new(0.8, 0, 0.4, 0)
    profileFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
    profileFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    profileFrame.BorderSizePixel = 0
    profileFrame.Parent = cardFrame
    
    -- 프로필 이미지 둥글게
    local profileCorner = Instance.new("UICorner")
    profileCorner.CornerRadius = UDim.new(0.5, 0) -- 원형
    profileCorner.Parent = profileFrame
    
    -- 실제 프로필 이미지
    local profileImage = Instance.new("ImageLabel")
    profileImage.Name = "ProfileImage"
    profileImage.Size = UDim2.new(1, 0, 1, 0)
    profileImage.Position = UDim2.new(0, 0, 0, 0)
    profileImage.BackgroundTransparency = 1
    profileImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. (playerData.userId or 1) .. "&width=150&height=150&format=png"
    profileImage.Parent = profileFrame
    
    -- 프로필 이미지도 둥글게
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0.5, 0)
    imageCorner.Parent = profileImage
    
    -- 플레이어 이름
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(1, 0, 0.15, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.65, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerData.name
    nameLabel.TextColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = rank == 1 and 400 or 300 
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = cardFrame
    
    -- 거리 표시
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1, 0, 0.15, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.82, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = string.format("%.0f 스터드", playerData.distance)
    distanceLabel.TextColor3 = Color3.new(0, 0, 0)
    distanceLabel.TextSize = rank == 1 and 450 or 350
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.Parent = cardFrame
end

-- 전광판 리더보드 업데이트
local function updateScreenLeaderboards()
    for _, screen in pairs(leaderboardScreens) do
        local frontGui = screen:FindFirstChild("LeaderboardGuiFront")
        local backGui = screen:FindFirstChild("LeaderboardGuiBack")
        
        -- GUI가 없으면 생성
        if not frontGui or not backGui then
            createScreenLeaderboard(screen)
            frontGui = screen:FindFirstChild("LeaderboardGuiFront")
            backGui = screen:FindFirstChild("LeaderboardGuiBack")
        end
        
        -- 앞면과 뒷면 모두 업데이트
        local function updateSide(gui, sideName)
            if not gui then return end
            
            local container = gui:FindFirstChild("Background"):FindFirstChild("Top3Container")
            local updateLabel = gui:FindFirstChild("Background"):FindFirstChild("UpdateTime")
            
            if container and updateLabel then
                -- 기존 모든 자식 요소 제거 (플레이어 카드 + NoData 라벨)
                for _, child in pairs(container:GetChildren()) do
                    if child:IsA("Frame") and child.Name:match("PlayerCard") then
                        child:Destroy()
                    elseif child:IsA("TextLabel") and child.Name == "NoData" then
                        child:Destroy()
                    end
                end
                
                -- 갱신 시간 업데이트
                local currentTime = tick()
                local timeRemaining = UPDATE_INTERVAL - (currentTime - lastResetTime)
                if timeRemaining <= 0 then
                    updateLabel.Text = "갱신 중..."
                else
                    local minutes = math.floor(timeRemaining / 60)
                    local seconds = math.floor(timeRemaining % 60)
                    updateLabel.Text = string.format("다음 갱신: %d:%02d", minutes, seconds)
                end
                
                -- TOP3 데이터가 없을 때
                if #CustomLeaderboardModule.TopPlayers == 0 then
                    local noDataLabel = Instance.new("TextLabel")
                    noDataLabel.Name = "NoData"
                    noDataLabel.Size = UDim2.new(1, 0, 1, 0)
                    noDataLabel.Position = UDim2.new(0, 0, 0, 0)
                    noDataLabel.BackgroundTransparency = 1
                    noDataLabel.Text = "아직 기록이 없습니다."
                    noDataLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
                    noDataLabel.TextSize = 500
                    noDataLabel.Font = Enum.Font.GothamBold
                    noDataLabel.Parent = container
                else
                    -- TOP3 플레이어 카드 생성 (최대 3명)
                    for rank = 1, math.min(3, #CustomLeaderboardModule.TopPlayers) do
                        local playerData = CustomLeaderboardModule.TopPlayers[rank]
                        createPlayerCard(rank, playerData, container)
                    end
                end
            end
        end
        
        updateSide(frontGui, "앞면")
        updateSide(backGui, "뒷면")
    end
end

-- 전광판 실시간 타이머 업데이트
local function updateScreenTimers()
    for _, screen in pairs(leaderboardScreens) do
        local frontGui = screen:FindFirstChild("LeaderboardGuiFront")
        local backGui = screen:FindFirstChild("LeaderboardGuiBack")
        
        local function updateTimerSide(gui)
            if gui then
                local updateLabel = gui:FindFirstChild("Background"):FindFirstChild("UpdateTime")
                if updateLabel then
                    local currentTime = tick()
                    local timeRemaining = UPDATE_INTERVAL - (currentTime - lastResetTime)
                    
                    if timeRemaining <= 0 then
                        updateLabel.Text = "갱신 중..."
                    else
                        local minutes = math.floor(timeRemaining / 60)
                        local seconds = math.floor(timeRemaining % 60)
                        updateLabel.Text = string.format("다음 갱신: %d:%02d", minutes, seconds)
                    end
                end
            end
        end
        
        updateTimerSide(frontGui)
        updateTimerSide(backGui)
    end
end

-- DataStore에서 글로벌 리더보드 로드
function CustomLeaderboardModule.LoadGlobalLeaderboard()
    local success, data = pcall(function()
        return leaderboardDataStore:GetAsync(LEADERBOARD_KEY)
    end)
    
    if success and data then
        -- 리셋 시간 확인
        local currentTime = tick()
        if data.lastResetTime and (currentTime - data.lastResetTime) >= UPDATE_INTERVAL then
            print("[커스텀 리더보드] 5분 경과로 인한 글로벌 리더보드 리셋")
            CustomLeaderboardModule.ResetGlobalLeaderboard()
            return {}
        end
        
        -- DataStore에서 불러온 데이터의 distance 필드를 숫자로 변환
        local loadedPlayers = data.topPlayers or {}
        CustomLeaderboardModule.TopPlayers = {}
        for _, playerData in ipairs(loadedPlayers) do
            table.insert(CustomLeaderboardModule.TopPlayers, {
                userId = playerData.userId,
                name = playerData.name,
                distance = tonumber(playerData.distance) or 0
            })
        end
        lastResetTime = data.lastResetTime or currentTime
        
        print(string.format("[커스텀 리더보드] 글로벌 리더보드 로드 완료 - %d명", #CustomLeaderboardModule.TopPlayers))
        return CustomLeaderboardModule.TopPlayers
    else
        print("[커스텀 리더보드] 글로벌 리더보드 데이터 없음 - 새로 생성")
        CustomLeaderboardModule.TopPlayers = {}
        lastResetTime = tick()
        return {}
    end
end

-- DataStore에 글로벌 리더보드 저장
function CustomLeaderboardModule.SaveGlobalLeaderboard()
    local dataToSave = {
        topPlayers = CustomLeaderboardModule.TopPlayers,
        lastResetTime = lastResetTime
    }
    
    local success, err = pcall(function()
        leaderboardDataStore:SetAsync(LEADERBOARD_KEY, dataToSave)
    end)
    
    if success then
        print("[커스텀 리더보드] 글로벌 리더보드 저장 완료")
    else
        warn("[커스텀 리더보드] 글로벌 리더보드 저장 실패:", err)
    end
end

-- 글로벌 리더보드 리셋
function CustomLeaderboardModule.ResetGlobalLeaderboard()
    CustomLeaderboardModule.TopPlayers = {}
    lastResetTime = tick()
    
    -- 모든 온라인 플레이어의 BestDistance도 리셋
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = PlayerDataModule.GetPlayerData(player)
        if playerData then
            playerData.BestDistance = 0
            PlayerDataModule.SetPlayerData(player, playerData)
            print(string.format("[리더보드 리셋] %s의 최장 거리 기록 초기화", player.Name))
        end
    end
    
    CustomLeaderboardModule.SaveGlobalLeaderboard()
    CustomLeaderboardModule.BroadcastLeaderboard()
    
    -- 전광판 업데이트
    updateScreenLeaderboards()
    
    print("[커스텀 리더보드] 5분 주기 리셋 완료 - 모든 기록 초기화")
end

-- TOP10 리더보드 업데이트 (온라인 + 오프라인 플레이어 포함)
function CustomLeaderboardModule.UpdateTopPlayers()
    print("[커스텀 리더보드] 글로벌 리더보드 업데이트 시작...")
    
    -- 5분 경과 확인
    local currentTime = tick()
    if (currentTime - lastResetTime) >= UPDATE_INTERVAL then
        CustomLeaderboardModule.ResetGlobalLeaderboard()
        return
    end
    
    -- 현재 온라인 플레이어들의 기록을 글로벌 리더보드에 반영
    local hasChanges = false
    
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = PlayerDataModule.GetPlayerData(player)
        if playerData and playerData.BestDistance and playerData.BestDistance > 0 then
            local updated = CustomLeaderboardModule.UpdatePlayerInGlobalLeaderboard(
                player.UserId, 
                player.Name, 
                playerData.BestDistance
            )
            if updated then
                hasChanges = true
            end
        end
    end
    
    -- 변경사항이 있으면 저장 및 브로드캐스트
    if hasChanges then
        CustomLeaderboardModule.SaveGlobalLeaderboard()
        CustomLeaderboardModule.BroadcastLeaderboard()
        -- 전광판 업데이트
        updateScreenLeaderboards()
    end
    
    print(string.format("[커스텀 리더보드] 글로벌 리더보드 업데이트 완료 - TOP%d", #CustomLeaderboardModule.TopPlayers))
end

-- 글로벌 리더보드에서 특정 플레이어 기록 업데이트
function CustomLeaderboardModule.UpdatePlayerInGlobalLeaderboard(userId, playerName, distance)
    -- 기존 기록 찾기
    local existingIndex = nil
    for i, playerData in ipairs(CustomLeaderboardModule.TopPlayers) do
        if playerData.userId == userId then
            existingIndex = i
            break
        end
    end
    
    -- 기존 기록이 있고 새 기록이 더 낮으면 업데이트하지 않음
    if existingIndex then
        local existingDistance = tonumber(CustomLeaderboardModule.TopPlayers[existingIndex].distance) or 0
        local newDistance = tonumber(distance) or 0
        if existingDistance >= newDistance then
            return false
        end
    end
    
    -- 기존 기록 제거 (있다면)
    if existingIndex then
        table.remove(CustomLeaderboardModule.TopPlayers, existingIndex)
    end
    
    -- 새 기록 추가 (distance를 숫자로 변환하여 저장)
    table.insert(CustomLeaderboardModule.TopPlayers, {
        userId = userId,
        name = playerName,
        distance = tonumber(distance) or 0
    })
    
    -- 거리순으로 정렬 (내림차순)
    table.sort(CustomLeaderboardModule.TopPlayers, function(a, b)
        local distanceA = tonumber(a.distance) or 0
        local distanceB = tonumber(b.distance) or 0
        return distanceA > distanceB
    end)
    
    -- TOP10만 유지
    while #CustomLeaderboardModule.TopPlayers > 10 do
        table.remove(CustomLeaderboardModule.TopPlayers)
    end
    
    return true
end

-- 모든 클라이언트에게 리더보드 데이터 전송
function CustomLeaderboardModule.BroadcastLeaderboard()
    for _, player in pairs(Players:GetPlayers()) do
        customLeaderboardEvent:FireClient(player, CustomLeaderboardModule.TopPlayers, lastResetTime)
    end
    
    -- 전광판도 업데이트
    updateScreenLeaderboards()
end

-- 특정 플레이어에게 리더보드 데이터 전송
function CustomLeaderboardModule.SendLeaderboardToPlayer(player)
    customLeaderboardEvent:FireClient(player, CustomLeaderboardModule.TopPlayers, lastResetTime)
end

-- 플레이어 기록 업데이트 시 호출
function CustomLeaderboardModule.OnPlayerRecordUpdated(player, newDistance)
    local updated = CustomLeaderboardModule.UpdatePlayerInGlobalLeaderboard(
        player.UserId, 
        player.Name, 
        newDistance
    )
    
    if updated then
        CustomLeaderboardModule.SaveGlobalLeaderboard()
        CustomLeaderboardModule.BroadcastLeaderboard()
        -- 전광판 업데이트는 BroadcastLeaderboard에서 처리됨
    end
end

-- 주기적 업데이트 시작
function CustomLeaderboardModule.StartPeriodicUpdate()
    -- 리더보드 업데이트 루프
    spawn(function()
        while true do
            wait(60) -- 1분마다 체크
            local currentTime = tick()
            
            -- 5분 경과 확인
            if (currentTime - lastResetTime) >= UPDATE_INTERVAL then
                CustomLeaderboardModule.ResetGlobalLeaderboard()
            else
                -- 일반 업데이트
                CustomLeaderboardModule.UpdateTopPlayers()
            end
        end
    end)
    
    -- 전광판 실시간 타이머 업데이트 루프 (10초마다)
    spawn(function()
        while true do
            wait(10)
            updateScreenTimers()
        end
    end)
    
    print("[커스텀 리더보드] 주기적 업데이트 시작 - 1분마다 체크, 5분마다 리셋")
    print("[전광판] 실시간 타이머 업데이트 시작 - 10초마다 갱신")
end

-- 플레이어 입장 시 리더보드 전송
function CustomLeaderboardModule.OnPlayerAdded(player)
    -- 플레이어가 완전히 로딩된 후 리더보드 전송
    spawn(function()
        wait(2) -- 2초 대기
        CustomLeaderboardModule.SendLeaderboardToPlayer(player)
    end)
end

-- 초기화
function CustomLeaderboardModule.Initialize()
    -- 전광판 스크린 설정
    setupLeaderboardScreens()
    
    -- 글로벌 리더보드 로드
    CustomLeaderboardModule.LoadGlobalLeaderboard()
    
    -- 플레이어 입장 이벤트 연결
    Players.PlayerAdded:Connect(CustomLeaderboardModule.OnPlayerAdded)
    
    -- 이미 접속한 플레이어들에게도 적용
    for _, player in pairs(Players:GetPlayers()) do
        CustomLeaderboardModule.OnPlayerAdded(player)
    end
    
    -- 초기 리더보드 업데이트
    wait(1) -- 모든 플레이어 데이터가 로딩될 때까지 대기
    CustomLeaderboardModule.UpdateTopPlayers()
    
    -- 초기 전광판 설정
    updateScreenLeaderboards()
    
    -- 주기적 업데이트 시작
    CustomLeaderboardModule.StartPeriodicUpdate()
    
    print("[커스텀 리더보드] 글로벌 시스템 초기화 완료")
    print("[전광판] 리더보드 표시 시스템 초기화 완료")
end

return CustomLeaderboardModule 