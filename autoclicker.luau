local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local C = {
	bg = Color3.fromRGB(12, 12, 12),
	surface = Color3.fromRGB(20, 20, 20),
	elevated = Color3.fromRGB(28, 28, 28),
	border = Color3.fromRGB(40, 40, 40),
	primary = Color3.fromRGB(255, 255, 255),
	sub = Color3.fromRGB(255, 182, 193),
	muted = Color3.fromRGB(140, 140, 140),
	success = Color3.fromRGB(100, 220, 140),
	danger = Color3.fromRGB(220, 80, 80),
	warn = Color3.fromRGB(220, 160, 60),
}

local State = {
	clicking = false,
	settingPos = false,
	useCustomPos = false,
	customPos = Vector2.new(960, 540),
	clickCount = 0,
	keybind = Enum.KeyCode.F,
	settingKeybind = false,
	antiAfk = false,
	afkCount = 0,
	activeTab = "clicker",
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoClicker by FEMBOYSTONE"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 490)
Main.Position = UDim2.new(0.5, -150, 0.5, -245)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", Main)
ms.Color = C.border
ms.Thickness = 1

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = C.surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = C.surface
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 2)
Accent.Position = UDim2.new(0, 0, 1, -1)
Accent.BackgroundColor3 = C.sub
Accent.BorderSizePixel = 0
Accent.Parent = TitleBar

local TitleDot = Instance.new("Frame")
TitleDot.Size = UDim2.new(0, 8, 0, 8)
TitleDot.Position = UDim2.new(0, 16, 0.5, -4)
TitleDot.BackgroundColor3 = C.sub
TitleDot.BorderSizePixel = 0
TitleDot.Parent = TitleBar
Instance.new("UICorner", TitleDot).CornerRadius = UDim.new(1, 0)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 32, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Auto Clicker by FEMBOYSTONE"
TitleLabel.TextColor3 = C.primary
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.sub
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseEnter:Connect(function()
	CloseBtn.BackgroundColor3 = C.danger
	CloseBtn.TextColor3 = C.primary
end)
CloseBtn.MouseLeave:Connect(function()
	CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
	CloseBtn.TextColor3 = C.sub
end)

local allConnections = {}

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -32, 0, 32)
TabBar.Position = UDim2.new(0, 16, 0, 58)
TabBar.BackgroundColor3 = C.surface
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
local ts = Instance.new("UIStroke", TabBar)
ts.Color = C.border
ts.Thickness = 1

local TabBtnContainer = Instance.new("Frame")
TabBtnContainer.Size = UDim2.new(1, 0, 1, 0)
TabBtnContainer.BackgroundTransparency = 1
TabBtnContainer.Parent = TabBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = TabBtnContainer

local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0.5, -8, 0, 2)
tabIndicator.Position = UDim2.new(0, 4, 1, -3)
tabIndicator.BackgroundColor3 = C.sub
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 2
tabIndicator.Parent = TabBar
Instance.new("UICorner", tabIndicator).CornerRadius = UDim.new(1, 0)

local ClickerPanel = Instance.new("Frame")
ClickerPanel.Size = UDim2.new(1, -32, 1, -140)
ClickerPanel.Position = UDim2.new(0, 16, 0, 100)
ClickerPanel.BackgroundTransparency = 1
ClickerPanel.Parent = Main
local cl = Instance.new("UIListLayout", ClickerPanel)
cl.SortOrder = Enum.SortOrder.LayoutOrder
cl.Padding = UDim.new(0, 8)

local AfkPanel = Instance.new("Frame")
AfkPanel.Size = UDim2.new(1, -32, 1, -140)
AfkPanel.Position = UDim2.new(0, 16, 0, 100)
AfkPanel.BackgroundTransparency = 1
AfkPanel.Visible = false
AfkPanel.Parent = Main
local al = Instance.new("UIListLayout", AfkPanel)
al.SortOrder = Enum.SortOrder.LayoutOrder
al.Padding = UDim.new(0, 8)

local debugBar = Instance.new("Frame")
debugBar.Size = UDim2.new(1, -32, 0, 28)
debugBar.Position = UDim2.new(0, 16, 1, -38)
debugBar.BackgroundColor3 = C.surface
debugBar.BorderSizePixel = 0
debugBar.Parent = Main
Instance.new("UICorner", debugBar).CornerRadius = UDim.new(0, 8)
local ds = Instance.new("UIStroke", debugBar)
ds.Color = C.border
ds.Thickness = 1

local debugDot = Instance.new("Frame")
debugDot.Size = UDim2.new(0, 6, 0, 6)
debugDot.Position = UDim2.new(0, 10, 0.5, -3)
debugDot.BackgroundColor3 = C.muted
debugDot.BorderSizePixel = 0
debugDot.Parent = debugBar
Instance.new("UICorner", debugDot).CornerRadius = UDim.new(1, 0)

local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(1, -28, 1, 0)
debugLabel.Position = UDim2.new(0, 22, 0, 0)
debugLabel.BackgroundTransparency = 1
debugLabel.Text = "Idle"
debugLabel.TextColor3 = C.muted
debugLabel.TextSize = 11
debugLabel.Font = Enum.Font.Gotham
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.Parent = debugBar

local function log(msg, color)
	local c = color or C.muted
	debugLabel.Text = msg
	debugLabel.TextColor3 = c
	debugDot.BackgroundColor3 = c
	print("[AutoClicker] " .. msg)
end

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 8)
end

local function makeStroke(parent, color)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or C.border
	s.Thickness = 1
end

local function sectionLabel(text, order, parent)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.BackgroundTransparency = 1
	lbl.Text = text:upper()
	lbl.TextColor3 = C.sub
	lbl.TextSize = 10
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order
	lbl.Parent = parent
end

local function makeRow(order, parent, height)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, height or 36)
	row.BackgroundColor3 = C.elevated
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = parent
	makeCorner(row)
	makeStroke(row)
	return row
end

local function rowLabel(text, parent)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = C.muted
	lbl.TextSize = 12
	lbl.Font = Enum.Font.Gotham
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
end

local function rowValue(text, parent, color)
	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0.45, -12, 1, 0)
	val.Position = UDim2.new(0.5, 0, 0, 0)
	val.BackgroundTransparency = 1
	val.Text = text
	val.TextColor3 = color or C.sub
	val.TextSize = 12
	val.Font = Enum.Font.GothamBold
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = parent
	return val
end

local function inputRow(labelText, defaultVal, order, parent)
	local row = makeRow(order, parent)
	rowLabel(labelText, row)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.35, 0, 0, 24)
	box.Position = UDim2.new(0.62, 0, 0.5, -12)
	box.BackgroundColor3 = C.surface
	box.BorderSizePixel = 0
	box.Text = defaultVal
	box.TextColor3 = C.primary
	box.TextSize = 12
	box.Font = Enum.Font.GothamBold
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.Parent = row
	makeCorner(box, 6)
	return box
end

local function infoRow(labelText, valueText, order, parent, valueColor)
	local row = makeRow(order, parent)
	rowLabel(labelText, row)
	return rowValue(valueText, row, valueColor)
end

local function makeBtn(text, color, order, parent)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = C.primary
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamBold
	btn.LayoutOrder = order
	btn.Parent = parent
	makeCorner(btn)
	return btn
end

local function addHover(btn, base, hover)
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = hover
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = base
	end)
end

local DARK_BTN = Color3.fromRGB(35, 35, 35)
local DARK_HOVER = Color3.fromRGB(50, 35, 40)

local function darkBtn(text, order, parent)
	local b = makeBtn(text, DARK_BTN, order, parent)
	addHover(b, DARK_BTN, DARK_HOVER)
	return b
end

local function makeTabBtn(text, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.5, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = text
	btn.TextColor3 = C.muted
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.LayoutOrder = order
	btn.Parent = TabBtnContainer
	return btn
end

local tabClicker = makeTabBtn("Clicker", 1)
local tabAfk = makeTabBtn("Anti-AFK", 2)

local function switchTab(tab)
	State.activeTab = tab
	ClickerPanel.Visible = (tab == "clicker")
	AfkPanel.Visible = (tab == "afk")
	tabClicker.TextColor3 = (tab == "clicker") and C.primary or C.muted
	tabAfk.TextColor3 = (tab == "afk") and C.primary or C.muted
	if tab == "clicker" then
		tabIndicator.Position = UDim2.new(0, 4, 1, -3)
	else
		tabIndicator.Position = UDim2.new(0.5, 4, 1, -3)
	end
end

tabClicker.MouseButton1Click:Connect(function()
	switchTab("clicker")
end)
tabAfk.MouseButton1Click:Connect(function()
	switchTab("afk")
end)

sectionLabel("Timing", 1, ClickerPanel)
local delayBox = inputRow("Delay (seconds)", "0.1", 2, ClickerPanel)

sectionLabel("Position", 3, ClickerPanel)

local posDisplay = makeRow(4, ClickerPanel)
rowLabel("Saved Pos", posDisplay)
local posValLbl = rowValue("960, 540", posDisplay)

local setPosBtn = darkBtn("Set Position: Click to Enter Mode", 5, ClickerPanel)
local usePosBtn = darkBtn("Custom Position: OFF", 6, ClickerPanel)

sectionLabel("Keybind", 7, ClickerPanel)
local keybindBtn = darkBtn("Keybind: [ F ]", 8, ClickerPanel)
local toggleBtn = makeBtn("Start", C.sub, 9, ClickerPanel)

sectionLabel("Status", 1, AfkPanel)
local afkStatusVal = infoRow("State", "Disabled", 2, AfkPanel, C.muted)
local afkFiredVal = infoRow("Times Fired", "0", 3, AfkPanel, C.sub)

local afkToggleBtn = makeBtn("Enable Anti-AFK", C.sub, 4, AfkPanel)

local afkConnection = nil

local function setAntiAfk(enabled)
	State.antiAfk = enabled
	if enabled then
		afkStatusVal.Text = "Active"
		afkStatusVal.TextColor3 = C.success
		afkToggleBtn.Text = "Disable Anti-AFK"
		afkToggleBtn.BackgroundColor3 = C.danger
		log("Anti-AFK enabled", C.success)

		afkConnection = LocalPlayer.Idled:Connect(function()
			VirtualUser:Button1Down(Vector2.new(0, 0), CFrame.new())
			task.wait(0.1)
			VirtualUser:Button1Up(Vector2.new(0, 0), CFrame.new())
			State.afkCount += 1
			afkFiredVal.Text = tostring(State.afkCount)
			log("AFK kick prevented · " .. State.afkCount .. "x", C.success)
		end)
		table.insert(allConnections, afkConnection)
	else
		afkStatusVal.Text = "Disabled"
		afkStatusVal.TextColor3 = C.muted
		afkToggleBtn.Text = "Enable Anti-AFK"
		afkToggleBtn.BackgroundColor3 = C.sub
		log("Anti-AFK disabled", C.muted)
		if afkConnection then
			afkConnection:Disconnect()
			afkConnection = nil
		end
	end
end

afkToggleBtn.MouseButton1Click:Connect(function()
	setAntiAfk(not State.antiAfk)
end)

local function updatePosDisplay()
	posValLbl.Text = State.customPos.X .. ", " .. State.customPos.Y
end

local mainInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if State.settingPos and input.UserInputType == Enum.UserInputType.MouseButton1 then
		task.wait()
		State.customPos = Vector2.new(
			math.floor(UserInputService:GetMouseLocation().X),
			math.floor(UserInputService:GetMouseLocation().Y)
		)
		updatePosDisplay()
		State.settingPos = false
		setPosBtn.Text = "Set Position: Click to Enter Mode"
		setPosBtn.BackgroundColor3 = DARK_BTN
		log("Position saved → " .. State.customPos.X .. ", " .. State.customPos.Y, C.success)
		return
	end

	if gameProcessed then
		return
	end
	if State.settingKeybind then
		return
	end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == State.keybind then
		toggleClicking()
	end
end)
table.insert(allConnections, mainInputConnection)

setPosBtn.MouseButton1Click:Connect(function()
	if State.clicking then
		log("Stop clicker before setting pos", C.warn)
		return
	end
	State.settingPos = not State.settingPos
	if State.settingPos then
		setPosBtn.Text = "Click anywhere to capture pos..."
		setPosBtn.BackgroundColor3 = C.warn
		log("Click anywhere to capture position", C.warn)
	else
		setPosBtn.Text = "Set Position: Click to Enter Mode"
		setPosBtn.BackgroundColor3 = DARK_BTN
		log("Cancelled", C.muted)
	end
end)

usePosBtn.MouseButton1Click:Connect(function()
	State.useCustomPos = not State.useCustomPos
	usePosBtn.Text = "Custom Position: " .. (State.useCustomPos and "ON" or "OFF")
	usePosBtn.BackgroundColor3 = State.useCustomPos and Color3.fromRGB(40, 25, 35) or DARK_BTN
	log("Custom pos " .. (State.useCustomPos and "enabled" or "disabled"), State.useCustomPos and C.success or C.muted)
end)

local keybindConn = nil
keybindBtn.MouseButton1Click:Connect(function()
	if State.settingKeybind then
		return
	end
	State.settingKeybind = true
	keybindBtn.Text = "Press any key..."
	keybindBtn.BackgroundColor3 = C.warn
	log("Waiting for keybind...", C.warn)
	task.wait(0.1)
	keybindConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		State.keybind = input.KeyCode
		keybindBtn.Text = "Keybind: [ " .. State.keybind.Name .. " ]"
		keybindBtn.BackgroundColor3 = DARK_BTN
		State.settingKeybind = false
		log("Keybind → " .. State.keybind.Name, C.success)
		keybindConn:Disconnect()
		keybindConn = nil
	end)
	table.insert(allConnections, keybindConn)
end)

local cachedMethod = nil

local function doClick(pos)
	if cachedMethod == "m1c" then
		mousemoveabs(pos.X, pos.Y)
		mouse1click()
		return "mouse1click"
	elseif cachedMethod == "m1p" then
		mousemoveabs(pos.X, pos.Y)
		mouse1press()
		task.wait(0.05)
		mouse1release()
		return "mouse1press/release"
	end

	local ok1 = pcall(function()
		mousemoveabs(pos.X, pos.Y)
		mouse1click()
	end)
	if ok1 then
		cachedMethod = "m1c"
		return "mouse1click"
	end

	local ok2 = pcall(function()
		mousemoveabs(pos.X, pos.Y)
		mouse1press()
		task.wait(0.05)
		mouse1release()
	end)
	if ok2 then
		cachedMethod = "m1p"
		return "mouse1press/release"
	end

	return nil, "no valid click method found"
end

function toggleClicking()
	if State.settingPos or State.settingKeybind then
		return
	end
	State.clicking = not State.clicking

	if State.clicking then
		toggleBtn.Text = "Stop"
		toggleBtn.BackgroundColor3 = C.danger
		State.clickCount = 0
		log("Running...", C.success)

		task.spawn(function()
			while State.clicking do
				local pos = State.useCustomPos and State.customPos or UserInputService:GetMouseLocation()

				local method, err = doClick(pos)

				if method then
					State.clickCount += 1
					log("#" .. State.clickCount .. " @ " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y), C.success)
				else
					log("Error: " .. tostring(err), C.danger)
					State.clicking = false
					toggleBtn.Text = "Start"
					toggleBtn.BackgroundColor3 = C.sub
					break
				end

				task.wait(tonumber(delayBox.Text) or 0.1)
			end
			log("Stopped · " .. State.clickCount .. " clicks", C.muted)
		end)
	else
		toggleBtn.Text = "Start"
		toggleBtn.BackgroundColor3 = C.sub
		log("Stopped · " .. State.clickCount .. " clicks", C.muted)
	end
end

toggleBtn.MouseButton1Click:Connect(toggleClicking)

updatePosDisplay()
switchTab("clicker")

local function cleanup()
	log("Cleaning up...", C.muted)

	for _, conn in ipairs(allConnections) do
		if conn then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end

	if keybindConn then
		pcall(function()
			keybindConn:Disconnect()
		end)
	end

	if afkConnection then
		pcall(function()
			afkConnection:Disconnect()
		end)
	end

	log("Cleanup complete", C.muted)
end

CloseBtn.MouseButton1Click:Connect(function()
	cleanup()
	ScreenGui:Destroy()
end)
