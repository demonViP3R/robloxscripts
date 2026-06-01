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
local GS: GuiService       = cloneref(game:GetService("GuiService"))
local RS: ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players: Players      = cloneref(game:GetService("Players"))
local UIS: UserInputService = cloneref(game:GetService("UserInputService"))

local plr       = Players.LocalPlayer
local cam       = workspace.CurrentCamera
local isMobile  = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled

-- ─────────────────────────────────────────────
-- GUI host
-- ─────────────────────────────────────────────
local _ = cloneref(game:GetService("CoreGui"))
local hui = _:FindFirstChild("RobloxGui") or _
if gethui then
	local s, r = pcall(gethui)
	if s then hui = cloneref(r) end
end

-- ─────────────────────────────────────────────
-- Executor compatibility check
-- ─────────────────────────────────────────────
local SG        = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-notifications/refs/heads/main/unrestricted_main.luau"))()
local Drawlib   = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/lib.luau"))()
local info      = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/info.luau"))()
local get_id    = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/get_id.luau"))()



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

	local dir                    = part.Position - origin
	local result: RaycastResult  = workspace:Raycast(origin, dir, rp)
	if not result then return true, nil end
	if result.Instance:IsDescendantOf(part.Parent) then return true, result.Instance end
	return false, result.Instance
end

-- ─────────────────────────────────────────────
-- Target selection (with sticky memory)
-- ─────────────────────────────────────────────
local lastTarget     = nil
local lastTargetTime = 0
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
			cPart        = tPart
			cDistance    = distance
			lastTarget   = player
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
-- FOV UI  (inlined from script 1)
-- ─────────────────────────────────────────────
local function buildUI(sFOV: number, tFunc: (origin: Vector3?) -> (Model | BasePart)?, mCenter: boolean?)
	SG["info"]("Loading UI...")

	if getgenv()[key] then
		if getgenv()[key]["draw_instance"] and getgenv()[key]["connections"] and getgenv()[key]["p_instance"] then
			getgenv()[key]["draw_instance"]:terminate()
			for _, v in next, getgenv()[key]["connections"] do v:Disconnect() end
			table.clear(getgenv()[key]["connections"])
			getgenv()[key]["p_instance"]:Destroy()
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
	local on   = true

	local p = Instance.new("ScreenGui", hui)
	p.Name  = code(p:GetDebugId())

	local menu                  = Instance.new("CanvasGroup", p)
	menu.Name                   = code(menu:GetDebugId())
	menu.AnchorPoint            = Vector2.new(0.5, 0.5)
	menu.Position               = UDim2.new(0.5, 0, 0.5, 0)
	menu.Size                   = UDim2.new(0.3, 0, getgenv().fov and 0.5 or 0.3, 0)
	menu.BackgroundColor3       = Color3.fromRGB(25, 25, 25)
	menu.BorderMode             = Enum.BorderMode.Outline
	menu.BorderColor3           = Color3.fromRGB(50, 25, 25)
	menu.BorderSizePixel        = 3
	menu.Active                 = true
	menu.Draggable              = true
	menu.ClipsDescendants       = true

	local external_close        = Instance.new("ImageButton", p)
	external_close.Name         = code(external_close:GetDebugId())
	external_close.AnchorPoint  = Vector2.new(0, 0.5)
	external_close.Position     = UDim2.new(0, 0, 0.5, 0)
	external_close.Size         = UDim2.new(0, 64, 0, 64)
	external_close.BackgroundTransparency = 1
	external_close.Image        = get_id("close")
	external_close.Visible      = GS.MenuIsOpen

	local top                   = Instance.new("Frame", menu)
	top.Name                    = code(top:GetDebugId())
	top.AnchorPoint             = Vector2.new(0.5, 0)
	top.Position                = UDim2.new(0.5, 0, 0, 0)
	top.Size                    = UDim2.new(1, 0, 0.5, 0)
	top.BackgroundTransparency  = 1

	local drag                  = Instance.new("TextLabel", top)
	drag.Name                   = code(drag:GetDebugId())
	drag.AnchorPoint            = Vector2.new(0.5, 0.5)
	drag.Position               = UDim2.new(0.5, 0, 0.5, 0)
	drag.Size                   = UDim2.new(0.3, 0, 0.3, 0)
	drag.BackgroundTransparency = 1
	drag.TextScaled             = true
	drag.TextColor3             = Color3.new(1, 1, 1)
	drag.Text                   = "HOLD TO DRAG"

	local logo                  = Instance.new("ImageButton", top)
	logo.Name                   = code(logo:GetDebugId())
	logo.Size                   = UDim2.new(0, 64, 0, 64)
	logo.BackgroundTransparency = 1
	logo.Image                  = get_id("logo")

	local internal_close        = Instance.new("ImageButton", top)
	internal_close.Name         = code(internal_close:GetDebugId())
	internal_close.AnchorPoint  = Vector2.new(1, 0)
	internal_close.Position     = UDim2.new(1, 0)
	internal_close.Size         = UDim2.new(0, 64, 0, 64)
	internal_close.BackgroundTransparency = 1
	internal_close.Image        = get_id("close")

	local bottom                = Instance.new("Frame", menu)
	bottom.Name                 = code(bottom:GetDebugId())
	bottom.AnchorPoint          = Vector2.new(0.5, 1)
	bottom.Position             = UDim2.new(0.5, 0, 1, 0)
	bottom.Size                 = UDim2.new(1, 0, 0.5, 0)
	bottom.BackgroundTransparency = 1

	local fov_adjust
	if getgenv().fov then
		local fov_txt               = Instance.new("TextLabel", bottom)
		fov_txt.Name                = code(fov_txt:GetDebugId())
		fov_txt.Size                = UDim2.new(0.5, 0, 0.5, 0)
		fov_txt.BorderMode          = Enum.BorderMode.Outline
		fov_txt.BorderColor3        = Color3.new(1, 1, 1)
		fov_txt.BorderSizePixel     = 5
		fov_txt.BackgroundTransparency = 1
		fov_txt.TextScaled          = true
		fov_txt.TextColor3          = Color3.new(1, 1, 1)
		fov_txt.Text                = "FOV Size:"

		fov_adjust                  = Instance.new("TextBox", bottom)
		fov_adjust.Name             = code(fov_adjust:GetDebugId())
		fov_adjust.AnchorPoint      = Vector2.new(1, 0)
		fov_adjust.Position         = UDim2.new(1, 0, 0, 0)
		fov_adjust.Size             = UDim2.new(0.5, 0, 0.5, 0)
		fov_adjust.BorderMode       = Enum.BorderMode.Outline
		fov_adjust.BorderColor3     = Color3.new(1, 1, 1)
		fov_adjust.BorderSizePixel  = 5
		fov_adjust.BackgroundTransparency = 1
		fov_adjust.TextScaled       = true
		fov_adjust.TextColor3       = Color3.new(1, 1, 1)
		fov_adjust.Text             = tostring(getgenv().fov)
	end

	local toggle = Instance.new("TextButton", bottom)
	toggle.Name  = code(toggle:GetDebugId())
	do
		local tmp           = fov_adjust and 1 or 0.5
		toggle.AnchorPoint  = Vector2.new(0.5, tmp)
		toggle.Position     = UDim2.new(0.5, 0, tmp, 0)
	end
	toggle.Size             = UDim2.new(1, 0, fov_adjust and 0.5 or 1, 0)
	toggle.BackgroundColor3 = on and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	toggle.TextScaled       = true
	toggle.Text             = on and "FOV Enabled" or "FOV Disabled"


	local _toggle = function()
		on                      = not on
		toggle.BackgroundColor3 = on and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		toggle.Text             = on and "FOV Enabled" or "FOV Disabled"
		if on then draw:start() else draw:stop() end
	end

	local e_close = function()
		if GS.MenuIsOpen then
			external_close.Visible = not menu.Visible
		else
			external_close.Visible = false
		end
	end

	local i_close = function()
		menu.Visible = not menu.Visible
		if not menu.Visible then
			SG["info"]("FOV Menu closed, enter the escape menu and press the X button on the left to reopen the FOV Menu.")
			if GS.MenuIsOpen then external_close.Visible = true end
		else
			external_close.Visible = false
		end
	end

	getgenv()[key] = {
		["draw_instance"] = draw,
		["connections"] = {
			GS.MenuOpened:Connect(e_close),
			GS.MenuClosed:Connect(e_close),

			fov_adjust and fov_adjust.FocusLost:Connect(function(ep)
				if isMobile or ep then
					local fov = tonumber(fov_adjust.Text)
					if not fov then
						fov_adjust.Text = tostring(getgenv().fov)
						return
					end
					getgenv().fov = fov
					draw:set(fov)
				end
			end) or nil,

			external_close.MouseButton1Up:Connect(i_close),
			toggle.MouseButton1Up:Connect(_toggle),
			internal_close.MouseButton1Up:Connect(i_close),
			external_close.TouchTap:Connect(i_close),
			toggle.TouchTap:Connect(_toggle),
			internal_close.TouchTap:Connect(i_close),
		},
		["p_instance"] = p,
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
