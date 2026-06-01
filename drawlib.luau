local cloneref = cloneref or function(i: Instance) return i; end;

local RS: RunService = cloneref(game:GetService("RunService"));
local UIS: UserInputService = cloneref(game:GetService("UserInputService"));
local _ = cloneref(game:GetService("CoreGui"));
local hui = _:FindFirstChild("RobloxGui") or _;
if gethui then local s, r = pcall(gethui); if s then hui = cloneref(r); end; end;

local cam = workspace.CurrentCamera;

local code = function(n: string): string
    if crypt and crypt.base64encode then
        return crypt.base64encode(n);
    end;
    return n;
end;

local DrawLib = {};
DrawLib.__index = DrawLib;

function DrawLib.new(sFOV: number, tFunc: (origin: Vector3?) -> (Model | BasePart)?, mCenter: boolean?)
    local self = setmetatable({}, DrawLib);
    self.size = sFOV;
    self.func = tFunc;
    self.on = false;
    self.center = mCenter and (UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled);
    --self.p = nil;

    if DrawingImmediate then
        self.signal = DrawingImmediate.GetPaint(1);
    elseif Drawing and cleardrawcache then
        self.fov = Drawing.new("Circle");
        self.fov.Color = Color3.new(1, 0, 0);
        self.fov.Radius = self.size;
        self.fov.Thickness = 1;
        self.fov.Transparency = 1;
        self.fov.Filled = false;
        self.fov.NumSides = 256;
        self.fov.Visible = self.on;

        self.line = Drawing.new("Line");
        self.line.Thickness = 2;
        self.line.Color = Color3.new(1, 0, 0);
        self.line.Transparency = 0.5;
        self.line.Visible = self.on;
    else
        self.p = Instance.new("ScreenGui", hui);
        self.p.Name = code(self.p:GetDebugId());

        do
            self.fov = Instance.new("Frame", self.p);
            self.fov.Name = code(self.p:GetDebugId());
            self.fov.AnchorPoint = Vector2.new(0.5, 0.5);
            self.fov.Size = UDim2.new(0, self.size*2, 0, self.size*2);
            self.fov.Position = UDim2.new(0, 0);
            self.fov.Transparency = 1;
            self.fov.Visible = self.on;

            local _ = Instance.new("UICorner", self.fov);
            _.Name = code(_:GetDebugId());
            _.CornerRadius = UDim.new(1, 0);

            local __ = Instance.new("UIStroke", self.fov);
            __.Name = code(__:GetDebugId());
            __.Color = Color3.new(1, 0, 0);
            __.Thickness = 1;
            __.LineJoinMode = Enum.LineJoinMode.Round;
            __.Transparency = 0;
        end;

        do
            self.line = Instance.new("Frame", self.p);
            self.line.Name = code(self.line:GetDebugId());
            self.line.AnchorPoint = Vector2.new(0.5, 0.5);
            self.line.Size = UDim2.new(0, 0);
            self.line.Position = UDim2.new(0, 0);
            self.line.Transparency = 0.5;
            self.line.Visible = self.on;

            local _ = Instance.new("UIStroke", self.line);
            _.Name = code(_:GetDebugId());
            _.Color = Color3.new(1, 0, 0);
            _.Thickness = 1;
            _.LineJoinMode = Enum.LineJoinMode.Round;
            _.Transparency = 0.5;
        end;
    end;

    local cSet = function(isGreen: boolean)
        if self.p then
            self.fov:FindFirstChildOfClass("UIStroke").Color = isGreen and Color3.new(0, 1, 0) or Color3.new(1, 0, 0);
        elseif self.signal then
            return isGreen and Color3.new(0, 1, 0) or Color3.new(1, 0, 0);
        else
            self.fov.Color = isGreen and Color3.new(0, 1, 0) or Color3.new(1, 0, 0);
        end;
    end;

    self.connection = self.signal and (self.signal::RBXScriptSignal):Connect(function()
        if self.on then
            local pos = self.center and Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) or UIS:GetMouseLocation();
            local cam = workspace.CurrentCamera;
            local set = false;

            local c = self.func(cam.CFrame.Position);
            if c then
                local p, onScreen = cam:WorldToViewportPoint(c:IsA("Model") and c:GetPivot().Position or c.Position);
                if onScreen then
                    p = Vector2.new(p.X, p.Y);
                    DrawingImmediate.Line(pos, p, Color3.new(1, 0, 0), 1, 2);
                    set = true;
                else
                    set = false;
                end;
            else
                set = false;
            end;
            DrawingImmediate.Circle(pos, self.size, cSet(set), 1, 256, 1);
        end;
    end) or RS.RenderStepped:Connect(function()
        if self.on then
            local pos = self.center and Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) or UIS:GetMouseLocation();
            local cam = workspace.CurrentCamera;

            if self.fov then
                if self.p then
                    self.fov.Position = UDim2.new(0, pos.X, 0, pos.Y);
                    self.Size = UDim2.new(0, self.size*2, 0, self.size*2);
                else
                    self.fov.Position = pos;
                    self.fov.Radius = self.size;
                end;
                self.fov.Visible = true;
            end;

            if self.line then
                local c = self.func(cam.CFrame.Position);
                if c then
                    local p, onScreen = cam:WorldToViewportPoint(c:IsA("Model") and c:GetPivot().Position or c.Position);
                    if onScreen then
                        p = Vector2.new(p.X, p.Y);
                        if self.p then
                            local npos = (pos + p) / 2;
                            local l = (pos - p).Magnitude;
                            local a = math.atan2(p.Y - pos.Y, p.X - pos.X);

                            self.line.Position = UDim2.fromOffset(npos.X, npos.Y);
                            self.line.Size = UDim2.fromOffset(l, 0);
                            self.line.Rotation = math.deg(a);
                        else
                            self.line.From = pos;
                            self.line.To = p;
                        end;
                        self.line.Visible = true;
                        cSet(true);
                        return;
                    end;
                    return;
                end;
                self.line.Visible = false;
                cSet(false);
            end;
        else
            self.fov.Visible = false;
            self.line.Visible = false;
            cSet(false);
        end;
    end);
    
    return self;
end;

function DrawLib:set(sFOV: number)
    self.size = sFOV;
end;

function DrawLib:start()
    self.on = true;
end;

function DrawLib:stop()
    self.on = false;
end;

function DrawLib:terminate()
    self.on = nil;
    if self.connection then self.connection:Disconnect(); self.connection = nil; end;
    if self.p then
        self.p:Destroy();
        self.p = nil;
        if self.fov then self.fov:Destroy(); self.fov = nil; end;
        if self.line then self.line:Destroy(); self.line = nil; end;
    elseif self.signal then
        self.signal = nil;
    else
        cleardrawcache();
    end;
end;

return DrawLib;