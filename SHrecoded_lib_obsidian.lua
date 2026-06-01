if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- ─────────────────────────────────────────────
-- Shared utilities
-- ─────────────────────────────────────────────
local cloneref = cloneref or function(i: Instance)
	return i
end
local clonefunction = clonefunction or function(f: (...any) -> ...any)
	return f
end
local newcclosure = newcclosure or clonefunction
local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "Your executor"

if not (hookfunction and require) then
	local err = executor
		.. " is missing "
		.. (not hookfunction and "hookfunction " or "")
		.. (not require and "require" or "")
	print("error: " .. err)
	return error(err)
end

-- ─────────────────────────────────────────────
-- Services
-- ─────────────────────────────────────────────
local RS: ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players: Players      = cloneref(game:GetService("Players"))
local UIS: UserInputService = cloneref(game:GetService("UserInputService"))

local plr      = Players.LocalPlayer
local cam      = workspace.CurrentCamera
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled

-- ─────────────────────────────────────────────
-- Sneeky libs + Obsidian
-- ─────────────────────────────────────────────
local Drawlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/demonViP3R/robloxscripts/refs/heads/main/drawlib.luau"))()

local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(ObsidianRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(ObsidianRepo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(ObsidianRepo .. "addons/SaveManager.lua"))()
local Options      = Library.Options
local Toggles      = Library.Toggles


-- ─────────────────────────────────────────────
-- FastCast require
-- ─────────────────────────────────────────────
local s, ac = pcall(require, RS.BulletFireSystem.FastCastRedux.ActiveCast)
if not s then
	return warn(
		executor .. " returned an error while trying to require RS.BulletFireSystem.FastCastRedux.ActiveCast:\n" .. ac
	)
end

local gs, lps = workspace:FindFirstChild("Game Systems"), workspace:FindFirstChild("LocalPartStorage")
if not (gs and lps) then
	local err = "Script needs updating"
	print("error: " .. err)
	return warn(err)
end

-- ─────────────────────────────────────────────
-- Visibility / wall-check
-- ─────────────────────────────────────────────
local rp = RaycastParams.new()
rp.FilterType  = Enum.RaycastFilterType.Exclude
rp.IgnoreWater = true

local isVisible = function(part: BasePart, origin: Vector3): (boolean, Instance?)
	local char = plr.Character
	if not (char and part) then
		return false, nil
	end

	rp.FilterDescendantsInstances = {
		char,
		lps,
		gs:FindFirstChild("ACS_WorkSpace"),
		gs:FindFirstChild("Boat Workspace"),
		gs:FindFirstChild("Tank Workspace"),
		gs:FindFirstChild("Vehicle Workspace"),
		gs:FindFirstChild("Helicopter Workspace"),
		gs:FindFirstChild("Hovercraft Workspace"),
		gs:FindFirstChild("Plane Workspace"),
		gs:FindFirstChild("Gunship Workspace"),
		gs:FindFirstChild("Submarine Workspace"),
		gs:FindFirstChild("FireDamage"),
	}

	local dir                   = part.Position - origin
	local result: RaycastResult = workspace:Raycast(origin, dir, rp)
	if not result then return true, nil end
	if result.Instance:IsDescendantOf(part.Parent) then return true, result.Instance end
	return false, result.Instance
end

-- ─────────────────────────────────────────────
-- Target selection (with sticky memory)
-- ─────────────────────────────────────────────
local lastTarget      = nil
local lastTargetTime  = 0
local STICKY_DURATION = 0.5

local getTarget = function(origin: Vector3)
	local cPart, cDistance = nil, getgenv().fov or 300

	for _, player: Player in next, Players:GetPlayers() do
		if player == plr then continue end

		local char = player.Character
		if
			not char
			or char:FindFirstChildOfClass("ForceField")
			or (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0)
		then
			continue
		end

		local tPart: BasePart = char:FindFirstChild("Head")
			or char.PrimaryPart
			or char:FindFirstChild("HumanoidRootPart")
		if not tPart then continue end

		local pos, onScreen = cam:WorldToViewportPoint(tPart.Position)
		if not onScreen then continue end

		if getgenv().wallcheck then
			local v, nTPart = isVisible(tPart, origin)
			if not v then
				v, nTPart = isVisible(char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"), origin)
				if not v then continue end
			end
			if nTPart then tPart = nTPart end
		end

		local distance = (
			Vector2.new(pos.X, pos.Y)
			- (
				isMobile
					and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
				or UIS:GetMouseLocation()
			)
		).Magnitude

		if distance < cDistance then
			cPart          = tPart
			cDistance      = distance
			lastTarget     = player
			lastTargetTime = os.clock()
		end
	end

	-- Sticky: reuse last target briefly after it leaves FOV
	if not cPart and lastTarget and (os.clock() - lastTargetTime) < STICKY_DURATION then
		local char = lastTarget.Character
		if
			char
			and not char:FindFirstChildOfClass("ForceField")
			and char:FindFirstChild("Humanoid")
			and char.Humanoid.Health > 0
		then
			local tPart = char:FindFirstChild("Head") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
			if tPart then
				cPart = tPart
			end
		else
			lastTarget = nil
		end
	end

	return cPart
end

-- ─────────────────────────────────────────────
-- FOV UI  (Obsidian)
-- ─────────────────────────────────────────────
local function buildUI(sFOV: number, tFunc: (origin: Vector3?) -> (Model | BasePart)?, mCenter: boolean?)

	-- Clean up any previous instance of this script
	if getgenv()[key] then
		if getgenv()[key]["draw_instance"] and getgenv()[key]["connections"] then
			getgenv()[key]["draw_instance"]:terminate()
			for _, v in next, getgenv()[key]["connections"] do
				if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
			end
			table.clear(getgenv()[key]["connections"])
			if getgenv()[key]["unload"] then
				pcall(getgenv()[key]["unload"])
			end
			table.clear(getgenv()[key])
			getgenv()[key] = nil
		else
			plr:Kick(
				"Don't tamper with that getgenv key. If you believe this kick a mistake please join the Discord server and report it!\nDiscord Server Link: "
					.. discord_link
			)
		end
	end

	local draw = Drawlib.new(getgenv().fov or sFOV, tFunc, mCenter)

	-- ── Obsidian window ──────────────────────────────────────────────
	local Window = Library:CreateWindow({
		Title      = "Silent Aim",
		AutoShow   = true,
		NotifySide = "Right",
		ShowCustomCursor = true,
	})

	local Tabs = {
		Main         = Window:AddTab("Main", "crosshair"),
		["Settings"] = Window:AddTab("Settings", "settings"),
	}

	-- ── Main tab ─────────────────────────────────────────────────────
	local AimGroup = Tabs.Main:AddLeftGroupbox("Aimbot", "target")

	-- FOV toggle
	AimGroup:AddToggle("FovEnabled", {
		Text    = "Enable FOV",
		Default = true,
		Tooltip = "Toggles the FOV circle and silent aim",
		Callback = function(val)
			if val then draw:start() else draw:stop() end
		end,
	})

	-- Wall check toggle
	AimGroup:AddToggle("WallCheck", {
		Text    = "Wall Check",
		Default = getgenv().wallcheck or false,
		Tooltip = "Only aim at players that are visible through walls",
		Callback = function(val)
			getgenv().wallcheck = val
		end,
	})

	-- FOV size slider
	local defaultFov = getgenv().fov or sFOV or 300
	AimGroup:AddSlider("FovSize", {
		Text    = "FOV Size",
		Default = defaultFov,
		Min     = 10,
		Max     = 500,
		Rounding = 0,
		Suffix  = " px",
		Tooltip = "Radius of the FOV circle in pixels",
		Callback = function(val)
			getgenv().fov = val
			draw:set(val)
		end,
	})

	-- ── Settings tab ─────────────────────────────────────────────────
	local MenuGroup = Tabs["Settings"]:AddLeftGroupbox("Menu", "wrench")

	MenuGroup:AddToggle("ShowCustomCursor", {
		Text    = "Custom Cursor",
		Default = true,
		Callback = function(val)
			Library.ShowCustomCursor = val
		end,
	})

	MenuGroup:AddDropdown("NotificationSide", {
		Values  = { "Left", "Right" },
		Default = "Right",
		Text    = "Notification Side",
		Callback = function(val)
			Library:SetNotifySide(val)
		end,
	})

	MenuGroup:AddDivider()
	MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
		Default = "RightShift",
		NoUI    = true,
		Text    = "Toggle Menu",
	})

	MenuGroup:AddButton({
		Text = "Unload",
		Risky = true,
		Func = function()
			Library:Unload()
		end,
	})

	Library.ToggleKeybind = Options.MenuKeybind

	-- Addons
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
	ThemeManager:SetFolder("SilentAim")
	SaveManager:SetFolder("SilentAim")
	ThemeManager:ApplyToTab(Tabs["Settings"])
	SaveManager:BuildConfigSection(Tabs["Settings"])
	SaveManager:LoadAutoloadConfig()

	Library:OnUnload(function()
		draw:terminate()
		if getgenv()[key] then
			table.clear(getgenv()[key])
			getgenv()[key] = nil
		end
	end)

	-- ── Sync initial getgenv state with Obsidian toggle values ────────
	Toggles.FovEnabled:OnChanged(function()
		if Toggles.FovEnabled.Value then draw:start() else draw:stop() end
	end)

	Toggles.WallCheck:OnChanged(function()
		getgenv().wallcheck = Toggles.WallCheck.Value
	end)

	Options.FovSize:OnChanged(function()
		getgenv().fov = Options.FovSize.Value
		draw:set(Options.FovSize.Value)
	end)

	-- ── Store cleanup handles ─────────────────────────────────────────
	getgenv()[key] = {
		["draw_instance"] = draw,
		["connections"]   = {},
		["unload"]        = function() Library:Unload() end,
	}

	draw:start()
end

-- ─────────────────────────────────────────────
-- Launch UI
-- ─────────────────────────────────────────────
buildUI(getgenv().fov or 300, getTarget, true)

-- ─────────────────────────────────────────────
-- FastCast hook (silent aim)
-- ─────────────────────────────────────────────
local old
old = clonefunction(hookfunction(
	rawget(ac, "new"),
	newcclosure(function(_, origin, __, ___, ...)
		local c = getTarget(origin)
		if c then
			local dir = c.Position - origin
			return old(_, origin, dir, dir.Unit * 9e9, ...)
		end
		return old(_, origin, __, ___, ...)
	end)
))
