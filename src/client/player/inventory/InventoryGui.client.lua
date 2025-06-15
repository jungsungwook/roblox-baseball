local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvent 연결
local InventoryRemoteEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("InventoryRemoteEvent")

-- 인벤토리 UI 변수
local inventoryGui
local isInventoryOpen = false
local inventoryButton

-- Forward declarations
local closeInventory

-- 인벤토리 토글 버튼 생성
local function createInventoryButton()
    local buttonGui = Instance.new("ScreenGui")
    buttonGui.Name = "InventoryButtonGui"
    buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    buttonGui.Parent = playerGui
    
    inventoryButton = Instance.new("TextButton")
    inventoryButton.Name = "InventoryButton"
    inventoryButton.Size = UDim2.new(0.08, 0, 0.12, 0)
    inventoryButton.Position = UDim2.new(0.02, 0, 0.4, 0)
    inventoryButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    inventoryButton.Text = "가방"
    inventoryButton.TextColor3 = Color3.new(1, 1, 1)
    inventoryButton.TextScaled = true
    inventoryButton.Font = Enum.Font.GothamBold
    inventoryButton.Parent = buttonGui
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = inventoryButton
    
    -- 버튼 클릭 이벤트
    inventoryButton.MouseButton1Click:Connect(function()
        toggleInventory()
    end)
end

-- 인벤토리 UI 생성
local function createInventoryGui()
    inventoryGui = Instance.new("ScreenGui")
    inventoryGui.Name = "InventoryGui"
    inventoryGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    inventoryGui.Parent = playerGui
    
    -- 메인 프레임 (화면 왼쪽)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.3, 0, 0.6, 0)
    mainFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = inventoryGui
    
    -- 둥근 모서리
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- 제목 바
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(1, 0, 0.12, 0)
    titleFrame.Position = UDim2.new(0, 0, 0, 0)
    titleFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleFrame
    
    -- 제목
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "인벤토리"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleFrame
    
    -- 닫기 버튼
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.15, 0, 0.8, 0)
    closeButton.Position = UDim2.new(0.83, 0, 0.1, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- 스크롤 프레임
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemScrollFrame"
    scrollFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    scrollFrame.Position = UDim2.new(0.025, 0, 0.14, 0)
    scrollFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = mainFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 8)
    scrollCorner.Parent = scrollFrame
    
    -- UIListLayout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = scrollFrame
    
    -- 닫기 버튼 이벤트
    closeButton.MouseButton1Click:Connect(function()
        closeInventory()
    end)
    
    return scrollFrame
end

-- 아이템 프레임 생성
local function createInventoryItemFrame(item, scrollFrame)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = item.name
    itemFrame.Size = UDim2.new(1, -10, 0, 80)
    itemFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = scrollFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = itemFrame
    
    -- 아이템 이미지
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ItemImage"
    imageLabel.Size = UDim2.new(0, 60, 0, 60)
    imageLabel.Position = UDim2.new(0, 10, 0, 10)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = item.image
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = itemFrame
    
    -- 아이템 정보 프레임
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, -80, 1, -20)
    infoFrame.Position = UDim2.new(0, 75, 0, 10)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = itemFrame
    
    -- 아이템 이름
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = infoFrame
    
    -- 아이템 설명
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "ItemDescription"
    descLabel.Size = UDim2.new(1, 0, 0.6, 0)
    descLabel.Position = UDim2.new(0, 0, 0.4, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = item.description
    descLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = infoFrame
end

-- 인벤토리 열기
local function openInventory()
    if isInventoryOpen then return end
    
    isInventoryOpen = true
    inventoryButton.Text = "닫기"
    inventoryButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.4)
    
    local scrollFrame = createInventoryGui()
    
    -- 서버에서 인벤토리 데이터 요청
    InventoryRemoteEvent:FireServer("GetInventory")
end

-- 인벤토리 닫기
closeInventory = function()
    if not isInventoryOpen then return end
    
    isInventoryOpen = false
    inventoryButton.Text = "가방"
    inventoryButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    
    if inventoryGui then
        inventoryGui:Destroy()
        inventoryGui = nil
    end
end

-- 인벤토리 토글
function toggleInventory()
    if isInventoryOpen then
        closeInventory()
    else
        openInventory()
    end
end

-- 서버 이벤트 처리
InventoryRemoteEvent.OnClientEvent:Connect(function(action, ...)
    if action == "InventoryData" then
        local inventoryItems = ...
        
        if inventoryGui then
            local scrollFrame = inventoryGui.MainFrame.ItemScrollFrame
            
            -- 기존 아이템들 제거
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            -- 아이템들 추가
            for _, item in pairs(inventoryItems) do
                createInventoryItemFrame(item, scrollFrame)
            end
            
            -- 스크롤 프레임 크기 업데이트
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y + 10)
        end
    end
end)

-- I 키로 인벤토리 토글
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.I then
        toggleInventory()
    end
end)

-- 초기화
createInventoryButton() 