if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Load Obsidian UI
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Create window
local Window = Library:CreateWindow({
	Title = "Silent Aim",
	Center = true,
	AutoShow = true,
	Resizable = true,
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

-- Tabs
local Tabs = {
	Main = Window:AddTab("Main", "target"),
	UISettings = Window:AddTab("UI Settings", "settings"),
}

-- ======================== SETTINGS ========================
local Settings = {
	Enabled = false,
	FOVRadius = 300,
	WallCheck = true,
}

-- ======================== SERVICES ========================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Original script's globals
local gs = workspace:FindFirstChild("Game Systems")
local lps = workspace:FindFirstChild("LocalPartStorage")

-- ======================== RAYCAST FILTERS (from original) ========================
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.IgnoreWater = true

local function isVisible(part, origin)
	local char = plr.Character
	if not (char and part) then
		return false
	end

	-- Build filter list exactly like original
	local ignoreList = { char, lps }
	if gs then
		local folders = {
			"ACS_WorkSpace",
			"Boat Workspace",
			"Tank Workspace",
			"Vehicle Workspace",
			"Helicopter Workspace",
			"Hovercraft Workspace",
			"Plane Workspace",
			"Gunship Workspace",
			"Submarine Workspace",
			"FireDamage",
		}
		for _, name in ipairs(folders) do
			local folder = gs:FindFirstChild(name)
			if folder then
				table.insert(ignoreList, folder)
			end
		end
	end
	rp.FilterDescendantsInstances = ignoreList

	local direction = part.Position - origin
	local result = workspace:Raycast(origin, direction, rp)
	if not result then
		return true
	end
	return result.Instance:IsDescendantOf(part.Parent)
end

-- ======================== TARGET ACQUISITION ========================
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled

local function getTarget()
	local origin = cam.CFrame.Position
	local viewportCenter = cam.ViewportSize / 2
	local aimPoint = isMobile and viewportCenter or UIS:GetMouseLocation()

	local closestPart = nil
	local closestDist = Settings.FOVRadius
	local targetScreenPos = nil

	for _, v in pairs(Players:GetPlayers()) do
		if v == plr then
			continue
		end
		local char = v.Character
		if not char then
			continue
		end

		local humanoid = char:FindFirstChild("Humanoid")
		if not (humanoid and humanoid.Health > 0) then
			continue
		end
		if char:FindFirstChildOfClass("ForceField") then
			continue
		end

		local targetPart = char:FindFirstChild("Head") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
		if not targetPart then
			continue
		end

		local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
		if not onScreen then
			continue
		end

		local screenVector = Vector2.new(screenPos.X, screenPos.Y)
		local distFromAim = (screenVector - aimPoint).Magnitude
		if distFromAim <= Settings.FOVRadius then
			if Settings.WallCheck then
				if not isVisible(targetPart, origin) then
					-- Try alternative part (PrimaryPart) if head is blocked
					local altPart = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
					if altPart and altPart ~= targetPart then
						if not isVisible(altPart, origin) then
							continue
						end
						targetPart = altPart
					else
						continue
					end
				end
			end
			if distFromAim < closestDist then
				closestDist = distFromAim
				closestPart = targetPart
				targetScreenPos = screenVector
			end
		end
	end

	return closestPart, targetScreenPos
end

-- ======================== DRAWING OBJECTS ========================
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = Settings.FOVRadius
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(255, 255, 0) -- yellow
fovCircle.Transparency = 0.5
fovCircle.Filled = false
fovCircle.Visible = true

local targetLine = Drawing.new("Line")
targetLine.Thickness = 2
targetLine.Color = Color3.fromRGB(255, 255, 0)
targetLine.Transparency = 0.7
targetLine.Visible = false

local function updatePositions()
	local center = cam.ViewportSize / 2
	fovCircle.Position = center
	targetLine.From = center
end
updatePositions()
cam:GetPropertyChangedSignal("ViewportSize"):Connect(updatePositions)

-- ======================== AIMBOT STATE ========================
local aiming = false
local currentTarget = nil

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end
	if Settings.Enabled and input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = false
	end
end)

-- ======================== MAIN LOOP (Drawing + Aiming) ========================
RunService.RenderStepped:Connect(function()
	updatePositions()
	fovCircle.Radius = Settings.FOVRadius

	local target, screenPos = getTarget()
	currentTarget = target

	if target and screenPos then
		-- Target inside FOV → green circle + show line
		fovCircle.Color = Color3.fromRGB(0, 255, 0)
		targetLine.Visible = true
		targetLine.To = screenPos
		targetLine.Color = Color3.fromRGB(255, 0, 0)
	else
		-- No target → yellow circle + hide line
		fovCircle.Color = Color3.fromRGB(255, 255, 0)
		targetLine.Visible = false
	end

	if aiming and Settings.Enabled and target then
		cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
	end
end)

-- ======================== OBSIDIAN UI ========================
local MainGroup = Tabs.Main:AddLeftGroupbox("Aimbot Settings")
MainGroup:AddToggle("Enable", {
	Text = "Enable Silent Aim",
	Default = Settings.Enabled,
	Callback = function(v)
		Settings.Enabled = v
	end,
})
MainGroup:AddSlider("FOVRadius", {
	Text = "FOV Radius",
	Default = Settings.FOVRadius,
	Min = 50,
	Max = 500,
	Rounding = 0,
	Suffix = "px",
	Callback = function(v)
		Settings.FOVRadius = v
		fovCircle.Radius = v
	end,
})
MainGroup:AddToggle("WallCheck", {
	Text = "Wall Check",
	Default = Settings.WallCheck,
	Callback = function(v)
		Settings.WallCheck = v
	end,
})

local RightGroup = Tabs.Main:AddRightGroupbox("Controls")
RightGroup:AddLabel("Hold Right Mouse Button to aim")
RightGroup:AddLabel(isMobile and "(Tap & hold on mobile)" or "(Right-click)")

-- UI Settings tab
local UIGroup = Tabs.UISettings:AddLeftGroupbox("Menu")
UIGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(v)
		Library.ShowCustomCursor = v
	end,
})
UIGroup:AddSlider("CornerRadius", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(v)
		Window:SetCornerRadius(v)
	end,
})
local keypicker = UIGroup:AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	Text = "Menu Keybind",
})
Library.ToggleKeybind = keypicker

UIGroup:AddToggle("ShowFOVCircle", {
	Text = "Show FOV Circle",
	Default = true,
	Callback = function(v)
		fovCircle.Visible = v
	end,
})
UIGroup:AddToggle("ShowTargetLine", {
	Text = "Show Target Line",
	Default = true,
	Callback = function(v)
		if not v then
			targetLine.Visible = false
		elseif currentTarget then
			targetLine.Visible = true
		end
	end,
})

UIGroup:AddButton("Unload Script", function()
	fovCircle:Remove()
	targetLine:Remove()
	Library:Unload()
end)

-- Theme & Save
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("SilentAim")
SaveManager:SetFolder("SilentAim")
SaveManager:BuildConfigSection(Tabs.UISettings)
ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()

Library:Notify({
	Title = "Silent Aim",
	Description = "UI ready. Circle = yellow (no target) / green (target in FOV). Line appears on target.",
	Time = 3,
})
