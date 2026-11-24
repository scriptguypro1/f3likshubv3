print("[f3liks hub] Booting v3.5...")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local HUB_NAME = "f3liks hub"
local GUI_OBJECT_NAME = "f3liks_hub_v35_gui"
local ESP_FOLDER_NAME = "f3liks_hub_v35_esp"

local function getUiParent()
	local okGui, gui = pcall(function()
		return gethui and gethui()
	end)
	if okGui and gui and typeof(gui) == "Instance" then
		return gui
	end

	local okCore, core = pcall(function()
		return CoreGui
	end)
	if okCore and core and typeof(core) == "Instance" then
		return core
	end

	return LocalPlayer:WaitForChild("PlayerGui")
end

local function safeClipboard(txt)
	local ok = pcall(function()
		if setclipboard then
			setclipboard(tostring(txt))
		elseif toclipboard then
			toclipboard(tostring(txt))
		end
	end)
	return ok
end

local function getHumanoid()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function getRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function colorToHex(c)
	local r = math.clamp(math.round(c.R * 255), 0, 255)
	local g = math.clamp(math.round(c.G * 255), 0, 255)
	local b = math.clamp(math.round(c.B * 255), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function hexToColor(str)
	local clean = tostring(str or ""):gsub("#", ""):gsub("%s+", "")
	if #clean == 3 then
		clean = clean:sub(1, 1):rep(2) .. clean:sub(2, 2):rep(2) .. clean:sub(3, 3):rep(2)
	end
	if #clean ~= 6 or clean:match("[^0-9a-fA-F]") then
		return nil
	end
	local r = tonumber(clean:sub(1, 2), 16)
	local g = tonumber(clean:sub(3, 4), 16)
	local b = tonumber(clean:sub(5, 6), 16)
	return Color3.fromRGB(r, g, b)
end

local uiParent = getUiParent()
local existing = uiParent:FindFirstChild(GUI_OBJECT_NAME)
if existing then
	pcall(function() existing:Destroy() end)
end

local existingEsp = uiParent:FindFirstChild(ESP_FOLDER_NAME)
if existingEsp then
	pcall(function() existingEsp:Destroy() end)
end

local THEME = {
	BgMain = Color3.fromRGB(16, 17, 22),
	BgTop = Color3.fromRGB(23, 25, 33),
	BgSide = Color3.fromRGB(19, 21, 27),
	BgCard = Color3.fromRGB(27, 30, 39),
	BgCardAlt = Color3.fromRGB(35, 39, 51),
	BgInput = Color3.fromRGB(13, 14, 19),
	Stroke = Color3.fromRGB(48, 53, 68),
	Accent = Color3.fromRGB(110, 128, 255),
	AccentSoft = Color3.fromRGB(42, 50, 98),
	TextMain = Color3.fromRGB(244, 246, 250),
	TextSub = Color3.fromRGB(154, 161, 178),
	Success = Color3.fromRGB(64, 186, 132),
	Danger = Color3.fromRGB(235, 78, 94),
	Warn = Color3.fromRGB(245, 168, 38),
}

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end

local function addStroke(inst, col, thick)
	local s = Instance.new("UIStroke")
	s.Color = col or THEME.Stroke
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function addPadding(inst, pad)
	local p = Instance.new("UIPadding")
	local v = pad or 8
	p.PaddingTop = UDim.new(0, v)
	p.PaddingBottom = UDim.new(0, v)
	p.PaddingLeft = UDim.new(0, v)
	p.PaddingRight = UDim.new(0, v)
	p.Parent = inst
	return p
end

local function makeCard(parent, height, order)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, height or 50)
	f.LayoutOrder = order or 1
	f.BackgroundColor3 = THEME.BgCard
	f.BorderSizePixel = 0
	f.Parent = parent
	addCorner(f, 8)
	addStroke(f, THEME.Stroke, 1)
	return f
end

local function makeLabel(parent, text, size, bold, color, order)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, size and (size + 8) or 22)
	l.LayoutOrder = order or 1
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 13
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextColor3 = color or THEME.TextMain
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local function makeButton(parent, txt, col, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 104, 0, 30)
	b.BackgroundColor3 = col or THEME.BgCardAlt
	b.BorderSizePixel = 0
	b.Text = txt
	b.TextSize = 12
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = THEME.TextMain
	b.AutoButtonColor = true
	b.Parent = parent
	addCorner(b, 6)
	addStroke(b, THEME.Stroke, 1)
	b.MouseButton1Click:Connect(function()
		pcall(cb)
	end)
	return b
end

local function makeInput(parent, ph, def, w)
	local tb = Instance.new("TextBox")
	tb.Size = UDim2.new(0, w or 66, 0, 30)
	tb.BackgroundColor3 = THEME.BgInput
	tb.BorderSizePixel = 0
	tb.PlaceholderText = ph or ""
	tb.Text = tostring(def or "")
	tb.TextSize = 12
	tb.Font = Enum.Font.Code
	tb.TextColor3 = THEME.TextMain
	tb.PlaceholderColor3 = THEME.TextSub
	tb.ClearTextOnFocus = false
	tb.Parent = parent
	addCorner(tb, 6)
	addStroke(tb, THEME.Stroke, 1)
	return tb
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_OBJECT_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = uiParent

local reopenBtn = Instance.new("TextButton")
reopenBtn.Name = "ReopenBtn"
reopenBtn.Size = UDim2.new(0, 118, 0, 34)
reopenBtn.Position = UDim2.new(0, 12, 0.5, -17)
reopenBtn.BackgroundColor3 = THEME.BgTop
reopenBtn.BorderSizePixel = 0
reopenBtn.Text = HUB_NAME
reopenBtn.TextSize = 13
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextColor3 = THEME.TextMain
reopenBtn.Visible = false
reopenBtn.Parent = screenGui
addCorner(reopenBtn, 8)
local reopenStroke = addStroke(reopenBtn, THEME.Accent, 1.5)

local DEFAULT_POS = UDim2.new(0.5, -258, 0.5, -168)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = UDim2.new(0, 516, 0, 336)
mainFrame.Position = DEFAULT_POS
mainFrame.BackgroundColor3 = THEME.BgMain
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
addCorner(mainFrame, 10)
addStroke(mainFrame, THEME.Stroke, 1.5)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = THEME.BgTop
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
addCorner(topBar, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -104, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = HUB_NAME .. "  |  v3.5"
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = THEME.TextMain
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 24)
minBtn.Position = UDim2.new(1, -64, 0.5, -12)
minBtn.BackgroundColor3 = THEME.BgCardAlt
minBtn.Text = "-"
minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = THEME.TextMain
minBtn.Parent = topBar
addCorner(minBtn, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
closeBtn.BackgroundColor3 = THEME.Danger
closeBtn.Text = "X"
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = THEME.TextMain
closeBtn.Parent = topBar
addCorner(closeBtn, 6)

do
	local dragging = false
	local dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

minBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	reopenBtn.Visible = true
end)

reopenBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	reopenBtn.Visible = false
end)

local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 130, 1, -44)
sidebar.Position = UDim2.new(0, 6, 0, 40)
sidebar.BackgroundColor3 = THEME.BgSide
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 3
sidebar.CanvasSize = UDim2.new(0, 0, 0, 280)
sidebar.Parent = mainFrame
addCorner(sidebar, 8)
addStroke(sidebar, THEME.Stroke, 1)
addPadding(sidebar, 6)

local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 6)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = sidebar

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -144, 1, -44)
contentArea.Position = UDim2.new(0, 140, 0, 40)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local pages = {}
local tabButtons = {}
local activeTabName = "AI Builder"

local function createPage(name, order)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.Visible = false
	page.Parent = contentArea
	addPadding(page, 4)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
	end)

	pages[name] = page

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.LayoutOrder = order
	btn.BackgroundColor3 = THEME.BgCard
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = THEME.TextSub
	btn.Parent = sidebar
	addCorner(btn, 7)
	addStroke(btn, THEME.Stroke, 1)
	tabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		activeTabName = name
		for pName, pFrame in pairs(pages) do
			pFrame.Visible = (pName == name)
		end
		for bName, bInst in pairs(tabButtons) do
			local active = (bName == name)
			bInst.BackgroundColor3 = active and THEME.AccentSoft or THEME.BgCard
			bInst.TextColor3 = active and THEME.TextMain or THEME.TextSub
		end
	end)

	return page
end

local sharedOutputBox = nil
local sharedStatusLabel = nil

local function setOutputCode(codeStr, statusMsg)
	if sharedOutputBox then
		sharedOutputBox.Text = tostring(codeStr or "")
	end
	if sharedStatusLabel and statusMsg then
		sharedStatusLabel.Text = tostring(statusMsg)
	end
end

-- =========================================================
-- TAB 1: AI BUILDER
-- =========================================================
local aiPage = createPage("AI Builder", 1)
makeLabel(aiPage, "AI Script Prompt Creator", 14, true, THEME.TextMain, 1)
makeLabel(aiPage, "Slow reasoning steps by default, or toggle Fast mode anytime.", 11, false, THEME.TextSub, 2)

local promptCard = makeCard(aiPage, 74, 3)
addPadding(promptCard, 7)
local promptBox = Instance.new("TextBox")
promptBox.Size = UDim2.new(1, 0, 1, 0)
promptBox.BackgroundColor3 = THEME.BgInput
promptBox.BorderSizePixel = 0
promptBox.MultiLine = true
promptBox.ClearTextOnFocus = false
promptBox.TextWrapped = true
promptBox.TextXAlignment = Enum.TextXAlignment.Left
promptBox.TextYAlignment = Enum.TextYAlignment.Top
promptBox.Font = Enum.Font.Code
promptBox.TextSize = 12
promptBox.TextColor3 = THEME.TextMain
promptBox.PlaceholderColor3 = THEME.TextSub
promptBox.Text = "Create a bunnyhop auto-jump + speed boost utility"
promptBox.Parent = promptCard
addCorner(promptBox, 6)
addStroke(promptBox, THEME.Stroke, 1)

local aiCtrlCard = makeCard(aiPage, 44, 4)
addPadding(aiCtrlCard, 7)
local stepSecBox = makeInput(aiCtrlCard, "1.2", "1.2", 48)
stepSecBox.Position = UDim2.new(0, 0, 0.5, -15)

local fastModeOn = false
local fastBtn = makeButton(aiCtrlCard, "Mode: Slow", THEME.BgCardAlt, function() end)
fastBtn.Size = UDim2.new(0, 86, 0, 28)
fastBtn.Position = UDim2.new(0, 54, 0.5, -14)
fastBtn.MouseButton1Click:Connect(function()
	fastModeOn = not fastModeOn
	fastBtn.Text = fastModeOn and "Mode: Fast" or "Mode: Slow"
	fastBtn.BackgroundColor3 = fastModeOn and THEME.AccentSoft or THEME.BgCardAlt
end)

local autoSendOn = true
local autoSendBtn = makeButton(aiCtrlCard, "AutoSend: ON", THEME.Success, function() end)
autoSendBtn.Size = UDim2.new(0, 94, 0, 28)
autoSendBtn.Position = UDim2.new(0, 146, 0.5, -14)
autoSendBtn.MouseButton1Click:Connect(function()
	autoSendOn = not autoSendOn
	autoSendBtn.Text = autoSendOn and "AutoSend: ON" or "AutoSend: OFF"
	autoSendBtn.BackgroundColor3 = autoSendOn and THEME.Success or THEME.BgCardAlt
end)

local thinkBtn = makeButton(aiCtrlCard, "Think & Build", THEME.Accent, function() end)
thinkBtn.Size = UDim2.new(0, 102, 0, 28)
thinkBtn.Position = UDim2.new(1, -102, 0.5, -14)

local presetRow = makeCard(aiPage, 42, 5)
addPadding(presetRow, 6)
local p1 = makeButton(presetRow, "Spin + Speed", THEME.BgCardAlt, function()
	promptBox.Text = "Smooth spin rotation with WalkSpeed boost"
end)
p1.Size = UDim2.new(0, 96, 0, 28)
p1.Position = UDim2.new(0, 0, 0.5, -14)

local p2 = makeButton(presetRow, "Bunnyhop", THEME.BgCardAlt, function()
	promptBox.Text = "Auto bunnyhop jump when moving"
end)
p2.Size = UDim2.new(0, 86, 0, 28)
p2.Position = UDim2.new(0, 102, 0.5, -14)

local p3 = makeButton(presetRow, "Hover Float", THEME.BgCardAlt, function()
	promptBox.Text = "Safe hover float above ground with toggle"
end)
p3.Size = UDim2.new(0, 96, 0, 28)
p3.Position = UDim2.new(0, 194, 0.5, -14)

local p4 = makeButton(presetRow, "Player ESP", THEME.BgCardAlt, function()
	promptBox.Text = "Highlight other players cleanly with ESP"
end)
p4.Size = UDim2.new(0, 86, 0, 28)
p4.Position = UDim2.new(1, -86, 0.5, -14)

local thinkCard = makeCard(aiPage, 148, 6)
addPadding(thinkCard, 7)
local thinkTitle = Instance.new("TextLabel")
thinkTitle.Size = UDim2.new(1, 0, 0, 18)
thinkTitle.BackgroundTransparency = 1
thinkTitle.Text = "Thinking Process (Idle)"
thinkTitle.TextSize = 12
thinkTitle.Font = Enum.Font.GothamBold
thinkTitle.TextColor3 = THEME.Warn
thinkTitle.TextXAlignment = Enum.TextXAlignment.Left
thinkTitle.Parent = thinkCard

local thinkLog = Instance.new("TextBox")
thinkLog.Size = UDim2.new(1, 0, 1, -22)
thinkLog.Position = UDim2.new(0, 0, 0, 22)
thinkLog.BackgroundColor3 = THEME.BgInput
thinkLog.BorderSizePixel = 0
thinkLog.MultiLine = true
thinkLog.TextEditable = false
thinkLog.ClearTextOnFocus = false
thinkLog.TextWrapped = true
thinkLog.TextXAlignment = Enum.TextXAlignment.Left
thinkLog.TextYAlignment = Enum.TextYAlignment.Top
thinkLog.Font = Enum.Font.Code
thinkLog.TextSize = 11
thinkLog.TextColor3 = THEME.TextSub
thinkLog.Text = "Ready. Press 'Think & Build' to step through reasoning."
thinkLog.Parent = thinkCard
addCorner(thinkLog, 6)
addStroke(thinkLog, THEME.Stroke, 1)

local outPreviewCard = makeCard(aiPage, 146, 7)
addPadding(outPreviewCard, 7)
local outPreviewTitle = Instance.new("TextLabel")
outPreviewTitle.Size = UDim2.new(1, 0, 0, 18)
outPreviewTitle.BackgroundTransparency = 1
outPreviewTitle.Text = "Generated Script"
outPreviewTitle.TextSize = 12
outPreviewTitle.Font = Enum.Font.GothamBold
outPreviewTitle.TextColor3 = THEME.Success
outPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
outPreviewTitle.Parent = outPreviewCard

local genBox = Instance.new("TextBox")
genBox.Size = UDim2.new(1, 0, 1, -44)
genBox.Position = UDim2.new(0, 0, 0, 20)
genBox.BackgroundColor3 = THEME.BgInput
genBox.BorderSizePixel = 0
genBox.MultiLine = true
genBox.ClearTextOnFocus = false
genBox.TextWrapped = false
genBox.TextXAlignment = Enum.TextXAlignment.Left
genBox.TextYAlignment = Enum.TextYAlignment.Top
genBox.Font = Enum.Font.Code
genBox.TextSize = 11
genBox.TextColor3 = THEME.TextMain
genBox.Text = "-- Generated code appears here."
genBox.Parent = outPreviewCard
addCorner(genBox, 6)
addStroke(genBox, THEME.Stroke, 1)

local copyAiBtn = makeButton(outPreviewCard, "Copy Code", THEME.BgCardAlt, function()
	safeClipboard(genBox.Text)
end)
copyAiBtn.Size = UDim2.new(0, 96, 0, 20)
copyAiBtn.Position = UDim2.new(1, -96, 1, -20)

local thinkingActive = false
local thinkToken = 0

local function composeAiScript(promptStr)
	local q = string.lower(tostring(promptStr or ""))
	if string.find(q, "bunny") or string.find(q, "bhop") or string.find(q, "auto jump") then
		return table.concat({
			"-- f3liks hub v3.5 AI Builder",
			"local Players = game:GetService('Players')",
			"local RunService = game:GetService('RunService')",
			"local lp = Players.LocalPlayer",
			"local bhopOn = true",
			"RunService.Heartbeat:Connect(function()",
			"\tif not bhopOn then return end",
			"\tlocal hum = lp.Character and lp.Character:FindFirstChildOfClass('Humanoid')",
			"\tif hum and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then",
			"\t\thum:ChangeState(Enum.HumanoidStateType.Jumping)",
			"\tend",
			"end)",
			"print('[f3liks hub] Bunnyhop active.')"
		}, "\n")
	elseif string.find(q, "spin") or string.find(q, "orbit") then
		return table.concat({
			"-- f3liks hub v3.5 AI Builder",
			"local Players = game:GetService('Players')",
			"local RunService = game:GetService('RunService')",
			"local lp = Players.LocalPlayer",
			"local spinning = true",
			"RunService.RenderStepped:Connect(function(dt)",
			"\tif not spinning then return end",
			"\tlocal hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')",
			"\tif hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(220 * dt), 0) end",
			"end)",
			"print('[f3liks hub] Spin active.')"
		}, "\n")
	elseif string.find(q, "hover") or string.find(q, "float") or string.find(q, "fly") then
		return table.concat({
			"-- f3liks hub v3.5 AI Builder",
			"local lp = game:GetService('Players').LocalPlayer",
			"local RunService = game:GetService('RunService')",
			"local hovering = true",
			"RunService.Heartbeat:Connect(function()",
			"\tif not hovering then return end",
			"\tlocal hrp = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')",
			"\tif hrp then",
			"\t\thrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 2, hrp.AssemblyLinearVelocity.Z)",
			"\tend",
			"end)",
			"print('[f3liks hub] Hover float active.')"
		}, "\n")
	elseif string.find(q, "esp") or string.find(q, "highlight") then
		return table.concat({
			"-- f3liks hub v3.5 AI Builder",
			"local Players = game:GetService('Players')",
			"local lp = Players.LocalPlayer",
			"for _, plr in ipairs(Players:GetPlayers()) do",
			"\tif plr ~= lp and plr.Character and not plr.Character:FindFirstChild('f3liks_esp_hl') then",
			"\t\tlocal hl = Instance.new('Highlight')",
			"\t\thl.Name = 'f3liks_esp_hl'",
			"\t\thl.FillTransparency = 0.65",
			"\t\thl.Parent = plr.Character",
			"\tend",
			"end",
			"print('[f3liks hub] ESP applied.')"
		}, "\n")
	else
		return table.concat({
			"-- f3liks hub v3.5 AI Builder",
			"-- Prompt: " .. tostring(promptStr),
			"local lp = game:GetService('Players').LocalPlayer",
			"local hum = (lp.Character or lp.CharacterAdded:Wait()):WaitForChild('Humanoid')",
			"hum.UseJumpPower = true",
			"hum.WalkSpeed = 32",
			"hum.JumpPower = 75",
			"print('[f3liks hub] Speed=32 & Jump=75 applied.')"
		}, "\n")
	end
end

thinkBtn.MouseButton1Click:Connect(function()
	if thinkingActive then
		thinkToken += 1
		thinkingActive = false
		thinkBtn.Text = "Think & Build"
		thinkTitle.Text = "Thinking Process (Stopped)"
		return
	end

	thinkingActive = true
	thinkToken += 1
	local myToken = thinkToken
	thinkBtn.Text = "Stop"
	thinkTitle.Text = "Thinking Process (Running...)"

	local stepWait = fastModeOn and 0.15 or math.clamp(tonumber(stepSecBox.Text) or 1.2, 0.3, 5.0)
	local userReq = promptBox.Text ~= "" and promptBox.Text or "Utility script"

	local steps = {
		"Analyzing prompt: '" .. userReq .. "'",
		"Selecting Roblox services & checking nil safety...",
		"Structuring movement/visual/loop logic for mobile...",
		"Verifying clean toggle state & zero syntax issues...",
		"Writing final Luau script..."
	}

	task.spawn(function()
		local lines = {}
		for idx, msg in ipairs(steps) do
			if thinkToken ~= myToken then return end
			table.insert(lines, string.format("[%.1fs] (%d/%d) %s", (idx - 1) * stepWait, idx, #steps, msg))
			thinkLog.Text = table.concat(lines, "\n")
			task.wait(stepWait)
		end

		if thinkToken ~= myToken then return end
		local finalCode = composeAiScript(userReq)
		table.insert(lines, string.format("[%.1fs] Done!", #steps * stepWait))
		thinkLog.Text = table.concat(lines, "\n")
		thinkTitle.Text = "Thinking Process (Completed)"
		genBox.Text = finalCode
		if autoSendOn then
			setOutputCode(finalCode, "AI Builder sent script to Tools & Console.")
		end
		thinkingActive = false
		thinkBtn.Text = "Think & Build"
	end)
end)

-- =========================================================
-- TAB 2: MOVEMENT
-- =========================================================
local movePage = createPage("Movement", 2)
makeLabel(movePage, "Movement, Physics & Jumps", 14, true, THEME.TextMain, 1)

local noclipOn = false
local infJumpOn = false
local clickTpOn = false
local spinOn = false
local bhopOn = false

local wsCard = makeCard(movePage, 50, 2)
addPadding(wsCard, 7)
local wsLbl = Instance.new("TextLabel")
wsLbl.Size = UDim2.new(0.38, 0, 1, 0)
wsLbl.BackgroundTransparency = 1
wsLbl.Text = "WalkSpeed"
wsLbl.TextSize = 13
wsLbl.Font = Enum.Font.GothamBold
wsLbl.TextColor3 = THEME.TextMain
wsLbl.TextXAlignment = Enum.TextXAlignment.Left
wsLbl.Parent = wsCard

local wsBox = makeInput(wsCard, "16", "28", 54)
wsBox.Position = UDim2.new(1, -190, 0.5, -15)

local wsSet = makeButton(wsCard, "Apply", THEME.Accent, function()
	local hum = getHumanoid()
	local n = tonumber(wsBox.Text)
	if hum and n then hum.WalkSpeed = math.clamp(n, 0, 250) end
end)
wsSet.Size = UDim2.new(0, 72, 0, 30)
wsSet.Position = UDim2.new(1, -130, 0.5, -15)

local wsDef = makeButton(wsCard, "16", THEME.BgCardAlt, function()
	local hum = getHumanoid()
	wsBox.Text = "16"
	if hum then hum.WalkSpeed = 16 end
end)
wsDef.Size = UDim2.new(0, 52, 0, 30)
wsDef.Position = UDim2.new(1, -52, 0.5, -15)

local jpCard = makeCard(movePage, 50, 3)
addPadding(jpCard, 7)
local jpLbl = Instance.new("TextLabel")
jpLbl.Size = UDim2.new(0.38, 0, 1, 0)
jpLbl.BackgroundTransparency = 1
jpLbl.Text = "JumpPower"
jpLbl.TextSize = 13
jpLbl.Font = Enum.Font.GothamBold
jpLbl.TextColor3 = THEME.TextMain
jpLbl.TextXAlignment = Enum.TextXAlignment.Left
jpLbl.Parent = jpCard

local jpBox = makeInput(jpCard, "50", "75", 54)
jpBox.Position = UDim2.new(1, -190, 0.5, -15)

local jpSet = makeButton(jpCard, "Apply", THEME.Accent, function()
	local hum = getHumanoid()
	local n = tonumber(jpBox.Text)
	if hum and n then
		hum.UseJumpPower = true
		hum.JumpPower = math.clamp(n, 0, 300)
	end
end)
jpSet.Size = UDim2.new(0, 72, 0, 30)
jpSet.Position = UDim2.new(1, -130, 0.5, -15)

local jpDef = makeButton(jpCard, "50", THEME.BgCardAlt, function()
	local hum = getHumanoid()
	jpBox.Text = "50"
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = 50
	end
end)
jpDef.Size = UDim2.new(0, 52, 0, 30)
jpDef.Position = UDim2.new(1, -52, 0.5, -15)

local gravCard = makeCard(movePage, 50, 4)
addPadding(gravCard, 7)
local gravLbl = Instance.new("TextLabel")
gravLbl.Size = UDim2.new(0.38, 0, 1, 0)
gravLbl.BackgroundTransparency = 1
gravLbl.Text = "Gravity"
gravLbl.TextSize = 13
gravLbl.Font = Enum.Font.GothamBold
gravLbl.TextColor3 = THEME.TextMain
gravLbl.TextXAlignment = Enum.TextXAlignment.Left
gravLbl.Parent = gravCard

local gravBox = makeInput(gravCard, "196.2", "95", 54)
gravBox.Position = UDim2.new(1, -190, 0.5, -15)

local gravSet = makeButton(gravCard, "Apply", THEME.Accent, function()
	local n = tonumber(gravBox.Text)
	if n then workspace.Gravity = math.clamp(n, 0, 500) end
end)
gravSet.Size = UDim2.new(0, 72, 0, 30)
gravSet.Position = UDim2.new(1, -130, 0.5, -15)

local gravDef = makeButton(gravCard, "Def", THEME.BgCardAlt, function()
	gravBox.Text = "196.2"
	workspace.Gravity = 196.2
end)
gravDef.Size = UDim2.new(0, 52, 0, 30)
gravDef.Position = UDim2.new(1, -52, 0.5, -15)

local function makeToggleCard(parent, order, titleText, callback)
	local card = makeCard(parent, 46, order)
	addPadding(card, 7)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.72, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = THEME.TextMain
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card

	local state = false
	local btn
	btn = makeButton(card, "OFF", THEME.BgCardAlt, function()
		state = not state
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and THEME.Success or THEME.BgCardAlt
		callback(state)
	end)
	btn.Size = UDim2.new(0, 70, 0, 28)
	btn.Position = UDim2.new(1, -70, 0.5, -14)
	return btn
end

makeToggleCard(movePage, 5, "Noclip", function(s) noclipOn = s end)
makeToggleCard(movePage, 6, "Infinite Jump", function(s) infJumpOn = s end)
makeToggleCard(movePage, 7, "Auto Bunnyhop", function(s) bhopOn = s end)
makeToggleCard(movePage, 8, "Tap / Click Teleport", function(s) clickTpOn = s end)
makeToggleCard(movePage, 9, "Character Spin", function(s) spinOn = s end)

RunService.Stepped:Connect(function()
	if noclipOn and LocalPlayer.Character then
		for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if bhopOn then
		local hum = getHumanoid()
		if hum and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if spinOn then
		local hrp = getRoot()
		if hrp then
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(220 * dt), 0)
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpOn then
		local hum = getHumanoid()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not clickTpOn then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local cam = workspace.CurrentCamera
		local hrp = getRoot()
		if cam and hrp then
			local ray = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
			local res = workspace:Raycast(ray.Origin, ray.Direction * 500)
			if res then
				hrp.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0))
			end
		end
	end
end)

-- =========================================================
-- TAB 3: VISUALS
-- =========================================================
local visPage = createPage("Visuals", 3)
makeLabel(visPage, "Lighting, ESP & Camera", 14, true, THEME.TextMain, 1)

local espFolder = Instance.new("Folder")
espFolder.Name = ESP_FOLDER_NAME
espFolder.Parent = uiParent

local espActive = false
local function refreshEsp()
	espFolder:ClearAllChildren()
	if not espActive then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hl = Instance.new("Highlight")
			hl.FillColor = THEME.Accent
			hl.OutlineColor = THEME.TextMain
			hl.FillTransparency = 0.65
			hl.OutlineTransparency = 0.1
			hl.Adornee = plr.Character
			hl.Parent = espFolder
		end
	end
end

makeToggleCard(visPage, 2, "Fullbright", function(on)
	if on then
		Lighting.Brightness = 2.5
		Lighting.GlobalShadows = false
		Lighting.ClockTime = 14
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
	end
end)

makeToggleCard(visPage, 3, "Remove Fog / Atmosphere", function(on)
	if on then
		Lighting.FogEnd = 1e6
		for _, c in ipairs(Lighting:GetChildren()) do
			if c:IsA("Atmosphere") then c.Density = 0 end
		end
	else
		Lighting.FogEnd = 10000
	end
end)

makeToggleCard(visPage, 4, "Bright Ambient Tint", function(on)
	Lighting.Ambient = on and Color3.fromRGB(190, 190, 210) or Color3.fromRGB(120, 120, 120)
	Lighting.OutdoorAmbient = on and Color3.fromRGB(200, 200, 220) or Color3.fromRGB(128, 128, 128)
end)

makeToggleCard(visPage, 5, "Player ESP Highlights", function(on)
	espActive = on
	refreshEsp()
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		if espActive then task.wait(0.3); refreshEsp() end
	end)
end)

local fxCard = makeCard(visPage, 48, 6)
addPadding(fxCard, 7)
local fxLbl = Instance.new("TextLabel")
fxLbl.Size = UDim2.new(0.45, 0, 1, 0)
fxLbl.BackgroundTransparency = 1
fxLbl.Text = "FX & ESP Tools"
fxLbl.TextSize = 12
fxLbl.Font = Enum.Font.GothamBold
fxLbl.TextColor3 = THEME.TextMain
fxLbl.TextXAlignment = Enum.TextXAlignment.Left
fxLbl.Parent = fxCard

local fxBtn = makeButton(fxCard, "No Blur/FX", THEME.BgCardAlt, function()
	for _, inst in ipairs(Lighting:GetChildren()) do
		if inst:IsA("BlurEffect") or inst:IsA("BloomEffect") or inst:IsA("SunRaysEffect") then
			inst.Enabled = false
		end
	end
end)
fxBtn.Size = UDim2.new(0, 88, 0, 28)
fxBtn.Position = UDim2.new(1, -182, 0.5, -14)

local refEspBtn = makeButton(fxCard, "Sync ESP", THEME.Accent, function()
	refreshEsp()
end)
refEspBtn.Size = UDim2.new(0, 88, 0, 28)
refEspBtn.Position = UDim2.new(1, -88, 0.5, -14)

local fovCard = makeCard(visPage, 50, 7)
addPadding(fovCard, 7)
local fovLbl = Instance.new("TextLabel")
fovLbl.Size = UDim2.new(0.36, 0, 1, 0)
fovLbl.BackgroundTransparency = 1
fovLbl.Text = "Camera FOV"
fovLbl.TextSize = 13
fovLbl.Font = Enum.Font.GothamBold
fovLbl.TextColor3 = THEME.TextMain
fovLbl.TextXAlignment = Enum.TextXAlignment.Left
fovLbl.Parent = fovCard

local fovBox = makeInput(fovCard, "70", "90", 52)
fovBox.Position = UDim2.new(1, -182, 0.5, -15)

local fovApply = makeButton(fovCard, "Set", THEME.Accent, function()
	local cam = workspace.CurrentCamera
	local v = tonumber(fovBox.Text)
	if cam and v then cam.FieldOfView = math.clamp(v, 35, 120) end
end)
fovApply.Size = UDim2.new(0, 68, 0, 30)
fovApply.Position = UDim2.new(1, -124, 0.5, -15)

local fovReset = makeButton(fovCard, "70", THEME.BgCardAlt, function()
	local cam = workspace.CurrentCamera
	fovBox.Text = "70"
	if cam then cam.FieldOfView = 70 end
end)
fovReset.Size = UDim2.new(0, 50, 0, 30)
fovReset.Position = UDim2.new(1, -50, 0.5, -15)

-- =========================================================
-- TAB 4: PLAYER & SERVER
-- =========================================================
local srvPage = createPage("Player & Server", 4)
makeLabel(srvPage, "Player, Teleport & Server", 14, true, THEME.TextMain, 1)

local srvInfoCard = makeCard(srvPage, 88, 2)
addPadding(srvInfoCard, 7)
local srvInfoLbl = Instance.new("TextLabel")
srvInfoLbl.Size = UDim2.new(1, 0, 1, 0)
srvInfoLbl.BackgroundTransparency = 1
srvInfoLbl.TextWrapped = true
srvInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
srvInfoLbl.TextYAlignment = Enum.TextYAlignment.Top
srvInfoLbl.Font = Enum.Font.Code
srvInfoLbl.TextSize = 11
srvInfoLbl.TextColor3 = THEME.TextSub
srvInfoLbl.Text = string.format(
	"PlaceId: %s\nJobId: %s\nPlayers: %d/%d",
	tostring(game.PlaceId),
	tostring(game.JobId),
	#Players:GetPlayers(),
	Players.MaxPlayers
)
srvInfoLbl.Parent = srvInfoCard

local tpPlrCard = makeCard(srvPage, 50, 3)
addPadding(tpPlrCard, 7)
local tpPlrBox = makeInput(tpPlrCard, "Username", "", 165)
tpPlrBox.Position = UDim2.new(0, 0, 0.5, -15)

local tpPlrBtn = makeButton(tpPlrCard, "TP to Player", THEME.Accent, function()
	local targetName = string.lower(tpPlrBox.Text or "")
	local myRoot = getRoot()
	if targetName == "" or not myRoot then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.find(string.lower(plr.Name), targetName, 1, true)
			or string.find(string.lower(plr.DisplayName), targetName, 1, true) then
			local tRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if tRoot then
				myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, -3)
			end
			break
		end
	end
end)
tpPlrBtn.Size = UDim2.new(0, 112, 0, 30)
tpPlrBtn.Position = UDim2.new(1, -112, 0.5, -15)

local afkOn = false
makeToggleCard(srvPage, 4, "Anti-AFK", function(s) afkOn = s end)

LocalPlayer.Idled:Connect(function()
	if afkOn then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

local srvActCard = makeCard(srvPage, 50, 5)
addPadding(srvActCard, 7)

local respBtn = makeButton(srvActCard, "Respawn", THEME.BgCardAlt, function()
	local hum = getHumanoid()
	if hum then hum.Health = 0 end
end)
respBtn.Size = UDim2.new(0, 82, 0, 30)
respBtn.Position = UDim2.new(0, 0, 0.5, -15)

local copyIdBtn = makeButton(srvActCard, "Copy JobId", THEME.BgCardAlt, function()
	safeClipboard(tostring(game.JobId))
end)
copyIdBtn.Size = UDim2.new(0, 92, 0, 30)
copyIdBtn.Position = UDim2.new(0, 88, 0.5, -15)

local hopBtn = makeButton(srvActCard, "Server Hop", THEME.Accent, function()
	pcall(function()
		local url = string.format(
			"https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=25",
			tostring(game.PlaceId)
		)
		local raw = game:HttpGet(url)
		local data = HttpService:JSONDecode(raw)
		if data and data.data then
			for _, srv in ipairs(data.data) do
				if tostring(srv.id) ~= tostring(game.JobId) and (srv.playing or 0) < (srv.maxPlayers or 99) then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
					return
				end
			end
		end
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
end)
hopBtn.Size = UDim2.new(0, 102, 0, 30)
hopBtn.Position = UDim2.new(1, -102, 0.5, -15)

-- =========================================================
-- TAB 5: THEME & COLORS (COLOR WHEEL SPECTRUM + HEX)
-- =========================================================
local colorPage = createPage("Theme & Colors", 5)
makeLabel(colorPage, "ScreenGui Color Wheel & Hex", 14, true, THEME.TextMain, 1)
makeLabel(colorPage, "Pick a target, tap the color wheel bar or step hue, or enter a hex code.", 11, false, THEME.TextSub, 2)

local colorTarget = "Accent"
local currentHue = 0.64

local targetCard = makeCard(colorPage, 46, 3)
addPadding(targetCard, 6)
local tAccent = makeButton(targetCard, "Accent", THEME.AccentSoft, function() end)
local tMain = makeButton(targetCard, "Main BG", THEME.BgCardAlt, function() end)
local tTop = makeButton(targetCard, "Top Bar", THEME.BgCardAlt, function() end)
local tCard = makeButton(targetCard, "Card BG", THEME.BgCardAlt, function() end)

local targetButtons = {
	Accent = tAccent,
	["Main BG"] = tMain,
	["Top Bar"] = tTop,
	["Card BG"] = tCard,
}

for idx, b in ipairs({ tAccent, tMain, tTop, tCard }) do
	b.Size = UDim2.new(0, 82, 0, 28)
	b.Position = UDim2.new(0, (idx - 1) * 88, 0.5, -14)
end

local hexBox
local previewSwatch

local function refreshTabHighlights()
	for bName, bInst in pairs(tabButtons) do
		local isAct = (bName == activeTabName)
		bInst.BackgroundColor3 = isAct and THEME.AccentSoft or THEME.BgCard
		bInst.TextColor3 = isAct and THEME.TextMain or THEME.TextSub
	end
end

local function applyColorToTarget(col)
	if colorTarget == "Accent" then
		THEME.Accent = col
		THEME.AccentSoft = Color3.new(col.R * 0.35, col.G * 0.35, col.B * 0.55)
		reopenStroke.Color = col
	elseif colorTarget == "Main BG" then
		THEME.BgMain = col
		mainFrame.BackgroundColor3 = col
	elseif colorTarget == "Top Bar" then
		THEME.BgTop = col
		topBar.BackgroundColor3 = col
		reopenBtn.BackgroundColor3 = col
	elseif colorTarget == "Card BG" then
		THEME.BgCard = col
		for _, pg in pairs(pages) do
			for _, child in ipairs(pg:GetChildren()) do
				if child:IsA("Frame") then
					child.BackgroundColor3 = col
				end
			end
		end
	end
	refreshTabHighlights()
	if previewSwatch then
		previewSwatch.BackgroundColor3 = col
	end
	if hexBox then
		hexBox.Text = colorToHex(col)
	end
end

for name, btn in pairs(targetButtons) do
	btn.MouseButton1Click:Connect(function()
		colorTarget = name
		for k, b in pairs(targetButtons) do
			b.BackgroundColor3 = (k == name) and THEME.AccentSoft or THEME.BgCardAlt
		end
		local activeCol = THEME.Accent
		if name == "Main BG" then activeCol = THEME.BgMain
		elseif name == "Top Bar" then activeCol = THEME.BgTop
		elseif name == "Card BG" then activeCol = THEME.BgCard end
		if previewSwatch then previewSwatch.BackgroundColor3 = activeCol end
		if hexBox then hexBox.Text = colorToHex(activeCol) end
	end)
end

-- Color Wheel / Hue Spectrum Bar Card
local wheelCard = makeCard(colorPage, 78, 4)
addPadding(wheelCard, 7)

local wheelLbl = Instance.new("TextLabel")
wheelLbl.Size = UDim2.new(0.65, 0, 0, 18)
wheelLbl.BackgroundTransparency = 1
wheelLbl.Text = "Color Wheel Spectrum (Tap or Drag)"
wheelLbl.TextSize = 11
wheelLbl.Font = Enum.Font.GothamBold
wheelLbl.TextColor3 = THEME.TextMain
wheelLbl.TextXAlignment = Enum.TextXAlignment.Left
wheelLbl.Parent = wheelCard

previewSwatch = Instance.new("Frame")
previewSwatch.Size = UDim2.new(0, 56, 0, 18)
previewSwatch.Position = UDim2.new(1, -56, 0, 0)
previewSwatch.BackgroundColor3 = THEME.Accent
previewSwatch.BorderSizePixel = 0
previewSwatch.Parent = wheelCard
addCorner(previewSwatch, 4)
addStroke(previewSwatch, THEME.TextMain, 1)

local hueBar = Instance.new("TextButton")
hueBar.Size = UDim2.new(1, -126, 0, 24)
hueBar.Position = UDim2.new(0, 0, 0, 24)
hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
hueBar.BorderSizePixel = 0
hueBar.Text = ""
hueBar.AutoButtonColor = false
hueBar.Parent = wheelCard
addCorner(hueBar, 6)
addStroke(hueBar, THEME.Stroke, 1)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})
grad.Parent = hueBar

local minusHue = makeButton(wheelCard, "-Hue", THEME.BgCardAlt, function()
	currentHue = (currentHue - 0.05) % 1
	applyColorToTarget(Color3.fromHSV(currentHue, 0.85, 0.98))
end)
minusHue.Size = UDim2.new(0, 58, 0, 24)
minusHue.Position = UDim2.new(1, -120, 0, 24)

local plusHue = makeButton(wheelCard, "+Hue", THEME.BgCardAlt, function()
	currentHue = (currentHue + 0.05) % 1
	applyColorToTarget(Color3.fromHSV(currentHue, 0.85, 0.98))
end)
plusHue.Size = UDim2.new(0, 58, 0, 24)
plusHue.Position = UDim2.new(1, -58, 0, 24)

local pickingHue = false
local function updateHueFromX(absX)
	local rel = math.clamp((absX - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
	currentHue = rel
	applyColorToTarget(Color3.fromHSV(currentHue, 0.85, 0.98))
end

hueBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pickingHue = true
		updateHueFromX(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if pickingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateHueFromX(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pickingHue = false
	end
end)

-- Hex Code Box Card right under Color Wheel
local hexCard = makeCard(colorPage, 52, 5)
addPadding(hexCard, 7)

local hexLbl = Instance.new("TextLabel")
hexLbl.Size = UDim2.new(0, 74, 1, 0)
hexLbl.BackgroundTransparency = 1
hexLbl.Text = "Hex Code:"
hexLbl.TextSize = 12
hexLbl.Font = Enum.Font.GothamBold
hexLbl.TextColor3 = THEME.TextMain
hexLbl.TextXAlignment = Enum.TextXAlignment.Left
hexLbl.Parent = hexCard

hexBox = makeInput(hexCard, "#6E80FF", colorToHex(THEME.Accent), 112)
hexBox.Position = UDim2.new(0, 74, 0.5, -15)

local applyHexBtn = makeButton(hexCard, "Apply Hex", THEME.Accent, function()
	local parsed = hexToColor(hexBox.Text)
	if parsed then
		applyColorToTarget(parsed)
	end
end)
applyHexBtn.Size = UDim2.new(0, 84, 0, 30)
applyHexBtn.Position = UDim2.new(1, -174, 0.5, -15)

local copyHexBtn = makeButton(hexCard, "Copy Hex", THEME.BgCardAlt, function()
	safeClipboard(hexBox.Text)
end)
copyHexBtn.Size = UDim2.new(0, 82, 0, 30)
copyHexBtn.Position = UDim2.new(1, -82, 0.5, -15)

-- Quick Swatch Row
local swatchCard = makeCard(colorPage, 44, 6)
addPadding(swatchCard, 7)
local swatches = {
	{ "Blue", Color3.fromRGB(110, 128, 255) },
	{ "Red", Color3.fromRGB(235, 78, 94) },
	{ "Green", Color3.fromRGB(64, 186, 132) },
	{ "Purple", Color3.fromRGB(168, 85, 247) },
	{ "Gold", Color3.fromRGB(245, 168, 38) },
}
for i, item in ipairs(swatches) do
	local sb = makeButton(swatchCard, item[1], item[2], function()
		applyColorToTarget(item[2])
	end)
	sb.Size = UDim2.new(0, 66, 0, 28)
	sb.Position = UDim2.new(0, (i - 1) * 72, 0.5, -14)
end

-- =========================================================
-- TAB 6: TOOLS & CONSOLE
-- =========================================================
local toolsPage = createPage("Tools & Console", 6)
makeLabel(toolsPage, "Script Runner & Hub Tools", 14, true, THEME.TextMain, 1)

local stCard = makeCard(toolsPage, 38, 2)
addPadding(stCard, 7)
sharedStatusLabel = Instance.new("TextLabel")
sharedStatusLabel.Size = UDim2.new(1, 0, 1, 0)
sharedStatusLabel.BackgroundTransparency = 1
sharedStatusLabel.Text = "Ready: f3liks hub v3.5 loaded."
sharedStatusLabel.TextSize = 12
sharedStatusLabel.Font = Enum.Font.GothamBold
sharedStatusLabel.TextColor3 = THEME.Success
sharedStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
sharedStatusLabel.Parent = stCard

local boxCard = makeCard(toolsPage, 150, 3)
addPadding(boxCard, 7)
sharedOutputBox = Instance.new("TextBox")
sharedOutputBox.Size = UDim2.new(1, 0, 1, 0)
sharedOutputBox.BackgroundColor3 = THEME.BgInput
sharedOutputBox.BorderSizePixel = 0
sharedOutputBox.MultiLine = true
sharedOutputBox.ClearTextOnFocus = false
sharedOutputBox.TextWrapped = false
sharedOutputBox.TextXAlignment = Enum.TextXAlignment.Left
sharedOutputBox.TextYAlignment = Enum.TextYAlignment.Top
sharedOutputBox.Font = Enum.Font.Code
sharedOutputBox.TextSize = 11
sharedOutputBox.TextColor3 = THEME.TextMain
sharedOutputBox.Text = "print('f3liks hub v3.5 ready')"
sharedOutputBox.Parent = boxCard
addCorner(sharedOutputBox, 6)
addStroke(sharedOutputBox, THEME.Stroke, 1)

local runRow = makeCard(toolsPage, 46, 4)
addPadding(runRow, 7)

local runBtn = makeButton(runRow, "Run Code", THEME.Success, function()
	local fn, err = loadstring(sharedOutputBox.Text)
	if not fn then
		sharedStatusLabel.TextColor3 = THEME.Danger
		sharedStatusLabel.Text = "Compile Error: " .. tostring(err)
		return
	end
	local ok, rErr = pcall(fn)
	if ok then
		sharedStatusLabel.TextColor3 = THEME.Success
		sharedStatusLabel.Text = "Executed cleanly."
	else
		sharedStatusLabel.TextColor3 = THEME.Danger
		sharedStatusLabel.Text = "Runtime Error: " .. tostring(rErr)
	end
end)
runBtn.Size = UDim2.new(0, 82, 0, 30)
runBtn.Position = UDim2.new(0, 0, 0.5, -15)

local copyOutBtn = makeButton(runRow, "Copy", THEME.BgCardAlt, function()
	safeClipboard(sharedOutputBox.Text)
	sharedStatusLabel.TextColor3 = THEME.TextMain
	sharedStatusLabel.Text = "Copied output box."
end)
copyOutBtn.Size = UDim2.new(0, 62, 0, 30)
copyOutBtn.Position = UDim2.new(0, 88, 0.5, -15)

local resetPosBtn = makeButton(runRow, "Center GUI", THEME.BgCardAlt, function()
	mainFrame.Position = DEFAULT_POS
end)
resetPosBtn.Size = UDim2.new(0, 84, 0, 30)
resetPosBtn.Position = UDim2.new(0, 156, 0.5, -15)

local killBtn = makeButton(runRow, "Destroy GUI", THEME.Danger, function()
	thinkToken += 1
	pcall(function() espFolder:Destroy() end)
	pcall(function() screenGui:Destroy() end)
end)
killBtn.Size = UDim2.new(0, 94, 0, 30)
killBtn.Position = UDim2.new(1, -94, 0.5, -15)

closeBtn.MouseButton1Click:Connect(function()
	thinkToken += 1
	pcall(function() espFolder:Destroy() end)
	pcall(function() screenGui:Destroy() end)
end)

pages["AI Builder"].Visible = true
refreshTabHighlights()

print("[f3liks hub] Mounted v3.5.")
