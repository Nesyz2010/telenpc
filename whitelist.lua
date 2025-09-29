-- Auto Teleport NPC với UI báo lỗi/thành công
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Tạo GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportUI"
screenGui.Parent = game.CoreGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 300, 0, 50)
statusLabel.Position = UDim2.new(0, 20, 0, 200)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 20
statusLabel.Text = "Đang chờ..."
statusLabel.Parent = screenGui

-- Hàm teleport
local function teleportToNPC(npcName)
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and string.find(npc.Name, npcName) then
            LocalPlayer.Character.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
            statusLabel.Text = "✅ Teleport thành công: " .. npc.Name
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            return true
        end
    end
    statusLabel.Text = "❌ Không tìm thấy NPC: " .. npcName
    statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    return false
end

-- Auto teleport loop
local NPC_NAME = "Elite Hunter" -- đổi tên NPC ở đây
while task.wait(2) do
    teleportToNPC(NPC_NAME)
end
