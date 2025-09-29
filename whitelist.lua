--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Remotes (an toàn chờ + kiểm tra)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
assert(Remotes, "[AutoStat] Không tìm thấy ReplicatedStorage.Remotes")

local StatFunction = Remotes:WaitForChild("StatFunction", 10)
local RefundStats = Remotes:WaitForChild("RefundStats", 10)
assert(StatFunction and RefundStats, "[AutoStat] Thiếu Remote StatFunction/RefundStats")

--============================================================
-- UI
--============================================================
-- Không tạo trùng GUI
local ScreenGui = PlayerGui:FindFirstChild("AutoStatUI") or Instance.new("ScreenGui")
ScreenGui.Name = "AutoStatUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(240, 220)
Frame.Position = UDim2.new(0, 12, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.15
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 8)

local UIPadding = Instance.new("UIPadding", Frame)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)
UIPadding.PaddingTop = UDim.new(0, 8)
UIPadding.PaddingBottom = UDim.new(0, 8)

local UIListLayout = Instance.new("UIListLayout", Frame)
UIListLayout.Padding = UDim.new(0, 6)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 26)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "⚙️ Auto Stat Panel"

local function createButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.Text = text
    btn.AutoButtonColor = true
    btn.Parent = Frame

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        task.delay(0.12, function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
        end)
        callback()
    end)
    return btn
end

-- Trạng thái
local statusLabel = Instance.new("TextLabel", Frame)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.Text = "Trạng thái: ⛔ Tắt"

-- Nút Refund
createButton("🔄 Refund Stat", function()
    local ok, err = pcall(function()
        RefundStats:FireServer()
    end)
    statusLabel.Text = ok and "Đã gửi yêu cầu Refund ✅" or ("Refund lỗi: ".. tostring(err))
end)

-- Mode & Toggle
local autoStat = false
local statMode: "Sword" | "Gun" | nil = nil

createButton("⚔️ Auto Stat: Sword + Melee + Defense", function()
    autoStat = true
    statMode = "Sword"
    statusLabel.Text = "Trạng thái: ✅ Bật (Sword)"
end)

createButton("🔫 Auto Stat: Gun + Melee + Defense", function()
    autoStat = true
    statMode = "Gun"
    statusLabel.Text = "Trạng thái: ✅ Bật (Gun)"
end)

createButton("⛔ Stop Auto Stat", function()
    autoStat = false
    statMode = nil
    statusLabel.Text = "Trạng thái: ⛔ Tắt"
end)

-- Mastery labels
local swordLabel = Instance.new("TextLabel", Frame)
swordLabel.Size = UDim2.new(1, 0, 0, 20)
swordLabel.BackgroundTransparency = 1
swordLabel.Font = Enum.Font.Gotham
swordLabel.TextSize = 14
swordLabel.TextXAlignment = Enum.TextXAlignment.Left
swordLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
swordLabel.Text = "Sword Mastery: ..."

local gunLabel = Instance.new("TextLabel", Frame)
gunLabel.Size = UDim2.new(1, 0, 0, 20)
gunLabel.BackgroundTransparency = 1
gunLabel.Font = Enum.Font.Gotham
gunLabel.TextSize = 14
gunLabel.TextXAlignment = Enum.TextXAlignment.Left
gunLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
gunLabel.Text = "Gun Mastery: ..."

--============================================================
-- Logic
--============================================================
-- Hàm cộng Stat (chống spam + an toàn)
local lastSend = 0
local SEND_COOLDOWN = 0.25 -- giây, điều chỉnh để không flood server
local ADD_AMOUNT = 50       -- Đừng gửi 1000/lần; chia nhỏ để thân thiện server

local function safeAdd(stat, amount)
    if time() - lastSend < SEND_COOLDOWN then
        return
    end
    lastSend = time()
    local ok, err = pcall(function()
        -- Tùy theo server, định dạng tham số có thể khác
        StatFunction:InvokeServer("AddPoint", stat, amount)
    end)
    if not ok then
        statusLabel.Text = "Gửi stat lỗi: " .. tostring(err)
    end
end

-- Theo dõi Mastery bằng sự kiện thay vì poll 1s
local function hookMastery(dataFolder: Instance)
    if not dataFolder then return end

    local swordStat = dataFolder:FindFirstChild("SwordMastery")
    if swordStat and swordStat:IsA("IntValue") then
        swordLabel.Text = "Sword Mastery: " .. swordStat.Value
        swordStat.Changed:Connect(function()
            swordLabel.Text = "Sword Mastery: " .. swordStat.Value
        end)
    end

    local gunStat = dataFolder:FindFirstChild("GunMastery")
    if gunStat and gunStat:IsA("IntValue") then
        gunLabel.Text = "Gun Mastery: " .. gunStat.Value
        gunStat.Changed:Connect(function()
            gunLabel.Text = "Gun Mastery: " .. gunStat.Value
        end)
    end
end

-- Gắn lại khi Data sẵn sàng / nhân vật spawn
local function tryHookData()
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        hookMastery(dataFolder)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    tryHookData()
end)

-- Lần đầu
tryHookData()

-- Vòng lặp Auto Stat trên Heartbeat (mượt & dễ dừng)
local conn
conn = RunService.Heartbeat:Connect(function()
    if not autoStat or not statMode then return end

    -- Melee & Defense luôn
    safeAdd("Melee", ADD_AMOUNT)
    safeAdd("Defense", ADD_AMOUNT)

    if statMode == "Sword" then
        safeAdd("Sword", ADD_AMOUNT)
    elseif statMode == "Gun" then
        safeAdd("Gun", ADD_AMOUNT)
    end
end)

-- Dọn dẹp nếu cần (ví dụ khi GUI bị xóa)
ScreenGui.AncestryChanged:Connect(function(_, parent)
    if not parent and conn then
        conn:Disconnect()
        conn = nil
    end
end)

--============================================================
-- Lưu ý quan trọng (Best Practices):
-- 1) Chỉ dùng script client này cho game của BẠN. Với game người khác, server thường chặn/kiểm tra.
-- 2) Server nên xác thực: giới hạn mỗi tick, tổng điểm tối đa, và quyền của người chơi.
-- 3) Tránh gửi gói lớn (1000 điểm/lần). Gửi nhỏ + cooldown để không bị coi là flood.
-- 4) Các tên Remote/Tham số ("AddPoint") phải khớp với code server của bạn.
--============================================================
