local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TransitionEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("TransitionRemoteEvent")

-- 클라이언트가 화면 전환 요청 시 처리
TransitionEvent.OnServerEvent:Connect(function(player)
    -- 요청한 플레이어에게만 화면 전환을 실행하도록 응답
    TransitionEvent:FireClient(player)
end)

-- 서버가 직접 모든 플레이어에게 화면 전환 요청하는 함수 (필요시 사용)
local function requestTransitionAllPlayers()
    TransitionEvent:FireAllClients()
end