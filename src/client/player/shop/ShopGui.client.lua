local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvent 연결
local ShopRemoteEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("ShopRemoteEvent")

-- 상점 UI 변수
local shopGui
local isShopOpen = false

-- 상점 UI 생성
local function createShopGui()
    -- 메인 ScreenGui
    shopGui = Instance.new("ScreenGui")
    shopGui.Name = "ShopGui"
    shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    shopGui.Parent = playerGui
    
    -- 배경 (어둡게 만들기)
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Parent = shopGui
    
    -- 메인 프레임
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = background
    
    -- 둥근 모서리
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- 제목
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "상점"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- 닫기 버튼
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0.02, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- 스크롤 프레임
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemScrollFrame"
    scrollFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    scrollFrame.Position = UDim2.new(0.025, 0, 0.12, 0)
    scrollFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = mainFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 8)
    scrollCorner.Parent = scrollFrame
    
    -- GridLayout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.48, 0, 0.3, 0)
    gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.Name
    gridLayout.Parent = scrollFrame
    
    -- 닫기 버튼 이벤트
    closeButton.MouseButton1Click:Connect(function()
        closeShop()
    end)
    
    -- ESC 키로 닫기
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Escape and isShopOpen then
            closeShop()
        end
    end)
    
    return scrollFrame
end

-- 아이템 프레임 생성
local function createItemFrame(item, isOwned, scrollFrame)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = item.name
    itemFrame.BackgroundColor3 = isOwned and Color3.new(0.2, 0.4, 0.2) or Color3.new(0.2, 0.2, 0.3)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = scrollFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame
    
    -- 아이템 이미지
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ItemImage"
    imageLabel.Size = UDim2.new(0.4, 0, 0.6, 0)
    imageLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = item.image
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = itemFrame
    
    -- 아이템 이름
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(0.5, 0, 0.2, 0)
    nameLabel.Position = UDim2.new(0.48, 0, 0.05, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.Parent = itemFrame
    
    -- 아이템 설명
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "ItemDescription"
    descLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
    descLabel.Position = UDim2.new(0.48, 0, 0.25, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = item.description
    descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextWrapped = true
    descLabel.Parent = itemFrame
    
    -- 가격
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "ItemPrice"
    priceLabel.Size = UDim2.new(0.5, 0, 0.15, 0)
    priceLabel.Position = UDim2.new(0.48, 0, 0.5, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "가격: " .. item.price .. " 골드"
    priceLabel.TextColor3 = Color3.new(1, 0.8, 0)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.Parent = itemFrame
    
    -- 구매 버튼
    local buyButton = Instance.new("TextButton")
    buyButton.Name = "BuyButton"
    buyButton.Size = UDim2.new(0.9, 0, 0.2, 0)
    buyButton.Position = UDim2.new(0.05, 0, 0.75, 0)
    buyButton.BackgroundColor3 = isOwned and Color3.new(0.5, 0.5, 0.5) or Color3.new(0.2, 0.6, 0.2)
    buyButton.Text = isOwned and "구매완료" or "구매하기"
    buyButton.TextColor3 = Color3.new(1, 1, 1)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.GothamBold
    buyButton.Active = not isOwned
    buyButton.Parent = itemFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyButton
    
    -- 구매 버튼 이벤트
    if not isOwned then
        buyButton.MouseButton1Click:Connect(function()
            ShopRemoteEvent:FireServer("BuyItem", item.id)
        end)
    end
end

-- 상점 열기
local function openShop(shopItems, playerInventory)
    if isShopOpen then return end
    
    isShopOpen = true
    local scrollFrame = createShopGui()
    
    -- 아이템 추가
    for _, item in pairs(shopItems) do
        local isOwned = false
        for _, ownedItemId in pairs(playerInventory) do
            if ownedItemId == item.id then
                isOwned = true
                break
            end
        end
        createItemFrame(item, isOwned, scrollFrame)
    end
    
    -- GridLayout 크기 업데이트
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIGridLayout.AbsoluteContentSize.Y + 20)
end

-- 상점 닫기
function closeShop()
    if not isShopOpen then return end
    
    isShopOpen = false
    if shopGui then
        shopGui:Destroy()
        shopGui = nil
    end
end

-- 서버 이벤트 처리
ShopRemoteEvent.OnClientEvent:Connect(function(action, ...)
    if action == "OpenShop" then
        local shopItems, playerInventory = ...
        openShop(shopItems, playerInventory)
    elseif action == "PurchaseResult" then
        local success, message = ...
        
        -- 결과 메시지 표시 (간단한 알림)
        local messageGui = Instance.new("ScreenGui")
        messageGui.Name = "MessageGui"
        messageGui.Parent = playerGui
        
        local messageFrame = Instance.new("Frame")
        messageFrame.Size = UDim2.new(0.3, 0, 0.1, 0)
        messageFrame.Position = UDim2.new(0.35, 0, 0.45, 0)
        messageFrame.BackgroundColor3 = success and Color3.new(0.2, 0.6, 0.2) or Color3.new(0.6, 0.2, 0.2)
        messageFrame.BorderSizePixel = 0
        messageFrame.Parent = messageGui
        
        local messageCorner = Instance.new("UICorner")
        messageCorner.CornerRadius = UDim.new(0, 8)
        messageCorner.Parent = messageFrame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, 0, 1, 0)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = Color3.new(1, 1, 1)
        messageLabel.TextScaled = true
        messageLabel.Font = Enum.Font.GothamBold
        messageLabel.Parent = messageFrame
        
        -- 3초 후 제거
        game:GetService("Debris"):AddItem(messageGui, 3)
        
        -- 구매 성공 시 상점 새로고침
        if success and isShopOpen then
            closeShop()
            wait(0.1)
            ShopRemoteEvent:FireServer("RefreshShop")
        end
    end
end) 