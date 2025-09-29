--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Remotes (đổi tên ở đây nếu server bạn khác)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StatFunction = Remotes:WaitForChild("StatFunction") -- Add point
local RefundStats = Remotes:WaitForChild("RefundStats")   -- Refund

--// ====== Helper: Safe invoke (RemoteFunction/RemoteEvent đều chịu) ======
local function safeInvoke(remote, ...)
	-- Ưu tiên RemoteFunction:InvokeServer, fallback RemoteEvent:FireServer
	local ok, res = pcall(function()
		if remote and remote.InvokeServer then
			return remote:InvokeServer(...)
		elseif remote and remote.FireServer then
			return remote:FireServer(...)
		end
	end)
	if not ok then
		warn("Remote call failed:", res)
	end
	return ok, res
end

--// ====== Helper: Add Stat 1000 ======
-- Tên stat thường dùng: "Melee", "Defense", "Sword", "Gun"
local function addStat(statName, amount)
	amount = amount or 1000
	-- Một số game dùng format: StatFunction:InvokeServer("AddPoint", "Melee", 1000)
	-- Một số dùng: StatFunction:InvokeServer({Action="AddPoint", Stat="Melee", Amount=1000})
	-- Thử tuần tự nhiều kiểu cho chắc
	-- Kiểu 1:
	local ok = safeInvoke(StatFunction, "AddPoint", statName, amount)
	if ok then return end
	-- Kiểu 2:
	ok = safeInvoke(StatFunction, {Action="AddPoint", Stat=statName, Amount=amount})
	if ok then return end
	-- Kiểu 3: đôi khi chỉ truyền stat và amount
	ok = safeInvoke(StatFunction, statName, amount)
end

--// ====== Helper: Refund ======
local function doRefund()
	-- Thử nhiều kiểu gọi
	local ok = safeInvoke(RefundStats)
	if ok then return end
	ok = safeInvoke(RefundStats, "Refund")
	if ok then return end
	ok = safeInvoke(RefundStats, {Action="Refund"})
end

--// ====== Mastery Finder (auto-check Sword / Gun) ======
-- Cách lấy Mastery phụ thuộc game. Ở nhiều game, Tool có NumberValue/IntValue tên "Mastery"
-- hoặc Attribute "Mastery" / Value trong PlayerData. Ta sẽ quét Backpack + Character.
local function getToolMasteryByType(toolType) -- "Sword" hoặc "Gun"
	local function scan(container)
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") then
				local name = (tool.Name or ""):lower()
				-- Heuristic nhận dạng
				local isSword = name:find("sword") or (tool:FindFirstChild("ToolType") and tostring(tool.ToolType.Value):lower()=="sword")
				local isGun   = name:find("gun")   or (tool:FindFirstChild("ToolType") and tostring(tool.ToolType.Value):lower()=="gun")

				local match = (toolType=="Sword" and isSword) or (toolType=="Gun" and isGun)
				if match then
					-- Tìm NumberValue/IntValue tên "Mastery" hoặc Attribute
					local mastery = nil
					local val = tool:FindFirstChild("Mastery") or tool:FindFirstChild("Level") or tool:FindFirstChild("MasteryLevel")
					if val and val:IsA("NumberValue") or val and val:IsA("IntValue") then
						mastery = val.Value
					elseif tool:GetAttribute("Mastery") then
						mastery = tool:GetAttribute("Mastery")
					end
					-- Nếu không có value, trả nil (hiển thị —)
					return mastery
				end
			end
		end
	end

	-- Ưu tiên Character > Backpack (đang equip)
	local char = LocalPlayer.Character
	if char then
		local m = scan(char)
		if m ~= nil then return m end
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		local m = scan(backpack)
		if m ~= nil then return m end
	end
	return nil
end

--// ====== UI ======
local function createRound(parent, r)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, r or 12)
	ui.Parent = parent
	return ui
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxStatUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 360, 0, 270)
Main.Position = UDim2.new(0.5, -180, 0.5, -135)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
createRound(Main, 14)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Header.BorderSizePixel = 0
Header.Parent = Main
createRound(Header, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "Blox Fruits – Refund & Auto Stat"
Title.Parent = Header

-- Tabs
local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(0, 120, 0, 36)
Tabs.Position = UDim2.new(1, -126, 0.5, -18)
Tabs.BackgroundTransparency = 1
Tabs.Parent = Header

local UIList = Instance.new("UIListLayout")
UIList.FillDirection = Enum.FillDirection.Horizontal
UIList.Padding = UDim.new(0, 6)
UIList.Parent = Tabs

local function mkTabButton(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 56, 1, 0)
	b.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Text = text
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.AutoButtonColor = false
	createRound(b, 10)
	b.Parent = Tabs
	b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(75,75,90) end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(60,60,70) end)
	return b
end

local refundTabBtn = mkTabButton("Refund")
local autoTabBtn   = mkTabButton("Auto")

-- Content container
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -24, 1, -60)
Body.Position = UDim2.new(0, 12, 0, 52)
Body.BackgroundTransparency = 1
Body.Parent = Main

-- Pages
local RefundPage = Instance.new("Frame")
RefundPage.Size = UDim2.new(1, 0, 1, 0)
RefundPage.BackgroundTransparency = 1
RefundPage.Parent = Body

local AutoPage = Instance.new("Frame")
AutoPage.Size = UDim2.new(1, 0, 1, 0)
AutoPage.BackgroundTransparency = 1
AutoPage.Visible = false
AutoPage.Parent = Body

-- ===== REFUND PAGE =====
local RefundBox = Instance.new("Frame")
RefundBox.Size = UDim2.new(1, 0, 0, 140)
RefundBox.Position = UDim2.new(0, 0, 0, 0)
RefundBox.BackgroundColor3 = Color3.fromRGB(32,32,38)
RefundBox.BorderSizePixel = 0
RefundBox.Parent = RefundPage
createRound(RefundBox, 12)

local RefundTitle = Instance.new("TextLabel")
RefundTitle.Size = UDim2.new(1, -20, 0, 30)
RefundTitle.Position = UDim2.new(0, 10, 0, 10)
RefundTitle.BackgroundTransparency = 1
RefundTitle.Font = Enum.Font.GothamBold
RefundTitle.TextSize = 16
RefundTitle.TextXAlignment = Enum.TextXAlignment.Left
RefundTitle.TextColor3 = Color3.fromRGB(255,255,255)
RefundTitle.Text = "💸 Refund Stats"
RefundTitle.Parent = RefundBox

local RefundBtn = Instance.new("TextButton")
RefundBtn.Size = UDim2.new(0, 150, 0, 40)
RefundBtn.Position = UDim2.new(0, 10, 0, 54)
RefundBtn.BackgroundColor3 = Color3.fromRGB(255, 95, 95)
RefundBtn.TextColor3 = Color3.fromRGB(255,255,255)
RefundBtn.Font = Enum.Font.GothamBold
RefundBtn.TextSize = 16
RefundBtn.Text = "REFUND NOW"
RefundBtn.AutoButtonColor = false
createRound(RefundBtn, 10)
RefundBtn.Parent = RefundBox

RefundBtn.MouseEnter:Connect(function() RefundBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70) end)
RefundBtn.MouseLeave:Connect(function() RefundBtn.BackgroundColor3 = Color3.fromRGB(255, 95, 95) end)
RefundBtn.MouseButton1Click:Connect(function()
	doRefund()
	StarterGui:SetCore("SendNotification", {Title="Refund", Text="Đã gửi yêu cầu Refund!", Duration=2})
end)

-- ===== AUTO PAGE =====
local StatsBox = Instance.new("Frame")
StatsBox.Size = UDim2.new(1, 0, 0, 150)
StatsBox.Position = UDim2.new(0, 0, 0, 0)
StatsBox.BackgroundColor3 = Color3.fromRGB(32,32,38)
StatsBox.BorderSizePixel = 0
StatsBox.Parent = AutoPage
createRound(StatsBox, 12)

local StatsTitle = Instance.new("TextLabel")
StatsTitle.Size = UDim2.new(1, -20, 0, 30)
StatsTitle.Position = UDim2.new(0, 10, 0, 10)
StatsTitle.BackgroundTransparency = 1
StatsTitle.Font = Enum.Font.GothamBold
StatsTitle.TextSize = 16
StatsTitle.TextXAlignment = Enum.TextXAlignment.Left
StatsTitle.TextColor3 = Color3.fromRGB(255,255,255)
StatsTitle.Text = "⚙️ Auto Stat (mỗi lần +1000)"
StatsTitle.Parent = StatsBox

-- Buttons row
local Row = Instance.new("Frame")
Row.Size = UDim2.new(1, -20, 0, 44)
Row.Position = UDim2.new(0, 10, 0, 54)
Row.BackgroundTransparency = 1
Row.Parent = StatsBox

local RowLayout = Instance.new("UIListLayout")
RowLayout.FillDirection = Enum.FillDirection.Horizontal
RowLayout.Padding = UDim.new(0, 8)
RowLayout.Parent = Row

local function mkActionButton(txt)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -4, 1, 0)
	b.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Text = txt
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.AutoButtonColor = false
	createRound(b, 10)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(80, 135, 255) end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(70, 120, 255) end)
	b.Parent = Row
	return b
end

local btnSwordSet = mkActionButton("➕ Melee + Sword + Defense")
local btnGunSet   = mkActionButton("➕ Melee + Gun + Defense")

btnSwordSet.MouseButton1Click:Connect(function()
	addStat("Melee", 1000)
	addStat("Sword", 1000)
	addStat("Defense", 1000)
end)

btnGunSet.MouseButton1Click:Connect(function()
	addStat("Melee", 1000)
	addStat("Gun", 1000)
	addStat("Defense", 1000)
end)

-- Auto toggle
local AutoRow = Instance.new("Frame")
AutoRow.Size = UDim2.new(1, -20, 0, 44)
AutoRow.Position = UDim2.new(0, 10, 0, 102)
AutoRow.BackgroundTransparency = 1
AutoRow.Parent = StatsBox

local AutoLayout = Instance.new("UIListLayout")
AutoLayout.FillDirection = Enum.FillDirection.Horizontal
AutoLayout.Padding = UDim.new(0, 8)
AutoLayout.Parent = AutoRow

local function mkToggle(text)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, -4, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(45,45,52)
	frame.BorderSizePixel = 0
	createRound(frame, 10)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(220,220,230)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 52, 0, 28)
	btn.Position = UDim2.new(1, -62, 0.5, -14)
	btn.BackgroundColor3 = Color3.fromRGB(100, 100, 115)
	btn.Text = "OFF"
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.AutoButtonColor = false
	createRound(btn, 8)
	btn.Parent = frame

	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(115,115,130) end)
	btn.MouseLeave:Connect(function()
		if btn.Text == "OFF" then btn.BackgroundColor3 = Color3.fromRGB(100,100,115) else btn.BackgroundColor3 = Color3.fromRGB(70,160,100) end
	end)

	return frame, btn
end

local swordAutoFrame, swordAutoBtn = mkToggle("Auto ➕ Melee + Sword + Defense")
swordAutoFrame.Parent = AutoRow
local gunAutoFrame, gunAutoBtn = mkToggle("Auto ➕ Melee + Gun + Defense")
gunAutoFrame.Parent = AutoRow

local swordAuto = false
local gunAuto = false

local function setToggle(btn, state)
	if state then
		btn.Text = "ON"
		btn.BackgroundColor3 = Color3.fromRGB(70, 160, 100)
	else
		btn.Text = "OFF"
		btn.BackgroundColor3 = Color3.fromRGB(100,100,115)
	end
end

swordAutoBtn.MouseButton1Click:Connect(function()
	swordAuto = not swordAuto
	if swordAuto then gunAuto = false setToggle(gunAutoBtn,false) end
	setToggle(swordAutoBtn, swordAuto)
end)

gunAutoBtn.MouseButton1Click:Connect(function()
	gunAuto = not gunAuto
	if gunAuto then swordAuto = false setToggle(swordAutoBtn,false) end
	setToggle(gunAutoBtn, gunAuto)
end)

-- ===== MASTERIES BOX =====
local MasteryBox = Instance.new("Frame")
MasteryBox.Size = UDim2.new(1, 0, 0, 100)
MasteryBox.Position = UDim2.new(0, 0, 0, 160)
MasteryBox.BackgroundColor3 = Color3.fromRGB(32,32,38)
MasteryBox.BorderSizePixel = 0
MasteryBox.Parent = AutoPage
createRound(MasteryBox, 12)

local MasteryTitle = Instance.new("TextLabel")
MasteryTitle.Size = UDim2.new(1, -20, 0, 26)
MasteryTitle.Position = UDim2.new(0, 10, 0, 8)
MasteryTitle.BackgroundTransparency = 1
MasteryTitle.Font = Enum.Font.GothamBold
MasteryTitle.TextSize = 16
MasteryTitle.TextXAlignment = Enum.TextXAlignment.Left
MasteryTitle.TextColor3 = Color3.fromRGB(255,255,255)
MasteryTitle.Text = "📊 Mastery (Auto Check mỗi 2s)"
MasteryTitle.Parent = MasteryBox

local MasteryRow = Instance.new("Frame")
MasteryRow.Size = UDim2.new(1, -20, 0, 50)
MasteryRow.Position = UDim2.new(0, 10, 0, 40)
MasteryRow.BackgroundTransparency = 1
MasteryRow.Parent = MasteryBox

local MasteryLayout = Instance.new("UIListLayout")
MasteryLayout.FillDirection = Enum.FillDirection.Horizontal
MasteryLayout.Padding = UDim.new(0, 8)
MasteryLayout.Parent = MasteryRow

local function mkMeter(labelText)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0.5, -4, 1, 0)
	holder.BackgroundColor3 = Color3.fromRGB(45,45,52)
	holder.BorderSizePixel = 0
	createRound(holder, 10)

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.5, -10, 1, 0)
	name.Position = UDim2.new(0, 10, 0, 0)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamMedium
	name.TextSize = 14
	name.TextColor3 = Color3.fromRGB(220,220,230)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = labelText
	name.Parent = holder

	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(0.5, -10, 1, 0)
	value.Position = UDim2.new(0.5, 0, 0, 0)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBlack
	value.TextSize = 20
	value.TextColor3 = Color3.fromRGB(255,255,255)
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Text = "—"
	value.Parent = holder

	return holder, value
end

local SwordHolder, SwordValue = mkMeter("🗡️ Sword Mastery")
SwordHolder.Parent = MasteryRow
local GunHolder, GunValue = mkMeter("🔫 Gun Mastery")
GunHolder.Parent = MasteryRow

-- ===== TAB SWITCH =====
local function showRefund()
	RefundPage.Visible = true
	AutoPage.Visible = false
end
local function showAuto()
	RefundPage.Visible = false
	AutoPage.Visible = true
end
refundTabBtn.MouseButton1Click:Connect(showRefund)
autoTabBtn.MouseButton1Click:Connect(showAuto)

-- ===== LOOPS =====
-- Auto allocate loop (mỗi 1.0s)
task.spawn(function()
	while true do
		if swordAuto then
			addStat("Melee", 1000)
			addStat("Sword", 1000)
			addStat("Defense", 1000)
		elseif gunAuto then
			addStat("Melee", 1000)
			addStat("Gun", 1000)
			addStat("Defense", 1000)
		end
		task.wait(1.0)
	end
end)

-- Mastery auto check loop (mỗi 2s)
task.spawn(function()
	while true do
		local s = getToolMasteryByType("Sword")
		local g = getToolMasteryByType("Gun")
		SwordValue.Text = s and tostring(s) or "—"
		GunValue.Text   = g and tostring(g) or "—"
		task.wait(2.0)
	end
end)

-- Draggable window (tuỳ chọn)
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
		input.Changed:Connect(function(obj)
			if obj.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

Main.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
