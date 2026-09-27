# DAIZU-- プレーヤーとプレイヤーGUIの取得
local players = game:GetService("Players")
local player = players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

-- リスポーンしてもGUIが消えないようにする関数
local function setupDiceGui()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- 既存のGUIがあれば削除（二重生成防止）
    if playerGui:FindFirstChild("ColorDiceDynamicGui") then
        playerGui.ColorDiceDynamicGui:Destroy()
    end

    -- メインのScreenGui作成
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ColorDiceDynamicGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- メインフレーム
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 160)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -80)
    mainFrame.BackgroundColor3 = Color3.new(0.5, 0.7, 0.9)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim.new(0, 16)

    -- UIをドラッグして動かす機能
    local isDragging = false
    local isLocked = false
    local isMinimized = false
    local isLogOpen = false
    local dragInput, dragStart, startPos

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not isLocked then
                isDragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                    end
                end)
            end
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    runService.RenderStepped:Connect(function()
        if isDragging and dragInput and not isLocked then
            local delta = dragInput.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- 指定された6つの色
    local colors = {
        Color3.fromRGB(230, 50, 50),   -- 赤
        Color3.fromRGB(240, 150, 20), -- オレンジ
        Color3.fromRGB(240, 215, 50), -- 黄色
        Color3.fromRGB(50, 150, 50),   -- 緑
        Color3.fromRGB(30, 100, 210),  -- 青
        Color3.fromRGB(130, 50, 180)   -- 紫
    }

    local dices = {}
    local diceCount = 4
    local isAnimating = false
    local diceHistory = {}

    -- 各種UI部品の先行定義
    local startButton = Instance.new("TextButton", mainFrame)
    local logPanel = Instance.new("ScrollingFrame", mainFrame)

    -- ダイス配置・再描画関数
    local function renderDices()
        for _, d in ipairs(dices) do
            if d.container then d.container:Destroy() end
        end
        dices = {}
        
        local totalWidth = (diceCount * 80) + ((diceCount - 1) * 12) + 40
        local frameWidth = math.max(totalWidth, 320)
        if not isMinimized then
            mainFrame.Size = UDim2.new(0, frameWidth, 0, 160)
        end
        
        startButton.Size = UDim2.new(0, frameWidth - 40, 0, 28)
        
        local startX = 20
        local spacing = 92
        
        for i = 1, diceCount do
            local diceContainer = Instance.new("Frame")
            diceContainer.Size = UDim2.new(0, 80, 0, 80)
            diceContainer.Position = UDim2.new(0, startX + (i - 1) * spacing, 0, 32)
            diceContainer.BackgroundColor3 = Color3.new(1, 1, 1)
            diceContainer.BorderSizePixel = 0
            diceContainer.Parent = mainFrame
            
            Instance.new("UICorner", diceContainer).CornerRadius = UDim.new(0, 12)
            
            local diceFace = Instance.new("Frame")
            diceFace.Size = UDim2.new(1, -10, 1, -10)
            diceFace.Position = UDim2.new(0, 5, 0, 5)
            diceFace.BackgroundColor3 = colors[math.random(1, #colors)]
            diceFace.BorderSizePixel = 0
            diceFace.Parent = diceContainer
            
            Instance.new("UICorner", diceFace).CornerRadius = UDim.new(0, 8)
            
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 16, 0, 16)
            dot.Position = UDim2.new(0.5, -8, 0.5, -8)
            dot.BackgroundColor3 = Color3.new(1, 1, 1)
            dot.BorderSizePixel = 0
            dot.Parent = diceFace
            
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            
            -- 収納状態のときは新しく作ったダイスも最初から非表示にする
            diceContainer.Visible = not isMinimized and not isLogOpen
            
            table.insert(dices, {container = diceContainer, face = diceFace, defaultPos = diceContainer.Position})
        end
    end

    -- START! ボタン
    startButton.Size = UDim2.new(0, 360, 0, 28)
    startButton.Position = UDim2.new(0, 20, 0, 120)
    startButton.BackgroundColor3 = Color3.fromRGB(240, 120, 30)
    startButton.Text = "START!"
    startButton.TextColor3 = Color3.new(1, 1, 1)
    startButton.TextSize = 15
    startButton.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 8)

    -- --- 上部コントロールボタン類 ---

    -- 1. プラスボタン (+)
    local plusButton = Instance.new("TextButton", mainFrame)
    plusButton.Size = UDim2.new(0, 22, 0, 22)
    plusButton.Position = UDim2.new(0, 12, 0, 5)
    plusButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    plusButton.Text = "+"
    plusButton.TextColor3 = Color3.new(1, 1, 1)
    plusButton.TextSize = 14
    plusButton.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", plusButton).CornerRadius = UDim.new(1, 0)

    -- 2. マイナスボタン (-)
    local minusButton = Instance.new("TextButton", mainFrame)
    minusButton.Size = UDim2.new(0, 22, 0, 22)
    minusButton.Position = UDim2.new(0, 42, 0, 5)
    minusButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    minusButton.Text = "-"
    minusButton.TextColor3 = Color3.new(1, 1, 1)
    minusButton.TextSize = 14
    minusButton.Font = Enum.Font.SourceSansBold
    Instance.new("UICorner", minusButton).CornerRadius = UDim.new(1, 0)

    local currentScale = 1.0
    local uiScale = Instance.new("UIScale", mainFrame)

    plusButton.MouseButton1Click:Connect(function()
        currentScale = math.clamp(currentScale + 0.1, 0.7, 1.4)
        uiScale.Scale = currentScale
    end)
    minusButton.MouseButton1Click:Connect(function()
        currentScale = math.clamp(currentScale - 0.1, 0.7, 1.4)
        uiScale.Scale = currentScale
    end)

    -- 右側のボタン群（収納、ログ、ロック）
    local minimizeButton = Instance.new("TextButton", mainFrame)
    minimizeButton.Size = UDim2.new(0, 22, 0, 22)
    minimizeButton.Position = UDim2.new(1, -30, 0, 5)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    minimizeButton.Text = "-"
    minimizeButton.TextSize = 14
    minimizeButton.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(1, 0)

    local logButton = Instance.new("TextButton", mainFrame)
    logButton.Size = UDim2.new(0, 22, 0, 22)
    logButton.Position = UDim2.new(1, -65, 0, 5)
    logButton.BackgroundColor3 = Color3.fromRGB(180, 130, 50)
    logButton.Text = "📜"
    logButton.TextSize = 12
    Instance.new("UICorner", logButton).CornerRadius = UDim.new(1, 0)

    local lockButton = Instance.new("TextButton", mainFrame)
    lockButton.Size = UDim2.new(0, 22, 0, 22)
    lockButton.Position = UDim2.new(1, -100, 0, 5)
    lockButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    lockButton.Text = "🔓"
    lockButton.TextSize = 12
    Instance.new("UICorner", lockButton).CornerRadius = UDim.new(1, 0)

    lockButton.MouseButton1Click:Connect(function()
        isLocked = not isLocked
        if isLocked then
            lockButton.Text = "🔒"
            lockButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        else
            lockButton.Text = "🔓"
            lockButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
    end)

    -- --- ログパネル ---
    logPanel.Size = UDim2.new(1, -20, 0, 115)
    logPanel.Position = UDim2.new(0, 10, 0, 32)
    logPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    logPanel.BackgroundTransparency = 0.2
    logPanel.Visible = false
    logPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
    logPanel.ScrollBarThickness = 4
    Instance.new("UICorner", logPanel).CornerRadius = UDim.new(0, 8)

    local function updateLogDisplay()
        for _, child in ipairs(logPanel:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        for i, historyItem in ipairs(diceHistory) do
            local rowFrame = Instance.new("Frame", logPanel)
            rowFrame.Size = UDim2.new(1, -10, 0, 20)
            rowFrame.Position = UDim2.new(0, 5, 0, (i - 1) * 24 + 5)
            rowFrame.BackgroundTransparency = 1
            
            local label = Instance.new("TextLabel", rowFrame)
            label.Size = UDim2.new(0, 50, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "#" .. i
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 12
            label.Font = Enum.Font.SourceSansBold
            
            for j, col in ipairs(historyItem) do
                local miniDice = Instance.new("Frame", rowFrame)
                miniDice.Size = UDim2.new(0, 16, 0, 16)
                miniDice.Position = UDim2.new(0, 50 + (j - 1) * 22, 0, 2)
                miniDice.BackgroundColor3 = col
                Instance.new("UICorner", miniDice).CornerRadius = UDim.new(0, 4)
            end
        end
        logPanel.CanvasSize = UDim2.new(0, 0, 0, #diceHistory * 24 + 10)
    end

    -- ボタン挙動
    logButton.MouseButton1Click:Connect(function()
        if isMinimized then return end
        isLogOpen = not isLogOpen
        logPanel.Visible = isLogOpen
        startButton.Visible = not isLogOpen
        for _, d in ipairs(dices) do
            if d.container then d.container.Visible = not isLogOpen end
        end
        if isLogOpen then
            updateLogDisplay()
        end
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            -- 収納するとき：ログやダイス、スタートボタンを全て非表示にする
            minimizeButton.Text = "+"
            isLogOpen = false
            logPanel.Visible = false
            startButton.Visible = false
            for _, d in ipairs(dices) do
                if d.container then d.container.Visible = false end
            end
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 30)
        else
            -- 展開するとき：元のサイズに戻し、ダイスとスタートボタンを再表示
            minimizeButton.Text = "-"
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 160)
            startButton.Visible = true
            for _, d in ipairs(dices) do
                if d.container then d.container.Visible = true end
            end
        end
    end)

    -- 初回描画
    renderDices()

    -- STARTボタンを押したときの演出
    startButton.MouseButton1Click:Connect(function()
        if isAnimating or isMinimized or isLogOpen then return end
        isAnimating = true
        
        local startTime = tick()
        while tick() - startTime < 0.25 do
            for _, dice in ipairs(dices) do
                local rx = math.random(-3, 3)
                local ry = math.random(-3, 3)
                dice.container.Position = dice.defaultPos + UDim2.new(0, rx, 0, ry)
            end
            task.wait(0.03)
        end
        for _, dice in ipairs(dices) do
            dice.container.Position = dice.defaultPos
        end
        
        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, dice in ipairs(dices) do
            tweenService:Create(dice.container, tweenInfo, {BackgroundTransparency = 1}):Play()
            tweenService:Create(dice.face, tweenInfo, {BackgroundTransparency = 1}):Play()
        end
        
        task.wait(0.18)
        
        local currentRoll = {}
        for _, dice in ipairs(dices) do
            local randomColor = colors[math.random(1, #colors)]
            dice.face.BackgroundColor3 = randomColor
            table.insert(currentRoll, randomColor)
        end
        
        table.insert(diceHistory, 1, currentRoll)
        if #diceHistory > 5 then
            table.remove(diceHistory, 6)
        end
        
        for _, dice in ipairs(dices) do
            tweenService:Create(dice.container, tweenInfo, {BackgroundTransparency = 0}):Play()
            tweenService:Create(dice.face, tweenInfo, {BackgroundTransparency = 0}):Play()
        end
        
        task.wait(0.15)
        isAnimating = false
    end)
end

-- 初回実行
setupDiceGui()

-- リスポーン対応
player.CharacterAdded:Connect(function()
    task.wait(1)
    setupDiceGui()
end)
