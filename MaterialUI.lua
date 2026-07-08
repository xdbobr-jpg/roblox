local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local CoreGui = (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")

local secureMode = false
if getgenv then
	local ok, result = pcall(function()
		return getgenv().MATERIAL3_SECURE
	end)
	if ok and result then
		secureMode = true
	end
end

if secureMode then
	local rawPrint = print
	local rawWarn = warn
	local rawError = error
	print = function(...)
		return secureMode and nil or rawPrint(...)
	end
	warn = function(...)
		return secureMode and nil or rawWarn(...)
	end
	error = function(message, level)
		if secureMode then
			return rawError("", (level or 1) + 1)
		end
		return rawError(message, level)
	end
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	error("Material3 requires LocalPlayer")
end

local function getEnv()
	if getgenv then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" then
			return env
		end
	end
	return shared
end

local GENV = getEnv()
if GENV and GENV.Material3Active and type(GENV.Material3Active.Destroy) == "function" then
	pcall(function()
		GENV.Material3Active:Destroy()
	end)
end
local function safeCallback(callback, ...)
	if type(callback) ~= "function" then
		return true
	end
	local function onError()
		return ""
	end
	return xpcall(callback, onError, ...)
end

local function fileExists(path)
	return (isfile and isfile(path)) or false
end

local function ensureFolder(path)
	if makefolder and not isfolder(path) then
		pcall(makefolder, path)
	end
end

local function readJsonFile(path, fallback)
	if not fileExists(path) or not readfile then
		return fallback
	end
	local ok, raw = pcall(readfile, path)
	if not ok or type(raw) ~= "string" or raw == "" then
		return fallback
	end
	local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	return decodeOk and decoded or fallback
end

local function writeJsonFile(path, data)
	if not writefile then
		return false
	end
	local encoded = HttpService:JSONEncode(data)
	return pcall(writefile, path, encoded)
end

local function loadConfigValue(path, flag)
	local decoded = readJsonFile(path, {})
	return decoded and decoded[flag] or nil
end

local function serializeValue(value)
	local t = typeof(value)
	if t == "Color3" then
		return { __type = "Color3", R = math.floor(value.R * 255 + 0.5), G = math.floor(value.G * 255 + 0.5), B = math.floor(value.B * 255 + 0.5) }
	elseif t == "EnumItem" then
		return { __type = "EnumItem", EnumType = value.EnumType.Name, Name = value.Name }
	elseif t == "table" then
		local out = {}
		for k, v in pairs(value) do
			out[k] = serializeValue(v)
		end
		return out
	end
	return value
end

local function deserializeValue(value)
	if type(value) ~= "table" then
		return value
	end
	if value.__type == "Color3" then
		return Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255)
	elseif value.__type == "EnumItem" and value.EnumType == "KeyCode" and value.Name then
		return Enum.KeyCode[value.Name]
	end
	local out = {}
	for k, v in pairs(value) do
		if k ~= "__type" then
			out[k] = deserializeValue(v)
		end
	end
	return out
end

local function setZIndexDeep(root, zIndex)
	if not root then
		return
	end
	local function apply(node)
		if node:IsA("GuiObject") or node:IsA("UIStroke") or node:IsA("UIGradient") then
			pcall(function()
				node.ZIndex = zIndex
			end)
		end
		for _, child in ipairs(node:GetChildren()) do
			apply(child)
		end
	end
	apply(root)
end

local function bumpWindowZ(root, library)
	if not library then
		return
	end
	library.CurrentZIndex = (library.CurrentZIndex or 100) + 5
	setZIndexDeep(root, library.CurrentZIndex)
end

local Material3 = {}
Material3.__index = Material3
Material3.SecureMode = secureMode
Material3.ActiveWindow = nil

local TOKENS = {
	colors = {
		dark = {
			primary = Color3.fromRGB(203, 190, 255),
			onPrimary = Color3.fromRGB(52, 0, 152),
			primaryContainer = Color3.fromRGB(75, 33, 189),
			onPrimaryContainer = Color3.fromRGB(234, 221, 255),
			secondary = Color3.fromRGB(196, 194, 222),
			onSecondary = Color3.fromRGB(46, 47, 65),
			secondaryContainer = Color3.fromRGB(68, 69, 88),
			onSecondaryContainer = Color3.fromRGB(220, 218, 245),
			tertiary = Color3.fromRGB(239, 184, 200),
			onTertiary = Color3.fromRGB(74, 37, 50),
			tertiaryContainer = Color3.fromRGB(99, 59, 73),
			onTertiaryContainer = Color3.fromRGB(255, 216, 228),
			error = Color3.fromRGB(255, 180, 171),
			onError = Color3.fromRGB(105, 0, 5),
			errorContainer = Color3.fromRGB(147, 0, 10),
			onErrorContainer = Color3.fromRGB(255, 218, 214),
			background = Color3.fromRGB(19, 18, 20),
			onBackground = Color3.fromRGB(230, 225, 227),
			surface = Color3.fromRGB(19, 18, 20),
			surfaceContainerLowest = Color3.fromRGB(14, 13, 15),
			surfaceContainerLow = Color3.fromRGB(28, 27, 29),
			surfaceContainer = Color3.fromRGB(32, 31, 33),
			surfaceContainerHigh = Color3.fromRGB(42, 41, 43),
			surfaceContainerHighest = Color3.fromRGB(53, 52, 54),
			onSurface = Color3.fromRGB(230, 225, 227),
			onSurfaceVariant = Color3.fromRGB(202, 196, 208),
			outline = Color3.fromRGB(146, 143, 148),
			outlineVariant = Color3.fromRGB(77, 74, 81),
			inverseSurface = Color3.fromRGB(230, 225, 227),
			inverseOnSurface = Color3.fromRGB(48, 48, 48),
			scrim = Color3.fromRGB(0, 0, 0),
			shadow = Color3.fromRGB(0, 0, 0),
		},
		light = {
			primary = Color3.fromRGB(100, 66, 214),
			onPrimary = Color3.fromRGB(255, 255, 255),
			primaryContainer = Color3.fromRGB(159, 134, 255),
			onPrimaryContainer = Color3.fromRGB(30, 0, 96),
			secondary = Color3.fromRGB(93, 93, 116),
			onSecondary = Color3.fromRGB(255, 255, 255),
			secondaryContainer = Color3.fromRGB(220, 218, 245),
			onSecondaryContainer = Color3.fromRGB(33, 24, 43),
			tertiary = Color3.fromRGB(125, 82, 96),
			onTertiary = Color3.fromRGB(255, 255, 255),
			tertiaryContainer = Color3.fromRGB(241, 211, 249),
			onTertiaryContainer = Color3.fromRGB(39, 20, 48),
			error = Color3.fromRGB(179, 38, 30),
			onError = Color3.fromRGB(255, 255, 255),
			errorContainer = Color3.fromRGB(249, 222, 220),
			onErrorContainer = Color3.fromRGB(65, 14, 11),
			background = Color3.fromRGB(254, 251, 255),
			onBackground = Color3.fromRGB(28, 27, 29),
			surface = Color3.fromRGB(254, 251, 255),
			surfaceContainerLowest = Color3.fromRGB(255, 255, 255),
			surfaceContainerLow = Color3.fromRGB(248, 241, 246),
			surfaceContainer = Color3.fromRGB(242, 236, 238),
			surfaceContainerHigh = Color3.fromRGB(236, 231, 233),
			surfaceContainerHighest = Color3.fromRGB(230, 225, 227),
			onSurface = Color3.fromRGB(28, 27, 29),
			onSurfaceVariant = Color3.fromRGB(77, 66, 86),
			outline = Color3.fromRGB(120, 117, 121),
			outlineVariant = Color3.fromRGB(200, 196, 199),
			inverseSurface = Color3.fromRGB(48, 48, 48),
			inverseOnSurface = Color3.fromRGB(245, 239, 241),
			scrim = Color3.fromRGB(0, 0, 0),
			shadow = Color3.fromRGB(0, 0, 0),
		},
	},
	stateOpacity = {
		hover = 0.08,
		focus = 0.12,
		pressed = 0.12,
		dragged = 0.16,
		disabledContent = 0.38,
		disabledContainer = 0.12,
	},
	typeScale = {
		headlineSmall = { size = 22, weight = Enum.FontWeight.Medium },
		titleLarge = { size = 20, weight = Enum.FontWeight.Regular },
		titleMedium = { size = 16, weight = Enum.FontWeight.Medium },
		bodyLarge = { size = 16, weight = Enum.FontWeight.Regular },
		bodyMedium = { size = 14, weight = Enum.FontWeight.Regular },
		bodySmall = { size = 12, weight = Enum.FontWeight.Regular },
		labelLarge = { size = 14, weight = Enum.FontWeight.Medium },
		labelMedium = { size = 12, weight = Enum.FontWeight.Medium },
	},
	font = {
		fallback = Enum.Font.BuilderSans,
	},
	radius = {
		small = UDim.new(0, 6),
		medium = UDim.new(0, 8),
		large = UDim.new(0, 12),
		extraLarge = UDim.new(0, 18),
		full = UDim.new(1, 0),
	},
	motion = {
		fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		normal = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		emphasized = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		expressive = TweenInfo.new(0.46, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
}

local function create(className, props)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	return instance
end

local function applyCorner(target, radius)
	local corner = target:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
	return corner
end

local function applyStroke(target, color, transparency, thickness)
	local stroke = target:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1
	stroke.Parent = target
	return stroke
end

local function applyPadding(target, top, right, bottom, left)
	local padding = target:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.Parent = target
	return padding
end

local function applyTextStyle(target, scaleName, color)
	local scale = TOKENS.typeScale[scaleName] or TOKENS.typeScale.bodyMedium
	if TOKENS.font.face then
		pcall(function()
			target.FontFace = TOKENS.font.face
		end)
	else
		target.Font = TOKENS.font.fallback
	end
	target.TextSize = scale.size
	target.TextColor3 = color
	target.TextWrapped = false
	target.TextTruncate = Enum.TextTruncate.AtEnd
	if target:IsA("TextButton") or target:IsA("TextLabel") or target:IsA("TextBox") then
		target.RichText = true
	end
end

local function createStateLayer(target, radius)
	local stateLayer = create("Frame", {
		Name = "StateLayer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = target.ZIndex + 1,
		Active = false,
	})
	applyCorner(stateLayer, radius)
	stateLayer.Parent = target
	return stateLayer
end

local tween

local function bindStateLayer(button, stateLayer, colorResolver)
	local function apply(alpha, animated)
		stateLayer.BackgroundColor3 = colorResolver()
		if animated == false then
			stateLayer.BackgroundTransparency = alpha
		else
			tween(stateLayer, TOKENS.motion.fast, {
				BackgroundTransparency = alpha,
			})
		end
	end

	button.MouseEnter:Connect(function()
		apply(1 - TOKENS.stateOpacity.hover, true)
	end)

	button.MouseLeave:Connect(function()
		apply(1, true)
	end)

	button.MouseButton1Down:Connect(function()
		apply(1 - TOKENS.stateOpacity.pressed, false)
	end)

	button.MouseButton1Up:Connect(function()
		apply(1 - TOKENS.stateOpacity.hover, false)
	end)

	apply(1, false)
end

function tween(object, info, props)
	local tw = TweenService:Create(object, info, props)
	tw:Play()
	return tw
end

local function shallowMerge(base, extra)
	local out = {}
	for k, v in pairs(base or {}) do
		out[k] = v
	end
	for k, v in pairs(extra or {}) do
		out[k] = v
	end
	return out
end

local function blendColor(a, b, t)
	t = math.clamp(t or 0, 0, 1)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function elevatedSurface(colors, weight)
	return blendColor(colors.surface, colors.primary, weight or 0.06)
end

local function formatValue(value)
	if math.abs(value % 1) < 0.001 then
		return tostring(math.floor(value + 0.5))
	end
	return string.format("%.2f", value)
end

local function colorToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.clamp(math.floor(color.R * 255 + 0.5), 0, 255),
		math.clamp(math.floor(color.G * 255 + 0.5), 0, 255),
		math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
	)
end

local function parseHexColor(text)
	if typeof(text) ~= "string" then
		return nil
	end

	local normalized = text:gsub("#", ""):upper()
	if #normalized ~= 6 or normalized:find("[^%x]") then
		return nil
	end

	local r = tonumber(normalized:sub(1, 2), 16)
	local g = tonumber(normalized:sub(3, 4), 16)
	local b = tonumber(normalized:sub(5, 6), 16)
	if not r or not g or not b then
		return nil
	end

	return Color3.fromRGB(r, g, b)
end

local function formatKeyCode(keyCode)
	if typeof(keyCode) ~= "EnumItem" or keyCode.EnumType ~= Enum.KeyCode then
		return "None"
	end

	local name = keyCode.Name
	name = name:gsub("Left", "L ")
	name = name:gsub("Right", "R ")
	name = name:gsub("Control", "Ctrl")
	return name
end

local function formatBindValue(bindValue)
	if typeof(bindValue) == "EnumItem" and bindValue.EnumType == Enum.KeyCode then
		return formatKeyCode(bindValue)
	end
	if type(bindValue) == "string" then
		return bindValue
	end
	return "None"
end

local function normalizeKeyCode(value)
	if value == nil then
		return nil
	end

	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
		return value
	end

	if typeof(value) == "string" then
		local normalized = value:gsub("%s+", "")
		local ok, result = pcall(function()
			return Enum.KeyCode[normalized]
		end)
		if ok then
			return result
		end
	end

	return nil
end

local function normalizeBindValue(value)
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
		return value
	end
	if typeof(value) == "EnumItem" and value.EnumType == Enum.UserInputType then
		return value.Name
	end
	if type(value) == "string" then
		local key = normalizeKeyCode(value)
		if key then
			return key
		end
		return value
	end
	return nil
end

local Window = {}
Window.__index = Window

local Page = {}
Page.__index = Page

local Section = {}
Section.__index = Section

local function safeGetUserThumbnail(userId)
	if secureMode then
		return ""
	end

	local ok, content = pcall(function()
		local image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		return image
	end)
	return ok and content or ""
end

local function getDisplayInitials()
	local source = LocalPlayer.DisplayName or LocalPlayer.Name or "M"
	local initials = {}

	for token in string.gmatch(source, "[%w_]+") do
		local first = token:sub(1, 1)
		if first ~= "" then
			table.insert(initials, string.upper(first))
		end
		if #initials >= 2 then
			break
		end
	end

	if #initials == 0 then
		return "M"
	end

	return table.concat(initials, "")
end

local function bindThemeUpdater(window, updater)
	window.ThemeUpdaters = window.ThemeUpdaters or {}
	table.insert(window.ThemeUpdaters, updater)
	return updater
end

local function ensureBlurEffect()
	local ok, blur = pcall(function()
		local existing = Lighting:FindFirstChild("Material3Blur")
		if existing and existing:IsA("BlurEffect") and existing.Parent == Lighting then
			return existing
		end
		local created = Instance.new("BlurEffect")
		created.Name = "Material3Blur"
		created.Size = 0
		created.Enabled = false
		created.Parent = Lighting
		return created
	end)
	return ok and blur or nil
end

function Material3.new(config)
	config = config or {}
	if GENV and GENV.Material3Active and type(GENV.Material3Active.Destroy) == "function" then
		pcall(function()
			GENV.Material3Active:Destroy()
		end)
	end
	local mode = config.Theme and config.Theme.mode or "dark"
	local colors = TOKENS.colors[mode] or TOKENS.colors.dark
	local configSettings = shallowMerge({
		SaveCurrentState = true,
		FolderName = "Admin_Suite_Configs",
		FileName = (config.Name or "Material3") .. ".json",
	}, config.ConfigSettings or {})
	local configFolder = configSettings.FolderName
	local configPath = configFolder .. "\\" .. configSettings.FileName

	local self = setmetatable({
		Mode = mode,
		Colors = colors,
		Theme = config.Theme or { mode = mode, acrylic = false },
		Flags = {},
		Connections = {},
		ThemeUpdaters = {},
		ConfigSettings = configSettings,
		ConfigPath = configPath,
		ConfigData = {},
		CurrentZIndex = 100,
	}, Material3)

	ensureFolder(configFolder)
	self.ConfigData = readJsonFile(configPath, {})

	local gui = create("ScreenGui", {
		Name = config.Name or "Material3",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = config.DisplayOrder or 1000,
		IgnoreGuiInset = false,
	})

	local root = create("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.54),
		BackgroundColor3 = elevatedSurface(colors, 0.06),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	applyCorner(root, TOKENS.radius.extraLarge)
	applyStroke(root, colors.outlineVariant, 0.68, 1)
	root.Parent = gui

	local surfaceTint = create("Frame", {
		Name = "SurfaceTint",
		Size = UDim2.new(1, 0, 0, 220),
		BackgroundColor3 = colors.primary,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 0,
	})
	applyCorner(surfaceTint, TOKENS.radius.extraLarge)
	surfaceTint.Parent = root

	local surfaceTintGradient = Instance.new("UIGradient")
	surfaceTintGradient.Rotation = 90
	surfaceTintGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	surfaceTintGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.72, 0.78),
		NumberSequenceKeypoint.new(1, 1),
	})
	surfaceTintGradient.Parent = surfaceTint

	local acrylicTint = create("Frame", {
		Name = "AcrylicTint",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = elevatedSurface(colors, 0.08),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Visible = false,
	})
	applyCorner(acrylicTint, TOKENS.radius.extraLarge)
	acrylicTint.Parent = root

	local acrylicGlow = create("Frame", {
		Name = "AcrylicGlow",
		Size = UDim2.new(1, 0, 0, 160),
		BackgroundColor3 = colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Visible = false,
	})
	applyCorner(acrylicGlow, TOKENS.radius.extraLarge)
	acrylicGlow.Parent = acrylicTint

	local acrylicGlowGradient = Instance.new("UIGradient")
	acrylicGlowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	acrylicGlowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.82),
		NumberSequenceKeypoint.new(1, 1),
	})
	acrylicGlowGradient.Rotation = 90
	acrylicGlowGradient.Parent = acrylicGlow

	local rescueHandle = create("TextButton", {
		Name = "RescueHandle",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(110, 18),
		BackgroundColor3 = colors.surfaceContainerHigh,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 100,
	})
	applyCorner(rescueHandle, TOKENS.radius.full)
	applyStroke(rescueHandle, colors.outlineVariant, 0.55, 1)
	rescueHandle.Parent = gui

	local rescueGrip = create("Frame", {
		Name = "Grip",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40, 4),
		BackgroundColor3 = colors.onSurfaceVariant,
		BackgroundTransparency = 0.24,
		BorderSizePixel = 0,
		ZIndex = 101,
	})
	applyCorner(rescueGrip, TOKENS.radius.full)
	rescueGrip.Parent = rescueHandle

	local notificationHost = create("Frame", {
		Name = "NotificationHost",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 50,
	})
	notificationHost.Parent = gui

	local notificationLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	notificationLayout.Parent = notificationHost

	local sizeConstraint = create("UISizeConstraint", {
		MinSize = Vector2.new(460, 300),
		MaxSize = Vector2.new(860, 620),
	})
	sizeConstraint.Parent = root

	local topBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = elevatedSurface(colors, 0.04),
		BorderSizePixel = 0,
	})
	applyPadding(topBar, 14, 18, 12, 18)
	topBar.Parent = root

	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -104, 0, 22),
		Text = config.Title or "Material 3",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(title, "headlineSmall", colors.onSurface)
	title.Parent = topBar

	local subtitle = create("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, -96, 0, 18),
		Text = config.Subtitle or "Google-flavored Roblox UI",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(subtitle, "bodyMedium", colors.onSurfaceVariant)
	subtitle.Parent = topBar

	local actions = create("Frame", {
		Name = "Actions",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.fromOffset(80, 40),
		BackgroundTransparency = 1,
	})
	actions.Parent = topBar

	local actionsList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	actionsList.Parent = actions

	local function createTopAction(name, text)
		local button = create("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = colors.surfaceContainerHigh,
			BorderSizePixel = 0,
			Text = text,
			AutoButtonColor = false,
		})
		applyTextStyle(button, "labelMedium", colors.onSurfaceVariant)
		applyCorner(button, TOKENS.radius.full)
		applyStroke(button, colors.outlineVariant, 0.82, 1)
		local stateLayer = createStateLayer(button, TOKENS.radius.full)
		bindStateLayer(button, stateLayer, function()
			return self.Colors.onSurfaceVariant
		end)
		button.Parent = actions
		return button
	end

	local minimizeButton = createTopAction("MinimizeButton", "-")
	local closeButton = createTopAction("CloseButton", "x")

	local navigation = create("Frame", {
		Name = "Navigation",
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(0, 142, 1, -64),
		BackgroundColor3 = elevatedSurface(colors, 0.03),
		BorderSizePixel = 0,
	})
	applyPadding(navigation, 12, 10, 12, 10)
	navigation.Parent = root

	local profileCard = create("Frame", {
		Name = "ProfileCard",
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundColor3 = colors.surfaceContainer,
		BorderSizePixel = 0,
	})
	applyCorner(profileCard, TOKENS.radius.large)
	applyStroke(profileCard, colors.outlineVariant, 0.8, 1)
	profileCard.Parent = navigation

	local avatar = create("ImageLabel", {
		Name = "Avatar",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = colors.secondaryContainer,
		BorderSizePixel = 0,
		BackgroundTransparency = 0,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
	})
	applyCorner(avatar, TOKENS.radius.full)
	avatar.Parent = profileCard

	local avatarFallback = create("TextLabel", {
		Name = "AvatarFallback",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = getDisplayInitials(),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = secureMode,
	})
	applyTextStyle(avatarFallback, "titleMedium", colors.onSecondaryContainer)
	avatarFallback.Parent = avatar

	local avatarStroke = create("UIStroke", {
		Color = colors.outlineVariant,
		Transparency = 0.5,
		Thickness = 1,
	})
	avatarStroke.Parent = avatar

	local profileName = create("TextLabel", {
		Name = "ProfileName",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(74, 12),
		Size = UDim2.new(1, -118, 0, 20),
		Text = LocalPlayer.DisplayName or LocalPlayer.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(profileName, "titleMedium", colors.onSurface)
	profileName.TextWrapped = false
	profileName.Parent = profileCard

	local profileHandle = create("TextLabel", {
		Name = "ProfileHandle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(74, 34),
		Size = UDim2.new(1, -118, 0, 18),
		Text = "@" .. LocalPlayer.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(profileHandle, "labelMedium", colors.onSurfaceVariant)
	profileHandle.TextWrapped = false
	profileHandle.Parent = profileCard

	local settingsButton = create("TextButton", {
		Name = "MenuSettingsButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	applyCorner(settingsButton, TOKENS.radius.medium)
	applyStroke(settingsButton, colors.outlineVariant, 0.82, 1)
	local settingsStateLayer = createStateLayer(settingsButton, TOKENS.radius.medium)
	bindStateLayer(settingsButton, settingsStateLayer, function()
		return self.Colors.onSurfaceVariant
	end)
	settingsButton.Parent = profileCard

	local settingsIcon
	local settingsLabel
	if secureMode then
		settingsLabel = create("TextLabel", {
			Name = "SettingsLabel",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "S",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		applyTextStyle(settingsLabel, "labelLarge", colors.onSurfaceVariant)
		settingsLabel.Parent = settingsButton
	else
		settingsIcon = create("ImageLabel", {
			Name = "SettingsIcon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Image = "rbxassetid://107951743207713",
			ImageColor3 = colors.onSurfaceVariant,
		})
		settingsIcon.Parent = settingsButton
	end

	local tabsHost = create("ScrollingFrame", {
		Name = "TabsHost",
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 1, -80),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	tabsHost.Parent = navigation

	local navList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	navList.Parent = tabsHost

	local contentHost = create("Frame", {
		Name = "ContentHost",
		Position = UDim2.fromOffset(142, 64),
		Size = UDim2.new(1, -142, 1, -64),
		BackgroundTransparency = 1,
	})
	contentHost.Parent = root

	local settingsPanel = create("Frame", {
		Name = "SettingsPanel",
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = colors.surfaceContainer,
		BorderSizePixel = 0,
		Visible = false,
	})
	applyCorner(settingsPanel, TOKENS.radius.large)
	applyStroke(settingsPanel, colors.outlineVariant, 0.78, 1)
	settingsPanel.Parent = navigation

	local settingsPadding = applyPadding(settingsPanel, 12, 12, 12, 12)
	settingsPadding.Parent = settingsPanel

	local settingsTitle = create("TextLabel", {
		Name = "SettingsTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Text = "Menu settings",
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	})
	applyTextStyle(settingsTitle, "titleMedium", colors.onSurface)
	settingsTitle.Parent = settingsPanel

	local settingsStack = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	settingsStack.Parent = settingsPanel

	local function createSettingsSwitch(labelText, descriptionText, defaultValue, onChanged)
		local row = create("TextButton", {
			BackgroundColor3 = colors.surfaceContainerLow,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, descriptionText and 56 or 50),
			Text = "",
			AutoButtonColor = false,
		})
		applyCorner(row, TOKENS.radius.medium)
		applyStroke(row, colors.outlineVariant, 0.82, 1)
		local rowStateLayer = createStateLayer(row, TOKENS.radius.medium)
		bindStateLayer(row, rowStateLayer, function()
			return colors.onSurface
		end)

		local titleLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, descriptionText and 7 or 0),
			Size = UDim2.new(1, -84, 0, 22),
			Text = labelText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		applyTextStyle(titleLabel, descriptionText and "bodyLarge" or "bodyMedium", colors.onSurface)
		titleLabel.Parent = row

		local descriptionLabel
		if descriptionText then
			descriptionLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 28),
				Size = UDim2.new(1, -84, 0, 18),
				Text = descriptionText,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			})
			applyTextStyle(descriptionLabel, "bodySmall", colors.onSurfaceVariant)
			descriptionLabel.Parent = row
		end

		local track = create("Frame", {
			Name = "Track",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(48, 28),
			BackgroundColor3 = colors.surfaceContainerHighest,
			BorderSizePixel = 0,
		})
		applyCorner(track, TOKENS.radius.full)
		applyStroke(track, colors.outlineVariant, 0.75, 1)
		track.Parent = row

		local thumb = create("Frame", {
			Name = "Thumb",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 4, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = colors.outline,
			BorderSizePixel = 0,
		})
		applyCorner(thumb, TOKENS.radius.full)
		thumb.Parent = track

		local value = defaultValue == true

		local object = {}

		local function sync(animate)
			if value then
				track.BackgroundColor3 = colors.primary
				thumb.BackgroundColor3 = colors.onPrimary
				local trackStroke = track:FindFirstChildOfClass("UIStroke")
				if trackStroke then
					trackStroke.Color = colors.primary
					trackStroke.Transparency = 1
				end
				if animate == false then
					thumb.Position = UDim2.new(0, 24, 0.5, 0)
					thumb.Size = UDim2.fromOffset(20, 20)
				else
					tween(thumb, TOKENS.motion.normal, {
						Position = UDim2.new(0, 24, 0.5, 0),
						Size = UDim2.fromOffset(20, 20),
					})
				end
			else
				track.BackgroundColor3 = colors.surfaceContainerHighest
				thumb.BackgroundColor3 = colors.outline
				local trackStroke = track:FindFirstChildOfClass("UIStroke")
				if trackStroke then
					trackStroke.Color = colors.outlineVariant
					trackStroke.Transparency = 0.75
				end
				if animate == false then
					thumb.Position = UDim2.new(0, 4, 0.5, 0)
					thumb.Size = UDim2.fromOffset(20, 20)
				else
					tween(thumb, TOKENS.motion.normal, {
						Position = UDim2.new(0, 4, 0.5, 0),
						Size = UDim2.fromOffset(20, 20),
					})
				end
			end
		end

		row.MouseButton1Down:Connect(function()
			thumb.Size = UDim2.fromOffset(24, 24)
		end)

		row.MouseButton1Up:Connect(function()
			sync()
		end)

		row.MouseLeave:Connect(function()
			sync()
		end)

		row.Activated:Connect(function()
			value = not value
			sync()
			if onChanged then
				onChanged(value)
			end
		end)

		function object:SetValue(newValue, silent)
			value = newValue == true
			sync(false)
			if not silent and onChanged then
				onChanged(value)
			end
		end

		function object:GetValue()
			return value
		end

		function object:ApplyTheme(nextColors)
			colors = nextColors
			row.BackgroundColor3 = colors.surfaceContainerLow
			titleLabel.TextColor3 = colors.onSurface
			if descriptionLabel then
				descriptionLabel.TextColor3 = colors.onSurfaceVariant
			end
			local stroke = row:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = colors.outlineVariant
			end
			sync(false)
		end

		object.Instance = row
		sync(false)
		return row, object
	end

	local themeRow, themeToggle = createSettingsSwitch("Light theme", "Switch the whole UI between dark and light.", mode == "light", function(enabled)
		self:SetTheme(enabled and "light" or "dark")
	end)
	themeRow.LayoutOrder = 2
	themeRow.Parent = settingsPanel

	local acrylicRow, acrylicToggle = createSettingsSwitch("Acrylic blur", "Use the built-in translucent blur effect.", self.Theme.acrylic, function(enabled)
		self:SetAcrylic(enabled)
	end)
	acrylicRow.LayoutOrder = 3
	acrylicRow.Parent = settingsPanel

	local settingsExpandedHeight = 136

	local function updateNavigationLayout()
		local topInset = profileCard.AbsoluteSize.Y + 8
		if settingsPanel.Visible and settingsPanel.Parent == navigation then
			topInset = topInset + settingsExpandedHeight + 8
		end
		tabsHost.Position = UDim2.fromOffset(0, topInset)
		tabsHost.Size = UDim2.new(1, 0, 1, -topInset)
	end

	settingsPanel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		settingsExpandedHeight = math.max(136, math.floor(settingsPanel.AbsoluteSize.Y + 0.5))
		updateNavigationLayout()
	end)

	updateNavigationLayout()

	local railDivider = create("Frame", {
		Name = "RailDivider",
		Position = UDim2.fromOffset(156, 76),
		Size = UDim2.new(0, 1, 1, -92),
		BackgroundColor3 = colors.outlineVariant,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
	})
	railDivider.Parent = root

	local pages = {}
	local tabs = {}
	local currentPage = nil

	local window = setmetatable({
		Library = self,
		ScreenGui = gui,
		Root = root,
		SurfaceTint = surfaceTint,
		AcrylicTint = acrylicTint,
		AcrylicGlow = acrylicGlow,
		RescueHandle = rescueHandle,
		RescueGrip = rescueGrip,
		NotificationHost = notificationHost,
		TopBar = topBar,
		Navigation = navigation,
		TabsHost = tabsHost,
		ContentHost = contentHost,
		ProfileCard = profileCard,
		Avatar = avatar,
		AvatarFallback = avatarFallback,
		ProfileName = profileName,
		ProfileHandle = profileHandle,
		SettingsButton = settingsButton,
		SettingsIcon = settingsIcon,
		SettingsLabel = settingsLabel,
		SettingsPanel = settingsPanel,
		SettingsTitle = settingsTitle,
		ThemeRow = themeRow,
		ThemeToggle = themeToggle,
		AcrylicRow = acrylicRow,
		AcrylicToggle = acrylicToggle,
		UpdateNavigationLayout = updateNavigationLayout,
		SizeConstraint = sizeConstraint,
		Pages = pages,
		Tabs = tabs,
		ThemeUpdaters = {},
		CurrentPage = currentPage,
		SettingsPage = nil,
		IsMinimized = false,
		ExpandedSize = UDim2.fromScale(0.56, 0.54),
		MinimizedSize = UDim2.fromOffset(360, 64),
	}, Window)

	if not secureMode then
		task.spawn(function()
			local image = safeGetUserThumbnail(LocalPlayer.UserId)
			if image ~= "" and avatar.Parent then
				avatar.Image = image
				if avatarFallback then
					avatarFallback.Visible = false
				end
				return
			end

			for _ = 1, 8 do
				task.wait(0.25)
				image = safeGetUserThumbnail(LocalPlayer.UserId)
				if image ~= "" and avatar.Parent then
					avatar.Image = image
					if avatarFallback then
						avatarFallback.Visible = false
					end
					return
				end
			end

			if avatarFallback then
				avatarFallback.Visible = true
			end
		end)
	end

	local dragging = false
	local dragStart
	local rootStart
	local dragTarget = root.Position
	local dragInputType = nil
	local rescueVisible = false
	local function beginDrag(input)
		bumpWindowZ(root, self.Library)
		dragging = true
		dragStart = input.Position
		rootStart = dragTarget
		dragInputType = input.UserInputType
	end

	local function updateDrag(input)
		if not dragging then
			return
		end
		local delta = input.Position - dragStart
		dragTarget = UDim2.new(
			rootStart.X.Scale,
			rootStart.X.Offset + delta.X,
			rootStart.Y.Scale,
			rootStart.Y.Offset + delta.Y
		)
	end

	local function endDrag()
		dragging = false
		dragInputType = nil
	end

	table.insert(self.Connections, topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end))

	table.insert(self.Connections, rescueHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end))

	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if dragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateDrag(input)
		elseif dragInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end))

	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end))

	table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
		local alpha = 1 - math.exp(-20 * dt)
		root.Position = UDim2.new(
			root.Position.X.Scale + (dragTarget.X.Scale - root.Position.X.Scale) * alpha,
			root.Position.X.Offset + (dragTarget.X.Offset - root.Position.X.Offset) * alpha,
			root.Position.Y.Scale + (dragTarget.Y.Scale - root.Position.Y.Scale) * alpha,
			root.Position.Y.Offset + (dragTarget.Y.Offset - root.Position.Y.Offset) * alpha
		)

		local shouldShowRescue = root.AbsolutePosition.Y < -(topBar.AbsoluteSize.Y * 0.45)
		if shouldShowRescue ~= rescueVisible then
			rescueVisible = shouldShowRescue
			rescueHandle.Visible = true
			tween(rescueHandle, TOKENS.motion.normal, {
				BackgroundTransparency = rescueVisible and 0.08 or 1,
			})
			tween(rescueGrip, TOKENS.motion.normal, {
				BackgroundTransparency = rescueVisible and 0.24 or 1,
			})
			local rescueStroke = rescueHandle:FindFirstChildOfClass("UIStroke")
			if rescueStroke then
				tween(rescueStroke, TOKENS.motion.normal, {
					Transparency = rescueVisible and 0.55 or 1,
				})
			end
			if not rescueVisible then
				task.delay(0.24, function()
					if rescueHandle.Parent and not rescueVisible then
						rescueHandle.Visible = false
					end
				end)
			end
		end
	end))

	closeButton.Activated:Connect(function()
		window:Destroy()
	end)

	minimizeButton.Activated:Connect(function()
		window:ToggleMinimize()
	end)

	settingsButton.Activated:Connect(function()
		window:ToggleSettingsPanel()
	end)

	themeRow.Activated:Connect(function()
		local nextMode = window.Library.Mode == "dark" and "light" or "dark"
		window:ApplyTheme(nextMode)
	end)

	acrylicRow.Activated:Connect(function()
		window:SetAcrylic(not window.Library.Theme.acrylic)
	end)

	gui.Parent = config.Parent or CoreGui
	gui.Enabled = true
	root.Size = UDim2.fromScale(0.48, 0.54)
	root.BackgroundTransparency = 1
	navigation.BackgroundTransparency = 1
	topBar.BackgroundTransparency = 1
	profileCard.BackgroundTransparency = 1
	tween(root, TOKENS.motion.emphasized, {
		Size = window.ExpandedSize,
		BackgroundTransparency = 0,
	})
	tween(navigation, TOKENS.motion.normal, { BackgroundTransparency = 0 })
	tween(topBar, TOKENS.motion.normal, { BackgroundTransparency = 0 })
	tween(profileCard, TOKENS.motion.normal, { BackgroundTransparency = 0 })
	window:ApplyTheme(mode)
	window:SetAcrylic(self.Theme.acrylic)
	settingsPanel.Visible = false
	if GENV then
		GENV.Material3Active = window
	end
	Material3.ActiveWindow = window

	local toggleKey = config.ToggleUIKeybind or Enum.KeyCode.RightShift
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
			window:ToggleVisibility()
		end
	end))

	return window
end

function Window:ToggleMinimize()
	self.IsMinimized = not self.IsMinimized

	if self.IsMinimized then
		self.SizeConstraint.MinSize = Vector2.new(360, 64)
		self.Navigation.Visible = false
		self.ContentHost.Visible = false
		local divider = self.Root:FindFirstChild("RailDivider")
		if divider then
			divider.Visible = false
		end
		tween(self.Root, TOKENS.motion.normal, {
			Size = self.MinimizedSize,
		})
	else
		self.SizeConstraint.MinSize = Vector2.new(520, 340)
		tween(self.Root, TOKENS.motion.normal, {
			Size = self.ExpandedSize,
		})
		task.delay(0.12, function()
			if self.Root and self.Root.Parent and not self.IsMinimized then
				self.Navigation.Visible = true
				self.ContentHost.Visible = true
				local divider = self.Root:FindFirstChild("RailDivider")
				if divider then
					divider.Visible = true
				end
			end
		end)
	end
end

function Material3.SetFallbackFont(fontEnum)
	TOKENS.font.fallback = fontEnum or Enum.Font.BuilderSans
end

function Material3.SetFontFace(fontFace)
	TOKENS.font.face = fontFace
end

function Material3.IsSecureMode()
	return secureMode
end

function Material3:_SaveState()
	if not self.ConfigSettings or not self.ConfigSettings.SaveCurrentState then
		return
	end
	local payload = {}
	for flag, element in pairs(self.Flags or {}) do
		if element and type(element.GetValue) == "function" then
			payload[flag] = serializeValue(element:GetValue())
		end
	end
	self.ConfigData = payload
	writeJsonFile(self.ConfigPath, payload)
end

function Material3:_ApplyState(flag, object)
	if not flag or not object then
		return
	end
	local value = self.ConfigData and self.ConfigData[flag]
	if value ~= nil and type(object.SetValue) == "function" then
		object:SetValue(deserializeValue(value), true)
	end
end

function Material3:RegisterFlag(flag, object)
	if not flag or not object then
		return object
	end
	self.Flags[flag] = object
	self:_ApplyState(flag, object)
	return object
end

function Window:Notify(config)
	config = config or {}
	local toast = create("Frame", {
		Name = "Snackbar",
		Size = UDim2.fromOffset(300, 56),
		BackgroundColor3 = self.Library.Colors.inverseSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 50,
	})
	applyCorner(toast, TOKENS.radius.large)
	toast.Parent = self.NotificationHost or self.ScreenGui

	local message = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Text = config.Content or "Notification",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(message, "bodyMedium", self.Library.Colors.inverseOnSurface)
	message.Parent = toast

	toast.Position = UDim2.fromOffset(0, 10)
	tween(toast, TOKENS.motion.normal, {
		BackgroundTransparency = 0,
		Position = UDim2.fromOffset(0, 0),
	})
	task.delay(config.Duration or 3, function()
		if toast.Parent then
			tween(toast, TOKENS.motion.normal, {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 10),
			})
			task.delay(0.24, function()
				if toast.Parent then
					toast:Destroy()
				end
			end)
		end
	end)
end

function Window:ApplyTheme(mode)
	mode = (mode == "light" and "light") or "dark"
	self.Library.Mode = mode
	self.Library.Theme.mode = mode
	self.Library.Colors = TOKENS.colors[mode] or TOKENS.colors.dark

	local colors = self.Library.Colors
	self.Root.BackgroundColor3 = elevatedSurface(colors, 0.06)
	if self.SurfaceTint then
		self.SurfaceTint.BackgroundColor3 = colors.primary
	end
	if self.AcrylicTint then
		self.AcrylicTint.BackgroundColor3 = elevatedSurface(colors, 0.08)
	end
	if self.AcrylicGlow then
		self.AcrylicGlow.BackgroundColor3 = mode == "light" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 225, 255)
	end
	if self.RescueHandle then
		self.RescueHandle.BackgroundColor3 = colors.surfaceContainerHigh
		local rescueStroke = self.RescueHandle:FindFirstChildOfClass("UIStroke")
		if rescueStroke then
			rescueStroke.Color = colors.outlineVariant
		end
	end
	if self.RescueGrip then
		self.RescueGrip.BackgroundColor3 = colors.onSurfaceVariant
	end
	self.TopBar.BackgroundColor3 = elevatedSurface(colors, 0.04)
	self.Navigation.BackgroundColor3 = elevatedSurface(colors, 0.03)
	self.ProfileCard.BackgroundColor3 = colors.surfaceContainer
	self.Avatar.BackgroundColor3 = colors.secondaryContainer
	if self.AvatarFallback then
		self.AvatarFallback.TextColor3 = colors.onSecondaryContainer
	end
	self.ProfileName.TextColor3 = colors.onSurface
	self.ProfileHandle.TextColor3 = colors.onSurfaceVariant
	self.SettingsButton.BackgroundColor3 = colors.surfaceContainerHigh
	if self.SettingsIcon then
		self.SettingsIcon.ImageColor3 = colors.onSurfaceVariant
	end
	if self.SettingsLabel then
		self.SettingsLabel.TextColor3 = colors.onSurfaceVariant
	end
	self.SettingsPanel.BackgroundColor3 = colors.surfaceContainer
	self.SettingsTitle.TextColor3 = colors.onSurface
	local divider = self.Root:FindFirstChild("RailDivider")
	if divider then
		divider.BackgroundColor3 = colors.outlineVariant
	end

	for _, instance in ipairs({ self.Root, self.ProfileCard, self.SettingsButton, self.SettingsPanel, self.ThemeRow, self.AcrylicRow }) do
		local stroke = instance:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = colors.outlineVariant
		end
	end

	local avatarStroke = self.Avatar:FindFirstChildOfClass("UIStroke")
	if avatarStroke then
		avatarStroke.Color = colors.outlineVariant
	end

	local title = self.TopBar:FindFirstChild("Title")
	local subtitle = self.TopBar:FindFirstChild("Subtitle")
	if title then
		title.TextColor3 = colors.onSurface
	end
	if subtitle then
		subtitle.TextColor3 = colors.onSurfaceVariant
	end

	local actions = self.TopBar:FindFirstChild("Actions")
	if actions then
		for _, child in ipairs(actions:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = colors.surfaceContainerHigh
				child.TextColor3 = colors.onSurfaceVariant
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = colors.outlineVariant
				end
			end
		end
	end

	for _, row in ipairs({ self.ThemeRow, self.AcrylicRow }) do
		row.BackgroundColor3 = colors.surfaceContainerLow
	end

	if self.ThemeToggle then
		self.ThemeToggle:ApplyTheme(colors)
		self.ThemeToggle:SetValue(mode == "light", true)
	end

	if self.AcrylicToggle then
		self.AcrylicToggle:ApplyTheme(colors)
		self.AcrylicToggle:SetValue(self.Library.Theme.acrylic, true)
	end

	for page, button in pairs(self.Tabs) do
		local indicator = button:FindFirstChild("Indicator")
		if self.CurrentPage == page then
			button.BackgroundColor3 = colors.secondaryContainer
			button.TextColor3 = colors.onSecondaryContainer
			if indicator then
				indicator.BackgroundColor3 = colors.primary
				indicator.BackgroundTransparency = 0
			end
		else
			button.BackgroundColor3 = colors.surface
			button.TextColor3 = colors.onSurfaceVariant
			if indicator then
				indicator.BackgroundColor3 = colors.primary
				indicator.BackgroundTransparency = 1
			end
		end
	end

	for _, updater in ipairs(self.ThemeUpdaters or {}) do
		updater(colors)
	end
end

function Window:SetTheme(mode)
	self:ApplyTheme(mode)
end

function Window:SetAcrylic(enabled)
	self.Library.Theme.acrylic = enabled and true or false
	if self.AcrylicToggle then
		self.AcrylicToggle:SetValue(self.Library.Theme.acrylic, true)
	end

	local blur = ensureBlurEffect()
	if blur and blur.Parent == Lighting then
		pcall(function()
			blur.Enabled = self.Library.Theme.acrylic
			blur.Size = self.Library.Theme.acrylic and 18 or 0
		end)
	end

	if self.AcrylicTint then
		self.AcrylicTint.Visible = self.Library.Theme.acrylic
		self.AcrylicTint.BackgroundTransparency = self.Library.Theme.acrylic and 0.24 or 1
	end
	if self.AcrylicGlow then
		self.AcrylicGlow.Visible = self.Library.Theme.acrylic
		self.AcrylicGlow.BackgroundTransparency = self.Library.Theme.acrylic and 0.7 or 1
	end

	self.Root.BackgroundTransparency = self.Library.Theme.acrylic and 0.18 or 0
	self.TopBar.BackgroundTransparency = self.Library.Theme.acrylic and 0.22 or 0
	self.Navigation.BackgroundTransparency = self.Library.Theme.acrylic and 0.2 or 0
	self.ContentHost.BackgroundTransparency = 1
	self.ProfileCard.BackgroundTransparency = self.Library.Theme.acrylic and 0.18 or 0
	self.SettingsPanel.BackgroundTransparency = self.Library.Theme.acrylic and 0.16 or 0
end

function Window:ToggleSettingsPanel()
	bumpWindowZ(self.Root, self.Library)
	if not self.SettingsPage then
		local page = self:CreatePage({
			Name = "SettingsPage",
			Title = "Settings",
			HiddenTab = true,
		})
		self.SettingsPage = page

		self.SettingsPanel.Visible = true
		self.SettingsPanel.Position = UDim2.fromOffset(0, 0)
		self.SettingsPanel.Size = UDim2.new(1, 0, 0, 0)
		self.SettingsPanel.Parent = page.Frame
		if self.UpdateNavigationLayout then
			self:UpdateNavigationLayout()
		end
	end

	self:SelectPage(self.SettingsPage)
end

function Window:SelectPage(page)
	if self.CurrentPage == page then
		return
	end

	for _, item in ipairs(self.Pages) do
		item.Frame.Visible = false
		local tabButton = self.Tabs[item]
		if tabButton then
			tabButton.BackgroundColor3 = self.Library.Colors.surface
			tabButton.TextColor3 = self.Library.Colors.onSurfaceVariant
			local indicator = tabButton:FindFirstChild("Indicator")
			if indicator then
				indicator.BackgroundColor3 = self.Library.Colors.primary
				indicator.BackgroundTransparency = 1
			end
		end
	end

	page.Frame.Visible = true
	self.CurrentPage = page

	local selected = self.Tabs[page]
	if selected then
		selected.BackgroundColor3 = self.Library.Colors.secondaryContainer
		selected.TextColor3 = self.Library.Colors.onSecondaryContainer
		local indicator = selected:FindFirstChild("Indicator")
		if indicator then
			indicator.BackgroundColor3 = self.Library.Colors.primary
			indicator.BackgroundTransparency = 0
		end
	end
end

function Window:CreatePage(config)
	config = config or {}
	local pageButton
	if not config.HiddenTab then
		pageButton = create("TextButton", {
			Name = (config.Name or "Page") .. "Tab",
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = self.Library.Colors.surface,
			BorderSizePixel = 0,
			Text = config.Title or config.Name or "Page",
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
		})
		applyTextStyle(pageButton, "labelLarge", self.Library.Colors.onSurfaceVariant)
		applyCorner(pageButton, TOKENS.radius.full)
		applyPadding(pageButton, 0, 18, 0, 28)
		local indicator = create("Frame", {
			Name = "Indicator",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(4, 18),
			BackgroundColor3 = self.Library.Colors.primary,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		})
		applyCorner(indicator, TOKENS.radius.full)
		indicator.Parent = pageButton
		createStateLayer(pageButton, TOKENS.radius.full)
		pageButton.Parent = self.TabsHost
	end

	local pageFrame = create("ScrollingFrame", {
		Name = config.Name or "Page",
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	})
	pageFrame.Parent = self.ContentHost

	local pagePadding = applyPadding(pageFrame, 18, 18, 18, 18)
	local pageList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 16),
	})
	pageList.Parent = pageFrame

	local page = setmetatable({
		Window = self,
		Frame = pageFrame,
		List = pageList,
		Padding = pagePadding,
		HiddenTab = config.HiddenTab == true,
	}, Page)

	bindThemeUpdater(self, function(colors)
		if pageButton then
			if self.CurrentPage == page then
				pageButton.BackgroundColor3 = colors.secondaryContainer
				pageButton.TextColor3 = colors.onSecondaryContainer
				local indicator = pageButton:FindFirstChild("Indicator")
				if indicator then
					indicator.BackgroundColor3 = colors.primary
					indicator.BackgroundTransparency = 0
				end
			else
				pageButton.BackgroundColor3 = colors.surface
				pageButton.TextColor3 = colors.onSurfaceVariant
				local indicator = pageButton:FindFirstChild("Indicator")
				if indicator then
					indicator.BackgroundColor3 = colors.primary
					indicator.BackgroundTransparency = 1
				end
			end
			local stateLayer = pageButton:FindFirstChild("StateLayer")
			if stateLayer then
				stateLayer.BackgroundColor3 = colors.onSurface
			end
		end
	end)

	if pageButton then
		self.Tabs[page] = pageButton
	end
	table.insert(self.Pages, page)

	if pageButton then
		pageButton.MouseEnter:Connect(function()
			if self.CurrentPage ~= page then
				pageButton.StateLayer.BackgroundColor3 = self.Library.Colors.onSurface
				pageButton.StateLayer.BackgroundTransparency = 1 - TOKENS.stateOpacity.hover
			end
		end)

		pageButton.MouseLeave:Connect(function()
			if self.CurrentPage ~= page then
				pageButton.StateLayer.BackgroundTransparency = 1
			end
		end)

		pageButton.Activated:Connect(function()
			self:SelectPage(page)
		end)
	end

	if not config.HiddenTab and self.CurrentPage == nil then
		self:SelectPage(page)
	end

	return page
end

function Page:CreateSection(config)
	config = config or {}
	local card = create("Frame", {
		Name = config.Name or "Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Window.Library.Colors.surfaceContainer,
		BorderSizePixel = 0,
	})
	applyCorner(card, TOKENS.radius.large)
	applyStroke(card, self.Window.Library.Colors.outlineVariant, 0.82, 1)
	applyPadding(card, 14, 14, 14, 14)
	card.Parent = self.Frame

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Text = config.Title or config.Name or "Section",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(title, "titleMedium", self.Window.Library.Colors.onSurface)
	title.Parent = card

	local description
	local offset = 26
	if config.Description then
		description = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, 0, 0, 18),
			Text = config.Description,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		applyTextStyle(description, "bodyMedium", self.Window.Library.Colors.onSurfaceVariant)
		description.Parent = card
		offset = 50
	end

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, offset),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	content.Parent = card

	local list = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	list.Parent = content

	if description then
		description.TextWrapped = true
	end

	local section = setmetatable({
		Page = self,
		Frame = card,
		Content = content,
		List = list,
	}, Section)

	bindThemeUpdater(self.Window, function(colors)
		card.BackgroundColor3 = colors.surfaceContainer
		title.TextColor3 = colors.onSurface
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = colors.outlineVariant
		end
		if description then
			description.TextColor3 = colors.onSurfaceVariant
		end
	end)

	return section
end

function Section:CreateLabel(config)
	config = config or {}
	local label = create("TextLabel", {
		Name = config.Name or "Label",
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = config.Title or config.Text or "Label",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	applyTextStyle(label, config.Style or "bodyMedium", config.Color or self.Page.Window.Library.Colors.onSurfaceVariant)
	label.TextWrapped = true
	label.Parent = self.Content
	bindThemeUpdater(self.Page.Window, function(colors)
		if not config.Color then
			label.TextColor3 = colors.onSurfaceVariant
		end
	end)
	return label
end

function Section:CreateParagraph(config)
	config = config or {}
	local holder = create("Frame", {
		Name = config.Name or "Paragraph",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Page.Window.Library.Colors.surfaceContainerHigh,
		BorderSizePixel = 0,
	})
	applyCorner(holder, TOKENS.radius.large)
	applyStroke(holder, self.Page.Window.Library.Colors.outlineVariant, 0.84, 1)
	applyPadding(holder, 12, 12, 12, 12)
	holder.Parent = self.Content

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Text = config.Title or "Paragraph",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(title, "titleMedium", self.Page.Window.Library.Colors.onSurface)
	title.Parent = holder

	local body = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = config.Content or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	applyTextStyle(body, "bodyMedium", self.Page.Window.Library.Colors.onSurfaceVariant)
	body.TextWrapped = true
	body.Parent = holder

	bindThemeUpdater(self.Page.Window, function(colors)
		holder.BackgroundColor3 = colors.surfaceContainerHigh
		title.TextColor3 = colors.onSurface
		body.TextColor3 = colors.onSurfaceVariant
		local stroke = holder:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = colors.outlineVariant
		end
	end)

	return holder
end

function Section:CreateButton(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors
	local variant = config.Variant or "filled"
	local palette = {
		filled = { bg = colors.primary, fg = colors.onPrimary, stroke = 1 },
		tonal = { bg = colors.secondaryContainer, fg = colors.onSecondaryContainer, stroke = 1 },
		outlined = { bg = colors.surface, fg = colors.onSurface, stroke = 0 },
		text = { bg = colors.surface, fg = colors.primary, stroke = 0 },
	}
	local resolved = palette[variant] or palette.filled

	local button = create("TextButton", {
		Name = config.Name or "Button",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = resolved.bg,
		BorderSizePixel = 0,
		Text = config.Title or "Button",
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
	})
	applyTextStyle(button, "labelLarge", resolved.fg)
	applyCorner(button, TOKENS.radius.full)
	applyPadding(button, 0, 20, 0, 20)
	if variant == "outlined" then
		applyStroke(button, colors.outline, 0.45, 1)
	end
	local stateLayer = createStateLayer(button, TOKENS.radius.full)
	button.Parent = self.Content

	local object = {}
	bindStateLayer(button, stateLayer, function()
		return resolved.fg
	end)

	bindThemeUpdater(self.Page.Window, function(colors)
		local nextPalette = {
			filled = { bg = colors.primary, fg = colors.onPrimary, stroke = 1 },
			tonal = { bg = colors.secondaryContainer, fg = colors.onSecondaryContainer, stroke = 1 },
			outlined = { bg = colors.surface, fg = colors.onSurface, stroke = 0 },
			text = { bg = colors.surface, fg = colors.primary, stroke = 0 },
		}
		resolved = nextPalette[variant] or nextPalette.filled
		button.BackgroundColor3 = resolved.bg
		button.TextColor3 = resolved.fg
		stateLayer.BackgroundColor3 = resolved.fg
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = colors.outline
		end
	end)

	button.Activated:Connect(function()
		safeCallback(config.Callback)
	end)

	function object:SetTitle(text)
		button.Text = text
	end

	function object:SetDisabled(disabled)
		button.Active = not disabled
		button.AutoButtonColor = false
		button.BackgroundTransparency = disabled and TOKENS.stateOpacity.disabledContainer or 0
		button.TextTransparency = disabled and TOKENS.stateOpacity.disabledContent or 0
	end

	object.Instance = button
	return object
end

function Section:CreateToggle(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors
	local flag = config.Flag
	local saved = flag and self.Page.Window.Library.ConfigData[flag]
	local value = saved ~= nil and saved == true or config.Default == true

	local row = create("Frame", {
		Name = config.Name or "Toggle",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
	})
	row.Parent = self.Content

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 0, 24),
		Position = UDim2.fromOffset(0, 4),
		Text = config.Title or "Toggle",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(title, "bodyLarge", colors.onSurface)
	title.Parent = row

	local description
	if config.Description then
		description = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(1, -80, 0, 18),
			Text = config.Description,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		applyTextStyle(description, "bodyMedium", colors.onSurfaceVariant)
		description.Parent = row
	end

	local track = create("TextButton", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(48, 28),
		BackgroundColor3 = colors.surfaceContainerHighest,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	applyCorner(track, TOKENS.radius.full)
	applyStroke(track, colors.outlineVariant, 0.75, 1)
	track.Parent = row

	local thumb = create("Frame", {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = colors.outline,
		BorderSizePixel = 0,
	})
	applyCorner(thumb, TOKENS.radius.full)
	thumb.Parent = track

	local function sync()
		if value then
			track.BackgroundColor3 = colors.primary
			thumb.BackgroundColor3 = colors.onPrimary
			local trackStroke = track:FindFirstChildOfClass("UIStroke")
			if trackStroke then
				trackStroke.Transparency = 1
				trackStroke.Color = colors.primary
			end
			tween(thumb, TOKENS.motion.normal, { Position = UDim2.new(0, 24, 0.5, 0), Size = UDim2.fromOffset(20, 20) })
		else
			track.BackgroundColor3 = colors.surfaceContainerHighest
			thumb.BackgroundColor3 = colors.outline
			local trackStroke = track:FindFirstChildOfClass("UIStroke")
			if trackStroke then
				trackStroke.Transparency = 0.75
				trackStroke.Color = colors.outlineVariant
			end
			tween(thumb, TOKENS.motion.normal, { Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(20, 20) })
		end
	end

	track.MouseButton1Down:Connect(function()
		tween(thumb, TOKENS.motion.fast, {
			Size = UDim2.fromOffset(24, 24),
		})
	end)

	track.MouseButton1Up:Connect(function()
		sync()
	end)

	track.Activated:Connect(function()
		value = not value
		sync()
		safeCallback(config.Callback, value)
		self.Page.Window.Library:_SaveState()
	end)

	sync()

	local object = {}
	if description then
		description.TextWrapped = true
	end

	bindThemeUpdater(self.Page.Window, function(nextColors)
		colors = nextColors
		title.TextColor3 = colors.onSurface
		if description then
			description.TextColor3 = colors.onSurfaceVariant
		end
		sync()
	end)

	function object:SetValue(newValue)
		value = newValue == true
		sync()
		self.Page.Window.Library:_SaveState()
	end

	function object:GetValue()
		return value
	end

	object.Instance = row
	object.Flag = flag
	self.Page.Window.Library:RegisterFlag(flag, object)
	return object
end

function Section:CreateSlider(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors
	local min = config.Min or 0
	local max = config.Max or 100
	local step = config.Step or 1
	local flag = config.Flag
	local saved = flag and self.Page.Window.Library.ConfigData[flag]
	local value = saved ~= nil and tonumber(saved) or math.clamp(config.Default or min, min, max)
	local range = math.max(max - min, 0.0001)

	local holder = create("Frame", {
		Name = config.Name or "Slider",
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 1,
	})
	holder.Parent = self.Content

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -96, 0, 22),
		Text = config.Title or "Slider",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(title, "labelLarge", colors.onSurface)
	title.Parent = holder

	local valueChip = create("Frame", {
		Name = "ValueChip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(78, 32),
		BackgroundColor3 = blendColor(colors.secondaryContainer, colors.primaryContainer, 0.2),
		BorderSizePixel = 0,
	})
	applyCorner(valueChip, TOKENS.radius.full)
	applyStroke(valueChip, colors.outlineVariant, 0.9, 1)
	valueChip.Parent = holder

	local valueBox = create("TextBox", {
		Name = "ValueBox",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.fromOffset(9, 0),
		Text = formatValue(value),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
	})
	applyTextStyle(valueBox, "labelLarge", colors.onSecondaryContainer)
	valueBox.Parent = valueChip

	local track = create("Frame", {
		Name = "Track",
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = colors.surfaceContainerHighest,
		BorderSizePixel = 0,
	})
	applyCorner(track, TOKENS.radius.full)
	track.Parent = holder

	local fill = create("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 6),
		BackgroundColor3 = colors.primary,
		BorderSizePixel = 0,
	})
	applyCorner(fill, TOKENS.radius.full)
	fill.Parent = track

	local thumb = create("TextButton", {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = colors.primary,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	applyCorner(thumb, TOKENS.radius.full)
	applyStroke(thumb, colors.surface, 0.12, 1)
	thumb.Parent = track

	local dragging = false

	local function snap(raw)
		local stepped = math.round(raw / step) * step
		return math.clamp(stepped, min, max)
	end

	local function setValue(newValue, fromInput)
		value = snap(newValue)
		local alpha = (value - min) / range
		fill.Size = UDim2.new(alpha, 0, 0, 6)
		thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
		if not valueBox:IsFocused() then
			valueBox.Text = formatValue(value)
		end
		if fromInput ~= false then
			safeCallback(config.Callback, value)
			self.Page.Window.Library:_SaveState()
		end
	end

	local function setDragging(nextDragging)
		dragging = nextDragging
		tween(thumb, nextDragging and TOKENS.motion.expressive or TOKENS.motion.fast, {
			Size = nextDragging and UDim2.fromOffset(30, 30) or UDim2.fromOffset(20, 20),
		})
		tween(valueChip, TOKENS.motion.fast, {
			BackgroundTransparency = nextDragging and 0 or 0.08,
			Size = nextDragging and UDim2.fromOffset(84, 34) or UDim2.fromOffset(78, 32),
		})
	end

	local function updateFromPosition(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + range * alpha
		setValue(raw, true)
	end

	thumb.MouseButton1Down:Connect(function()
		setDragging(true)
	end)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setDragging(true)
			updateFromPosition(input.Position.X)
		end
	end)

	table.insert(self.Page.Window.Library.Connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromPosition(input.Position.X)
		end
	end))

	table.insert(self.Page.Window.Library.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setDragging(false)
		end
	end))

	valueBox.FocusLost:Connect(function()
		local typedValue = tonumber((valueBox.Text or ""):gsub(",", "."))
		if typedValue then
			setValue(math.clamp(typedValue, min, max), true)
		else
			valueBox.Text = formatValue(value)
		end
		valueBox.Text = formatValue(value)
	end)

	setValue(value, false)
	setDragging(false)

	local object = {}
	bindThemeUpdater(self.Page.Window, function(colors)
		title.TextColor3 = colors.onSurface
		valueChip.BackgroundColor3 = blendColor(colors.secondaryContainer, colors.primaryContainer, 0.2)
		valueBox.TextColor3 = colors.onSecondaryContainer
		track.BackgroundColor3 = colors.surfaceContainerHighest
		fill.BackgroundColor3 = colors.primary
		thumb.BackgroundColor3 = colors.primary
		local chipStroke = valueChip:FindFirstChildOfClass("UIStroke")
		if chipStroke then
			chipStroke.Color = colors.outlineVariant
		end
		local thumbStroke = thumb:FindFirstChildOfClass("UIStroke")
		if thumbStroke then
			thumbStroke.Color = colors.surface
		end
	end)

	function object:SetValue(newValue)
		setValue(newValue, false)
		self.Page.Window.Library:_SaveState()
	end

	function object:GetValue()
		return value
	end

	object.Instance = holder
	object.Flag = flag
	self.Page.Window.Library:RegisterFlag(flag, object)
	return object
end

function Section:CreateColorPicker(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors
	local flag = config.Flag
	local saved = flag and self.Page.Window.Library.ConfigData[flag]
	local value = typeof(saved) == "Color3" and saved or (typeof(config.Default) == "Color3" and config.Default or Color3.new(1, 1, 1))
	local hue, saturation, brightness = value:ToHSV()
	local isOpen = false
	local draggingBox = false
	local draggingHue = false

	local holder = create("Frame", {
		Name = config.Name or "ColorPicker",
		Size = UDim2.new(1, 0, 0, 44),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})
	holder.Parent = self.Content

	local button = create("TextButton", {
		Name = "Main",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})
	applyCorner(button, TOKENS.radius.medium)
	applyStroke(button, colors.outlineVariant, 0.76, 1)
	button.Parent = holder

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -144, 1, 0),
		Text = config.Title or "Color Picker",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(title, "bodyLarge", colors.onSurface)
	title.Parent = button

	local preview = create("Frame", {
		Name = "Preview",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -56, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = value,
		BorderSizePixel = 0,
	})
	applyCorner(preview, TOKENS.radius.full)
	applyStroke(preview, colors.outlineVariant, 0.72, 1)
	preview.Parent = button

	local hexLabel = create("TextLabel", {
		Name = "HexLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -88, 0.5, 0),
		Size = UDim2.fromOffset(74, 20),
		BackgroundTransparency = 1,
		Text = colorToHex(value),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(hexLabel, "labelMedium", colors.onSurfaceVariant)
	hexLabel.Parent = button

	local chevron = create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Text = "v",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(chevron, "labelLarge", colors.onSurfaceVariant)
	chevron.Parent = button

	local panel = create("Frame", {
		Name = "Panel",
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
	})
	applyCorner(panel, TOKENS.radius.large)
	applyStroke(panel, colors.outlineVariant, 1, 1)
	applyPadding(panel, 12, 12, 12, 12)
	panel.Parent = holder

	local svBox = create("Frame", {
		Name = "SVBox",
		Size = UDim2.new(1, 0, 0, 126),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
	})
	applyCorner(svBox, TOKENS.radius.medium)
	svBox.Parent = panel

	local svWhite = create("Frame", {
		Name = "WhiteOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	})
	applyCorner(svWhite, TOKENS.radius.medium)
	local svWhiteGradient = Instance.new("UIGradient")
	svWhiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	svWhiteGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	svWhiteGradient.Rotation = 0
	svWhiteGradient.Parent = svWhite
	svWhite.Parent = svBox

	local svBlack = create("Frame", {
		Name = "BlackOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	})
	applyCorner(svBlack, TOKENS.radius.medium)
	local svBlackGradient = Instance.new("UIGradient")
	svBlackGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
	svBlackGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	svBlackGradient.Rotation = 90
	svBlackGradient.Parent = svBlack
	svBlack.Parent = svBox

	local svCursor = create("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	})
	applyCorner(svCursor, TOKENS.radius.full)
	applyStroke(svCursor, Color3.new(1, 1, 1), 0, 1)
	svCursor.Parent = svBox

	local hueTrack = create("Frame", {
		Name = "HueTrack",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 138),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	})
	applyCorner(hueTrack, TOKENS.radius.full)
	hueTrack.Parent = panel

	local hueGradient = Instance.new("UIGradient")
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	})
	hueGradient.Parent = hueTrack

	local hueThumb = create("Frame", {
		Name = "HueThumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(hue, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	})
	applyCorner(hueThumb, TOKENS.radius.full)
	applyStroke(hueThumb, colors.outlineVariant, 0.2, 1)
	hueThumb.Parent = hueTrack

	local hexTitle = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 162),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Hex",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(hexTitle, "labelMedium", colors.onSurfaceVariant)
	hexTitle.Parent = panel

	local hexBox = create("TextBox", {
		Name = "HexBox",
		Position = UDim2.fromOffset(0, 184),
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = colors.surfaceContainer,
		BorderSizePixel = 0,
		Text = colorToHex(value),
		PlaceholderText = "#RRGGBB",
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})
	applyCorner(hexBox, TOKENS.radius.medium)
	applyStroke(hexBox, colors.outlineVariant, 0.7, 1)
	applyPadding(hexBox, 0, 14, 0, 14)
	applyTextStyle(hexBox, "bodyLarge", colors.onSurface)
	hexBox.PlaceholderColor3 = colors.onSurfaceVariant
	hexBox.Parent = panel

	local function setOpen(open)
		isOpen = open
		chevron.Text = open and "^" or "v"
		if open then
			bumpWindowZ(holder, self.Page.Window.Library)
			panel.Visible = true
			panel.Position = UDim2.fromOffset(0, 46)
			panel.BackgroundTransparency = 1
			local stroke = panel:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = 1
			end
			tween(panel, TOKENS.motion.normal, {
				Position = UDim2.fromOffset(0, 50),
				BackgroundTransparency = 0,
			})
			if stroke then
				tween(stroke, TOKENS.motion.normal, {
					Transparency = 0.76,
				})
			end
		else
			local stroke = panel:FindFirstChildOfClass("UIStroke")
			tween(panel, TOKENS.motion.fast, {
				Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 1,
			})
			if stroke then
				tween(stroke, TOKENS.motion.fast, {
					Transparency = 1,
				})
			end
			task.delay(0.14, function()
				if panel.Parent and not isOpen then
					panel.Visible = false
				end
			end)
		end
	end

	local function syncVisual()
		local current = Color3.fromHSV(hue, saturation, brightness)
		value = current
		preview.BackgroundColor3 = current
		hexLabel.Text = colorToHex(current)
		if not hexBox:IsFocused() then
			hexBox.Text = colorToHex(current)
		end
		svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		svCursor.Position = UDim2.new(saturation, 0, 1 - brightness, 0)
		hueThumb.Position = UDim2.new(hue, 0, 0.5, 0)
	end

	local function setColor(newColor, fireCallback)
		if typeof(newColor) ~= "Color3" then
			return
		end
		hue, saturation, brightness = newColor:ToHSV()
		syncVisual()
		if fireCallback ~= false and config.Callback then
			safeCallback(config.Callback, value)
			self.Page.Window.Library:_SaveState()
		end
	end

	local function updateFromSVPosition(position)
		local relativeX = math.clamp((position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
		local relativeY = math.clamp((position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
		saturation = relativeX
		brightness = 1 - relativeY
		syncVisual()
		if config.Callback then
			safeCallback(config.Callback, value)
			self.Page.Window.Library:_SaveState()
		end
	end

	local function updateFromHuePosition(position)
		hue = math.clamp((position.X - hueTrack.AbsolutePosition.X) / math.max(hueTrack.AbsoluteSize.X, 1), 0, 1)
		syncVisual()
		if config.Callback then
			safeCallback(config.Callback, value)
			self.Page.Window.Library:_SaveState()
		end
	end

	button.Activated:Connect(function()
		setOpen(not isOpen)
	end)

	svBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingBox = true
			updateFromSVPosition(input.Position)
		end
	end)

	hueTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			updateFromHuePosition(input.Position)
		end
	end)

	table.insert(self.Page.Window.Library.Connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if draggingBox then
			updateFromSVPosition(input.Position)
		end
		if draggingHue then
			updateFromHuePosition(input.Position)
		end
	end))

	table.insert(self.Page.Window.Library.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingBox = false
			draggingHue = false
		end
	end))

	hexBox.FocusLost:Connect(function()
		local parsed = parseHexColor(hexBox.Text)
		if parsed then
			setColor(parsed, true)
		else
			hexBox.Text = colorToHex(value)
		end
	end)

	bindThemeUpdater(self.Page.Window, function(nextColors)
		colors = nextColors
		button.BackgroundColor3 = colors.surfaceContainerHigh
		title.TextColor3 = colors.onSurface
		hexLabel.TextColor3 = colors.onSurfaceVariant
		chevron.TextColor3 = colors.onSurfaceVariant
		panel.BackgroundColor3 = colors.surfaceContainerHigh
		hexTitle.TextColor3 = colors.onSurfaceVariant
		hexBox.BackgroundColor3 = colors.surfaceContainer
		hexBox.TextColor3 = colors.onSurface
		hexBox.PlaceholderColor3 = colors.onSurfaceVariant
		local buttonStroke = button:FindFirstChildOfClass("UIStroke")
		if buttonStroke then
			buttonStroke.Color = colors.outlineVariant
		end
		local panelStroke = panel:FindFirstChildOfClass("UIStroke")
		if panelStroke then
			panelStroke.Color = colors.outlineVariant
		end
		local previewStroke = preview:FindFirstChildOfClass("UIStroke")
		if previewStroke then
			previewStroke.Color = colors.outlineVariant
		end
		local hueThumbStroke = hueThumb:FindFirstChildOfClass("UIStroke")
		if hueThumbStroke then
			hueThumbStroke.Color = colors.outlineVariant
		end
		local hexStroke = hexBox:FindFirstChildOfClass("UIStroke")
		if hexStroke then
			hexStroke.Color = colors.outlineVariant
		end
	end)

	syncVisual()
	setOpen(false)

	local object = {}

	function object:SetValue(newValue)
		setColor(newValue, false)
		self.Page.Window.Library:_SaveState()
	end

	function object:GetValue()
		return value
	end

	object.Instance = holder
	object.Flag = flag
	self.Page.Window.Library:RegisterFlag(flag, object)
	return object
end

function Section:CreateInput(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors

	local holder = create("Frame", {
		Name = config.Name or "Input",
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
	})
	holder.Parent = self.Content

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = config.Title or "Input",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(title, "labelMedium", colors.onSurfaceVariant)
	title.Parent = holder

	local box = create("TextBox", {
		Name = "TextBox",
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	})
	applyCorner(box, TOKENS.radius.medium)
	applyStroke(box, colors.outlineVariant, 0.76, 1)
	applyPadding(box, 0, 16, 0, 16)
	applyTextStyle(box, "bodyLarge", colors.onSurface)
	box.PlaceholderColor3 = colors.onSurfaceVariant
	box.Parent = holder

	bindThemeUpdater(self.Page.Window, function(colors)
		title.TextColor3 = colors.onSurfaceVariant
		box.BackgroundColor3 = colors.surfaceContainerHigh
		box.TextColor3 = colors.onSurface
		box.PlaceholderColor3 = colors.onSurfaceVariant
		local stroke = box:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = colors.outlineVariant
		end
	end)

	box.FocusLost:Connect(function(enterPressed)
		safeCallback(config.Callback, box.Text, enterPressed)
	end)

	local object = {}
	function object:SetValue(value)
		box.Text = tostring(value)
	end

	function object:GetValue()
		return box.Text
	end

	object.Instance = holder
	return object
end

function Section:CreateKeybind(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors
	local saved = config.Flag and self.Page.Window.Library.ConfigData[config.Flag]
	local value = normalizeBindValue(saved or config.Default)
	local listening = false
	local flag = config.Flag

	local holder = create("Frame", {
		Name = config.Name or "Keybind",
		Size = UDim2.new(1, 0, 0, config.Description and 56 or 40),
		BackgroundTransparency = 1,
	})
	holder.Parent = self.Content

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -132, 0, 22),
		Position = UDim2.fromOffset(0, config.Description and 4 or 9),
		Text = config.Title or "Keybind",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(title, config.Description and "bodyLarge" or "bodyMedium", colors.onSurface)
	title.Parent = holder

	local description
	if config.Description then
		description = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(1, -132, 0, 18),
			Text = config.Description,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		applyTextStyle(description, "bodySmall", colors.onSurfaceVariant)
		description.Parent = holder
	end

	local chip = create("TextButton", {
		Name = "BindChip",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(120, 32),
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})
	applyCorner(chip, TOKENS.radius.full)
	applyStroke(chip, colors.outlineVariant, 0.78, 1)
	chip.Parent = holder

	local chipLabel = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	applyTextStyle(chipLabel, "labelLarge", colors.onSurface)
	chipLabel.Parent = chip

	local stateLayer = createStateLayer(chip, TOKENS.radius.full)
	stateLayer.BackgroundColor3 = colors.onSurface

	local function syncVisual()
		chipLabel.Text = listening and "Press key..." or formatBindValue(value)
		chip.BackgroundColor3 = listening and blendColor(colors.secondaryContainer, colors.primaryContainer, 0.2) or colors.surfaceContainerHigh
		chipLabel.TextColor3 = listening and colors.onSecondaryContainer or colors.onSurface
		stateLayer.BackgroundColor3 = listening and colors.onSecondaryContainer or colors.onSurface
	end

	local function setValue(newValue, fireChanged)
		value = normalizeBindValue(newValue)
		syncVisual()
		if fireChanged ~= false and config.ChangedCallback then
			safeCallback(config.ChangedCallback, value)
			self.Page.Window.Library:_SaveState()
		end
	end

	local function stopListening()
		listening = false
		syncVisual()
	end

	local function beginListening()
		listening = true
		syncVisual()
	end

	chip.MouseEnter:Connect(function()
		tween(stateLayer, TOKENS.motion.fast, {
			BackgroundTransparency = 1 - TOKENS.stateOpacity.hover,
		})
	end)

	chip.MouseLeave:Connect(function()
		tween(stateLayer, TOKENS.motion.fast, {
			BackgroundTransparency = 1,
		})
	end)

	chip.MouseButton1Down:Connect(function()
		stateLayer.BackgroundTransparency = 1 - TOKENS.stateOpacity.pressed
	end)

	chip.MouseButton1Up:Connect(function()
		stateLayer.BackgroundTransparency = 1 - TOKENS.stateOpacity.hover
	end)

	chip.Activated:Connect(function()
		if listening then
			stopListening()
		else
			beginListening()
		end
	end)

	table.insert(self.Page.Window.Library.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local focusedTextBox = UserInputService:GetFocusedTextBox()
		if focusedTextBox then
			return
		end

		if listening then
			if input.KeyCode == Enum.KeyCode.Escape then
				stopListening()
				return
			end

			if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
				setValue(nil, true)
				stopListening()
				return
			end

			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				setValue(input.KeyCode, true)
			elseif input.UserInputType ~= Enum.UserInputType.Keyboard then
				setValue(input.UserInputType.Name, true)
			end
			stopListening()
			return
		end

		if value and ((typeof(value) == "EnumItem" and input.KeyCode == value) or (type(value) == "string" and input.UserInputType.Name == value)) then
			safeCallback(config.Callback, value, input)
		end
	end))

	if description then
		description.TextWrapped = true
	end

	bindThemeUpdater(self.Page.Window, function(nextColors)
		colors = nextColors
		title.TextColor3 = colors.onSurface
		if description then
			description.TextColor3 = colors.onSurfaceVariant
		end
		local stroke = chip:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = colors.outlineVariant
		end
		syncVisual()
	end)

	syncVisual()

	local object = {}

	function object:SetValue(newValue)
		setValue(newValue, false)
		self.Page.Window.Library:_SaveState()
	end

	function object:GetValue()
		return value
	end

	object.Instance = holder
	object.Flag = flag
	self.Page.Window.Library:RegisterFlag(flag, object)
	return object
end

function Section:CreateDropdown(config)
	config = config or {}
	local colors = self.Page.Window.Library.Colors
	local values = config.Values or {}
	local saved = config.Flag and self.Page.Window.Library.ConfigData[config.Flag]
	local selected = saved or config.Default or values[1] or ""
	local multiSelect = config.MultiSelect == true or config.MultipleOptions == true
	local checkboxMode = config.DropdownCheckbox == true or config.CheckboxDropdown == true or config.Style == "Checkbox"
	local selectedValues = typeof(selected) == "table" and selected or { selected }
	local isOpen = false
	local optionStates = {}

	local holder = create("Frame", {
		Name = config.Name or "Dropdown",
		Size = UDim2.new(1, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})
	holder.Parent = self.Content

	local button = create("TextButton", {
		Name = "Main",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})
	applyCorner(button, TOKENS.radius.medium)
	applyStroke(button, colors.outlineVariant, 0.76, 1)
	button.Parent = holder

	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -52, 1, 0),
		Text = (config.Title or "Dropdown") .. ": " .. tostring(selected),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	applyTextStyle(label, "bodyLarge", colors.onSurface)
	label.Parent = button

	local chevron = create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Text = "v",
	})
	applyTextStyle(chevron, "labelLarge", colors.onSurfaceVariant)
	chevron.Parent = button

	local menu = create("Frame", {
		Name = "Menu",
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
	})
	applyCorner(menu, TOKENS.radius.medium)
	applyStroke(menu, colors.outlineVariant, 1, 1)
	applyPadding(menu, 8, 8, 8, 8)
	menu.Parent = holder

	local list = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	})
	list.Parent = menu

	local function updateLabel()
		if multiSelect then
			if checkboxMode then
				label.Text = (config.Title or "Dropdown") .. ": " .. (#selectedValues == 0 and "None" or tostring(#selectedValues) .. " selected")
			else
				label.Text = (config.Title or "Dropdown") .. ": " .. (#selectedValues == 0 and "None" or table.concat(selectedValues, ", "))
			end
		else
			label.Text = (config.Title or "Dropdown") .. ": " .. tostring(selectedValues[1] or "")
		end
	end

	local syncOptions

	local function setSelected(value)
		if multiSelect then
			local idx = table.find(selectedValues, value)
			if idx then
				table.remove(selectedValues, idx)
			else
				table.insert(selectedValues, value)
			end
		else
			selectedValues = { value }
		end
		updateLabel()
		syncOptions()
		safeCallback(config.Callback, multiSelect and selectedValues or selectedValues[1])
		self.Page.Window.Library:_SaveState()
	end

	local function isSelected(value)
		return table.find(selectedValues, value) ~= nil
	end

	function syncOptions()
		for _, state in ipairs(optionStates) do
			local active = isSelected(state.Value)
			state.Button.BackgroundColor3 = active and colors.secondaryContainer or colors.surfaceContainer
			state.Button.TextColor3 = active and colors.onSecondaryContainer or colors.onSurface
			if state.Marker then
				state.Marker.BackgroundColor3 = active and colors.primary or colors.surfaceContainerHighest
				local markerStroke = state.Marker:FindFirstChildOfClass("UIStroke")
				if markerStroke then
					markerStroke.Color = active and colors.primary or colors.outlineVariant
					markerStroke.Transparency = active and 1 or 0.45
				end
			end
			if state.Dot then
				state.Dot.BackgroundTransparency = active and 0 or 1
			end
		end
	end

	updateLabel()

	local function toggle(open)
		isOpen = open
		chevron.Text = open and "^" or "v"
		if open then
			bumpWindowZ(holder, self.Page.Window.Library)
			menu.Visible = true
			menu.Position = UDim2.fromOffset(0, 42)
			menu.BackgroundTransparency = 1
			local stroke = menu:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = 1
			end
			tween(menu, TOKENS.motion.normal, {
				Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 0,
			})
			if stroke then
				tween(stroke, TOKENS.motion.normal, {
					Transparency = 0.76,
				})
			end
		else
			local stroke = menu:FindFirstChildOfClass("UIStroke")
			tween(menu, TOKENS.motion.fast, {
				Position = UDim2.fromOffset(0, 42),
				BackgroundTransparency = 1,
			})
			if stroke then
				tween(stroke, TOKENS.motion.fast, {
					Transparency = 1,
				})
			end
			task.delay(0.14, function()
				if menu.Parent and not isOpen then
					menu.Visible = false
				end
			end)
		end
	end

	bindThemeUpdater(self.Page.Window, function(nextColors)
		colors = nextColors
		button.BackgroundColor3 = colors.surfaceContainerHigh
		label.TextColor3 = colors.onSurface
		chevron.TextColor3 = colors.onSurfaceVariant
		menu.BackgroundColor3 = colors.surfaceContainerHigh
		local buttonStroke = button:FindFirstChildOfClass("UIStroke")
		if buttonStroke then
			buttonStroke.Color = colors.outlineVariant
		end
		local menuStroke = menu:FindFirstChildOfClass("UIStroke")
		if menuStroke then
			menuStroke.Color = colors.outlineVariant
		end
		for _, child in ipairs(menu:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = colors.surfaceContainer
				child.TextColor3 = colors.onSurface
			end
		end
		syncOptions()
	end)

	for _, value in ipairs(values) do
		local option = create("TextButton", {
			Name = tostring(value),
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = colors.surfaceContainer,
			BorderSizePixel = 0,
			Text = tostring(value),
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
		})
		applyTextStyle(option, "bodyMedium", colors.onSurface)
		applyCorner(option, TOKENS.radius.small)
		applyPadding(option, 0, 14, 0, 14)
		option.Parent = menu

		local checkMark
		if checkboxMode and multiSelect then
			checkMark = create("TextLabel", {
				Name = "Check",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Text = "☐",
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			})
			applyTextStyle(checkMark, "labelLarge", colors.onSurfaceVariant)
			checkMark.Parent = option
		end

		local function syncOption()
			local active = isSelected(value)
			option.BackgroundColor3 = active and colors.secondaryContainer or colors.surfaceContainer
			option.TextColor3 = active and colors.onSecondaryContainer or colors.onSurface
			if checkMark then
				checkMark.Text = active and "☑" or "☐"
				checkMark.TextColor3 = active and colors.onSecondaryContainer or colors.onSurfaceVariant
			end
		end
		syncOption()

		option.Activated:Connect(function()
			setSelected(value)
			if not multiSelect then
				toggle(false)
			end
			for _, child in ipairs(menu:GetChildren()) do
				if child:IsA("TextButton") then
					local mark = child:FindFirstChild("Check")
					local active = table.find(selectedValues, child.Name) ~= nil
					child.BackgroundColor3 = active and colors.secondaryContainer or colors.surfaceContainer
					child.TextColor3 = active and colors.onSecondaryContainer or colors.onSurface
					if mark and mark:IsA("TextLabel") then
						mark.Text = active and "☑" or "☐"
						mark.TextColor3 = active and colors.onSecondaryContainer or colors.onSurfaceVariant
					end
				end
			end
		end)
	end

	button.Activated:Connect(function()
		toggle(not isOpen)
	end)

	local object = {}
	function object:SetValue(value)
		if multiSelect and typeof(value) == "table" then
			selectedValues = {}
			for _, entry in ipairs(value) do
				table.insert(selectedValues, entry)
			end
			updateLabel()
			syncOptions()
			self.Page.Window.Library:_SaveState()
			return
		end
		setSelected(value)
		self.Page.Window.Library:_SaveState()
	end

	function object:GetValue()
		return multiSelect and selectedValues or selectedValues[1]
	end

	object.Instance = holder
	object.Flag = config.Flag
	self.Page.Window.Library:RegisterFlag(config.Flag, object)
	return object
end

function Window:CreateDialog(config)
	config = config or {}
	local colors = self.Library.Colors

	local scrim = create("TextButton", {
		Name = config.Name or "Dialog",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.scrim,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 100,
	})
	scrim.Parent = self.Root

	local card = create("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 14),
		Size = UDim2.fromOffset(392, 228),
		BackgroundColor3 = elevatedSurface(colors, 0.08),
		BorderSizePixel = 0,
		ZIndex = 101,
	})
	applyCorner(card, TOKENS.radius.extraLarge)
	applyStroke(card, colors.outlineVariant, 0.82, 1)
	applyPadding(card, 24, 24, 24, 24)
	card.Parent = scrim

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Text = config.Title or "Dialog",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101,
	})
	applyTextStyle(title, "headlineSmall", colors.onSurface)
	title.Parent = card

	local body = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 90),
		Text = config.Content or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 101,
	})
	applyTextStyle(body, "bodyMedium", colors.onSurfaceVariant)
	body.Parent = card

	local actions = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 101,
	})
	actions.Parent = card

	local actionList = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	actionList.Parent = actions

	local dialog = {}
	dialog.Library = self.Library

	local function addAction(labelText, callback, primary)
		local action = create("TextButton", {
			Size = UDim2.fromOffset(100, 40),
			BackgroundColor3 = primary and colors.primary or colors.surfaceContainerHigh,
			BorderSizePixel = 0,
			Text = labelText,
			AutoButtonColor = false,
			ZIndex = 101,
		})
		applyTextStyle(action, "labelLarge", primary and colors.onPrimary or colors.onSurface)
		applyCorner(action, TOKENS.radius.full)
		local stateLayer = createStateLayer(action, TOKENS.radius.full)
		bindStateLayer(action, stateLayer, function()
			return primary and colors.onPrimary or colors.onSurface
		end)
		action.Parent = actions
		action.Activated:Connect(function()
			if callback then
				callback()
			end
			dialog:Hide()
		end)
	end

	addAction(config.CancelText or "Close", config.OnCancel, false)
	if config.ConfirmText then
		addAction(config.ConfirmText, config.OnConfirm, true)
	end

	function dialog:Show()
		bumpWindowZ(scrim, dialog.Library)
		scrim.Visible = true
		scrim.BackgroundTransparency = 1
		card.Size = UDim2.fromOffset(356, 200)
		card.Position = UDim2.new(0.5, 0, 0.5, 18)
		card.BackgroundTransparency = 1
		local cardStroke = card:FindFirstChildOfClass("UIStroke")
		if cardStroke then
			cardStroke.Transparency = 1
		end
		tween(scrim, TOKENS.motion.normal, {
			BackgroundTransparency = 0.52,
		})
		tween(card, TOKENS.motion.expressive, {
			Size = UDim2.fromOffset(392, 228),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 0,
		})
		if cardStroke then
			tween(cardStroke, TOKENS.motion.normal, {
				Transparency = 0.82,
			})
		end
	end

	function dialog:Hide()
		local cardStroke = card:FindFirstChildOfClass("UIStroke")
		tween(scrim, TOKENS.motion.fast, {
			BackgroundTransparency = 1,
		})
		tween(card, TOKENS.motion.normal, {
			Size = UDim2.fromOffset(356, 200),
			Position = UDim2.new(0.5, 0, 0.5, 18),
			BackgroundTransparency = 1,
		})
		if cardStroke then
			tween(cardStroke, TOKENS.motion.fast, {
				Transparency = 1,
			})
		end
		task.delay(0.2, function()
			scrim.Visible = false
		end)
	end

	dialog.Instance = scrim
	return dialog
end

function Window:Destroy()
	local blur = Lighting:FindFirstChild("Material3Blur")
	if blur and blur:IsA("BlurEffect") and blur.Parent == Lighting then
		pcall(function()
			blur.Enabled = false
			blur.Size = 0
		end)
	end
	for _, connection in ipairs(self.Library.Connections or {}) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end
	self.Library.Connections = {}
	if GENV and GENV.Material3Active == self then
		GENV.Material3Active = nil
	end
	if self.ScreenGui and self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end
end

function Window:ToggleVisibility()
	if self.ScreenGui then
		self.ScreenGui.Enabled = not self.ScreenGui.Enabled
	end
end

function Window:CreateTab(name, image, ext)
	return self:CreatePage({
		Name = name,
		Title = name,
		Image = image,
		Ext = ext,
	})
end

Material3.CreateWindow = function(config)
	return Material3.new(config)
end

return Material3
