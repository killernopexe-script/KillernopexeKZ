-- ✅ Загрузка Rayfield
local success, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
	warn("⚠️ Не удалось загрузить Rayfield")
	return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ✅ Сохраняемый пароль
getgenv().PASSWORD = "Rebirth champion Clan"

-- ✅ Основное окно
local Window = Rayfield:CreateWindow({
	Name = "Rebirth champion ultimate",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "killernopexeKZ",
	ConfigurationSaving = {Enabled = true, FolderName = "AutoFarm", FileName = "Settings"},
	KeySystem = true, -- Включаем систему пароля
	KeySettings = {
		Title = "Password Required",
		Subtitle = "Enter the password",
		Note = "Telegram",
		Key = getgenv().PASSWORD,
		SaveKey = true, -- Сохраняем пароль
		Callback = function(Value)
			if Value == getgenv().PASSWORD then
				return true
			else
				return false
			end
		end
	}
})

--------------------------------------------------------
-- === ФУНКЦИЯ ИМИТАЦИИ КАСАНИЯ ===
--------------------------------------------------------
local function simulateTouch(part)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not part then return end
	pcall(function()
		firetouchinterest(hrp, part, 0)
		task.wait(0.05)
		firetouchinterest(hrp, part, 1)
	end)
end

--------------------------------------------------------
-- === ВКЛАДКА АВТО-ФАРМА ===
--------------------------------------------------------
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

-- Настройки для всех типов фарма
local FarmSettings = {
	-- Кликер
	AutoClick = false,
	
	-- Перерождение
	AutoRebirth = false, 
	RebirthLevel = "Best",
	
	-- Апгрейды
	AutoUpgrade = false,
	SelectedUpgrades = {},
	
	-- Сундуки
	AutoChests = false,
	
	-- Playtime Rewards
	AutoPlaytimeRewards = false,
	
	-- Руды (через Knit)
	AutoOreKnit = false,
	SelectedOres = {},
	
	-- Орбы
	AutoOrbs = false,
}

-- Секция кликера
FarmTab:CreateSection("⚡ Авто-Кликер")
FarmTab:CreateToggle({
	Name = "⚡ Auto Click",
	CurrentValue = false,
	Flag = "AutoClick",
	Callback = function(v) 
		FarmSettings.AutoClick = v 
	end,
})

-- Секция перерождения
FarmTab:CreateSection("🔄 Авто-Перерождение")

-- Получаем доступные уровни перерождения
local function getRebirthLevels()
	local levels = {"Best"}
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local DataController = Knit.GetController("DataController")
		DataController:waitForData()
		
		local Rebirths = require(ReplicatedStorage.Shared.List.Rebirths)
		local Upgrades = require(ReplicatedStorage.Shared.List.Upgrades)
		
		local rebirthButtonsLevel = DataController.data.upgrades.rebirthButtons or 0
		local rebirthButtons = Upgrades.rebirthButtons.upgrades[rebirthButtonsLevel]
		
		for rebirthLevel, rebirthData in pairs(Rebirths) do
			if rebirthButtons.value >= rebirthLevel then
				table.insert(levels, tostring(rebirthLevel))
			end
		end
	end)
	return levels
end

-- Получаем лучший доступный уровень
local function getBestRebirthLevel()
	local bestLevel = 1
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local DataController = Knit.GetController("DataController")
		DataController:waitForData()
		
		local Rebirths = require(ReplicatedStorage.Shared.List.Rebirths)
		local Upgrades = require(ReplicatedStorage.Shared.List.Upgrades)
		
		local rebirthButtonsLevel = DataController.data.upgrades.rebirthButtons or 0
		local rebirthButtons = Upgrades.rebirthButtons.upgrades[rebirthButtonsLevel]
		
		for rebirthLevel, rebirthData in pairs(Rebirths) do
			if rebirthButtons.value >= rebirthLevel then
				bestLevel = rebirthLevel
			else
				break
			end
		end
	end)
	return bestLevel
end

-- Проверяем возможность перерождения
local function canAffordRebirth(level)
	local canAfford = false
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local DataController = Knit.GetController("DataController")
		DataController:waitForData()
		
		local Rebirths = require(ReplicatedStorage.Shared.List.Rebirths)
		local Variables = require(ReplicatedStorage.Shared.Variables)
		
		local rebirthData = Rebirths[level]
		if not rebirthData then return false end
		
		local basePrice = Variables.rebirthPrice
		local multiplier = Variables.rebirthPriceMultiplier
		local currentRebirths = DataController.data.rebirths or 0
		
		local totalCost = (basePrice + currentRebirths * multiplier) * level + multiplier * (level * (level - 1) / 2)
		canAfford = (DataController.data.clicks or 0) >= totalCost
	end)
	return canAfford
end

local rebirthLevels = getRebirthLevels()
FarmTab:CreateDropdown({
	Name = "🎯 Rebirth Level",
	Options = rebirthLevels,
	CurrentOption = {"Best"},
	MultipleOptions = false,
	Flag = "RebirthLevel",
	Callback = function(selected)
		FarmSettings.RebirthLevel = selected[1]
	end,
})

FarmTab:CreateToggle({
	Name = "🔄 Auto Rebirth",
	CurrentValue = false,
	Flag = "AutoRebirth",
	Callback = function(v) 
		FarmSettings.AutoRebirth = v 
	end,
})

-- Секция орбов (УЛУЧШЕННАЯ ВЕРСИЯ - собирает все орбы за раз)
FarmTab:CreateSection("🌀 Орбы")
FarmTab:CreateToggle({
	Name = "🌀 Auto Collect Orbs (Мгновенно)",
	CurrentValue = false,
	Flag = "AutoOrbs",
	Callback = function(v) 
		FarmSettings.AutoOrbs = v 
	end,
})

-- Секция руд (через Knit)
FarmTab:CreateSection("⛏️ Рулы (Knit)")
local oreList = {
	"cobaltOre","diamondOre","emeraldOre","goldOre","ironOre",
	"moonstoneOre","platinumOre","rubyOre","sapphireOre",
	"sunstoneOre","titaniumOre","uraniumOre"
}

FarmTab:CreateDropdown({
	Name = "Select Ore Types",
	Options = oreList,
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "SelectedOres",
	Callback = function(options) FarmSettings.SelectedOres = options end,
})

FarmTab:CreateToggle({
	Name = "Auto Ore Farm (Knit)",
	CurrentValue = false,
	Flag = "AutoOreKnit",
	Callback = function(v) FarmSettings.AutoOreKnit = v end,
})

-- Секция апгрейдов
FarmTab:CreateSection("📈 Апгрейды")

local function getUpgradeList()
	local upgrades = {}
	pcall(function()
		local Upgrades = require(ReplicatedStorage.Shared.List.Upgrades)
		for upgradeName, upgradeData in pairs(Upgrades) do
			if upgradeName ~= "rebirthButtons" then
				table.insert(upgrades, upgradeName)
			end
		end
	end)
	return upgrades
end

local upgradeOptions = getUpgradeList()

FarmTab:CreateDropdown({
	Name = "Select Upgrades",
	Options = upgradeOptions,
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "SelectedUpgrades",
	Callback = function(options) FarmSettings.SelectedUpgrades = options end,
})

FarmTab:CreateToggle({
	Name = "Auto Buy Upgrades",
	CurrentValue = false,
	Flag = "AutoUpgrade",
	Callback = function(v) FarmSettings.AutoUpgrade = v end,
})

-- Секция сундуков
FarmTab:CreateSection("📦 Сундуки")
FarmTab:CreateToggle({
	Name = "Auto Claim Chests",
	CurrentValue = false,
	Flag = "AutoChests",
	Callback = function(v) FarmSettings.AutoChests = v end,
})

-- ==============================
-- Playtime Rewards (ИСПРАВЛЕННАЯ ВЕРСИЯ)
-- ==============================
task.spawn(function()
    while task.wait(30) do
        if FarmSettings.AutoPlaytimeRewards then
            pcall(function()
                local Knit = require(ReplicatedStorage.Packages.Knit)
                local DataController = Knit.GetController("DataController")
                DataController:waitForData()
                
                -- Получаем список наград
                local PlaytimeRewards = require(ReplicatedStorage.Shared.List.PlaytimeRewards)
                local RewardService = Knit.GetService("RewardService")
                
                -- Проверяем каждую награду
                for rewardId, rewardData in pairs(PlaytimeRewards) do
                    if not FarmSettings.AutoPlaytimeRewards then break end
                    
                    -- Проверяем, не забрана ли уже награда
                    local alreadyClaimed = false
                    for _, claimedId in ipairs(DataController.data.claimedPlaytimeRewards or {}) do
                        if claimedId == rewardId then
                            alreadyClaimed = true
                            break
                        end
                    end
                    
                    if not alreadyClaimed then
                        -- Проверяем выполнено ли условие (время игры)
                        local requiredTime = rewardData.required or rewardData.time or 0
                        local currentSessionTime = DataController.data.sessionTime or 0
                        
                        if currentSessionTime >= requiredTime then
                            -- Пытаемся забрать награду
                            local result = RewardService:claimPlaytimeReward(rewardId)
                            if result == "success" then
                                print("✅ Playtime Reward Claimed:", rewardId)
                                Rayfield:Notify({
                                    Title = "⏰ Playtime Reward",
                                    Content = "Награда " .. rewardId .. " получена!",
                                    Duration = 2
                                })
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ЦИКЛЫ ДЛЯ ВСЕХ ФУНКЦИЙ
task.spawn(function()
	-- Авто-кликер
	while task.wait(0.05) do
		if FarmSettings.AutoClick then
			pcall(function()
				local Knit = require(ReplicatedStorage.Packages.Knit)
				local ClickService = Knit.GetService("ClickService")
				ClickService.click:Fire()
			end)
		end
	end
end)

task.spawn(function()
	-- Авто-перерождение
	while task.wait(0.1) do
		if FarmSettings.AutoRebirth then
			pcall(function()
				local Knit = require(ReplicatedStorage.Packages.Knit)
				local RebirthService = Knit.GetService("RebirthService")
				local DataController = Knit.GetController("DataController")
				DataController:waitForData()
				
				local rebirthLevel
				if FarmSettings.RebirthLevel == "Best" then
					rebirthLevel = getBestRebirthLevel()
				else
					rebirthLevel = tonumber(FarmSettings.RebirthLevel)
				end
				
				if rebirthLevel and canAffordRebirth(rebirthLevel) then
					local success = RebirthService:rebirth(rebirthLevel)
					if success == "success" then
						print("✅ Успешное перерождение на уровне:", rebirthLevel)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	-- Орбы (УЛУЧШЕННАЯ ВЕРСИЯ - собирает все орбы мгновенно)
	while task.wait(0.5) do
		if FarmSettings.AutoOrbs then
			pcall(function()
				local debrisFolder = Workspace:FindFirstChild("Debris")
				if not debrisFolder then return end
				local orbsFolder = debrisFolder:FindFirstChild("Orbs")
				if not orbsFolder then return end
				
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Собираем ВСЕ орбы за один раз
				for _, obj in ipairs(orbsFolder:GetChildren()) do
					if obj:IsA("BasePart") or (obj:IsA("Model") and obj.PrimaryPart) then
						local orbPart = obj:IsA("BasePart") and obj or obj.PrimaryPart
						
						-- Телепортируем орб прямо к игроку
						orbPart.CFrame = hrp.CFrame
						
						-- Симулируем касание
						simulateTouch(orbPart)
						
						-- Удаляем орб сразу
						obj:Destroy()
					end
				end
			end)
		end
	end
end)

-- =========================
-- Авто-фарм руд через Knit (НОВАЯ ФУНКЦИЯ)
-- =========================
task.spawn(function()
    while task.wait(1) do
        if FarmSettings.AutoOreKnit and #FarmSettings.SelectedOres > 0 then
            pcall(function()
                local Knit = require(ReplicatedStorage.Packages.Knit)
                local OreController = Knit.GetController("OreController")
                
                if OreController and type(OreController.mineOre) == "function" then
                    -- Получаем все доступные руды на карте
                    for _, oreName in ipairs(FarmSettings.SelectedOres) do
                        -- Ищем руду в Workspace
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("Model") and obj.Name == oreName then
                                -- Используем Knit для добычи руды
                                local success = OreController:mineOre(oreName)
                                if success then
                                    print("✅ Руда добыта:", oreName)
                                end
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
	-- Апгрейды
	while task.wait(1) do
		if FarmSettings.AutoUpgrade and #FarmSettings.SelectedUpgrades > 0 then
			pcall(function()
				local Knit = require(ReplicatedStorage.Packages.Knit)
				local UpgradeService = Knit.GetService("UpgradeService")
				local DataController = Knit.GetController("DataController")
				DataController:waitForData()
				
				for _, upgradeName in ipairs(FarmSettings.SelectedUpgrades) do
					local currentLevel = DataController.data.upgrades[upgradeName] or 0
					local upgradeData = require(ReplicatedStorage.Shared.List.Upgrades)[upgradeName]
					
					if upgradeData then
						local nextLevelData = upgradeData.upgrades[currentLevel + 1]
						if nextLevelData and DataController.data.gems >= nextLevelData.cost then
							local result = UpgradeService:upgrade(upgradeName)
							if result == "success" then
								print("✅ Апгрейд куплен:", upgradeName, "Уровень:", currentLevel + 1)
							end
						end
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	-- Сундуки
	while task.wait(30) do
		if FarmSettings.AutoChests then
			pcall(function()
				local Knit = require(ReplicatedStorage.Packages.Knit)
				local RewardService = Knit.GetService("RewardService")
				local DataController = Knit.GetController("DataController")
				DataController:waitForData()
				
				local Chests = require(ReplicatedStorage.Shared.List.Chests)
				
				for chestName, chestData in pairs(Chests) do
					local lastClaim = DataController.data.chests[chestName] or 0
					local currentTime = os.time()
					
					if currentTime >= lastClaim + chestData.cooldown then
						if chestData.group then
							local inGroup = pcall(function()
								return player:IsInGroup(game.CreatorId)
							end)
							if not inGroup then continue end
						end
						
						local result = RewardService:claimChest(chestName)
						if result == "success" then
							print("✅ Сундук открыт:", chestName)
						end
					end
				end
			end)
		end
	end
end)

-- ==============================
-- Playtime Rewards (robust)
-- ==============================
task.spawn(function()
	while task.wait(30) do
		if FarmSettings.AutoPlaytimeRewards then
			pcall(function()
				local KnitOk, Knit = pcall(function() return require(ReplicatedStorage.Packages.Knit) end)
				if not KnitOk or not Knit then return end

				local successController, PlaytimeRewardsController = pcall(function() return Knit.GetController("PlaytimeRewardsController") end)
				local okData, DataController = pcall(function() return Knit.GetController("DataController") end)
				if okData and DataController then DataController:waitForData() end

				local claimedAny = false
				-- 1) Сначала пробуем claimAll если есть
				if successController and PlaytimeRewardsController and type(PlaytimeRewardsController.claimAll) == "function" then
					local ok, res = pcall(function() return PlaytimeRewardsController:claimAll() end)
					if ok then
						claimedAny = true
						Rayfield:Notify({Title = "⏰ Playtime Rewards", Content = "Все доступные награды собраны!", Duration = 2})
						print("✅ Playtime: claimAll succeeded")
					end
				end

				-- 2) Фоллбек: если claimAll не сработал, пытаемся claim(i) по индексам (1..50)
				if not claimedAny and successController and PlaytimeRewardsController and type(PlaytimeRewardsController.claim) == "function" then
					for i = 1, 50 do
						if not FarmSettings.AutoPlaytimeRewards then break end
						pcall(function()
							PlaytimeRewardsController:claim(i)
						end)
						task.wait(0.05)
					end
					Rayfield:Notify({Title = "⏰ Playtime Rewards", Content = "Попытка забрать Playtime (фоллбек).", Duration = 2})
				end

				-- 3) Доп. фоллбек: если нет контроллера, можно пробежать DataController.data.playtime* и вызывать контроллер.claim(key) если есть
				if not successController and okData and DataController then
					local rewardsTable = DataController.data.playtimeRewards or DataController.data.playtime or DataController.data.playtime_data
					if type(rewardsTable) == "table" then
						for key, info in pairs(rewardsTable) do
							if not FarmSettings.AutoPlaytimeRewards then break end
							local ready = false
							if type(info) == "table" then
								ready = info.ready or info.available or info.canClaim or (info.cooldown and os.time() >= (info.lastClaim or 0) + (info.cooldown or 0))
							end
							if ready and successController and PlaytimeRewardsController and type(PlaytimeRewardsController.claim) == "function" then
								pcall(function() PlaytimeRewardsController:claim(key) end)
								task.wait(0.05)
							end
						end
					end
				end
			end)
		end
	end
end)

--------------------------------------------------------
-- === ВКЛАДКА WORLD FARM ===
--------------------------------------------------------
local WorldTab = Window:CreateTab("World Farm", 4483362458)

-- Настройки для World Farm
local WorldSettings = {
	-- Метеориты
	AutoMeteor = false,
	
	-- Звезды
	AutoStars = false,
	
	-- Руды (старая версия)
	AutoOre = false,
	TeleportInterval = 2.5,
}

-- Секция метеоритов
WorldTab:CreateSection("🌠 Метеориты")
WorldTab:CreateToggle({
	Name = "Auto Meteor Farm",
	CurrentValue = false,
	Flag = "AutoMeteor",
	Callback = function(v) WorldSettings.AutoMeteor = v end,
})

local allowedMeteorNames = {["giant"]=true, ["huge"]=true, ["normal"]=true}

local function getNearestMeteor()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local debris = Workspace:FindFirstChild("Debris")
	if not debris then return nil end

	local nearest, dist = nil, math.huge
	for _, obj in ipairs(debris:GetChildren()) do
		local name = obj.Name and obj.Name:lower()
		if name and allowedMeteorNames[name] then
			local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
			if part then
				local d = (part.Position - hrp.Position).Magnitude
				if d < dist then dist, nearest = d, part end
			end
		end
	end
	return nearest
end

-- Секция звезд
WorldTab:CreateSection("⭐ Звезды")
WorldTab:CreateToggle({
	Name = "Auto Collect Stars",
	CurrentValue = false,
	Flag = "AutoStars",
	Callback = function(v) WorldSettings.AutoStars = v end,
})

local function collectStar(star)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not star then return end
	local hitbox = star:FindFirstChild("Hitbox") or star.PrimaryPart
	if hitbox then simulateTouch(hitbox) end
end

local function collectAllStars()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == "FallingStar" then collectStar(obj) end
	end
end

-- Секция руд (старая версия)
WorldTab:CreateSection("⛏️ Рулы (Teleport)")
WorldTab:CreateToggle({
	Name = "Auto Ore Teleport",
	CurrentValue = false,
	Flag = "AutoOre",
	Callback = function(v) WorldSettings.AutoOre = v end,
})

-- ЦИКЛЫ ДЛЯ WORLD FARM
task.spawn(function()
	-- Метеориты
	while task.wait(3) do
		if WorldSettings.AutoMeteor and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			local meteor = getNearestMeteor()
			if meteor then
				pcall(function() hrp.CFrame = meteor.CFrame + Vector3.new(0,5,0) end)
				simulateTouch(meteor)
			end
		end
	end
end)

task.spawn(function()
	-- Звезды
	while task.wait(0.3) do
		if WorldSettings.AutoStars then collectAllStars() end
	end
end)

Workspace.DescendantAdded:Connect(function(obj)
	if WorldSettings.AutoStars and obj:IsA("Model") and obj.Name == "FallingStar" then
		task.wait(0.05)
		collectStar(obj)
	end
end)

task.spawn(function()
	-- Руды (старая версия)
	while task.wait(WorldSettings.TeleportInterval) do
		if WorldSettings.AutoOre and player.Character and #FarmSettings.SelectedOres > 0 then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local nearestOre = nil
			local nearestDist = math.huge
			for _, oreName in ipairs(FarmSettings.SelectedOres) do
				for _, obj in ipairs(Workspace:GetDescendants()) do
					if obj:IsA("Model") and obj.Name == oreName then
						local part = obj.PrimaryPart or obj:FindFirstChild("Meshes/Rock") or obj:FindFirstChildWhichIsA("BasePart")
						if part then
							local d = (part.Position - hrp.Position).Magnitude
							if d < nearestDist then
								nearestDist = d
								nearestOre = part
							end
						end
					end
				end
			end

			if nearestOre then
				pcall(function() hrp.CFrame = nearestOre.CFrame + Vector3.new(0,7,0) end)
				simulateTouch(nearestOre)
				while nearestOre and nearestOre.Parent do task.wait(0.05) end
			end
		end
	end
end)

--------------------------------------------------------
-- === ВКЛАДКА ЯИЦ ===
--------------------------------------------------------
local PetTab = Window:CreateTab("Pets", 4483362458)
getgenv().autoopenegganywhere = false
getgenv().selectedEgg = ""

-- Nuclear disable - отключаем ВСЁ
local function nuclearDisableAnimations()
    pcall(function()
        print("🚫 Nuclear animation disable activated!")
        
        -- 1. Отключаем все RemoteEvents связанные с анимациями
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:lower():find("anim") or obj.Name:lower():find("effect") or obj.Name:lower():find("hatch") or obj.Name:lower():find("egg")) then
                if hookfunction then
                    local originalFire = obj.FireServer
                    hookfunction(obj.FireServer, function(self, ...)
                        return nil
                    end)
                else
                    obj.FireServer = function() return nil end
                end
            end
        end
        
        -- 2. Отключаем все функции в Knit контроллерах
        local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
        for _, controller in pairs(Knit.GetControllers()) do
            for name, func in pairs(controller) do
                if type(func) == "function" and (name:lower():find("anim") or name:lower():find("effect") or name:lower():find("hatch") or name:lower():find("show") or name:lower():find("display")) then
                    if not getgenv().savedFunctions then getgenv().savedFunctions = {} end
                    getgenv().savedFunctions[name] = func
                    
                    if hookfunction then
                        hookfunction(func, function() return nil end)
                    else
                        controller[name] = function() return nil end
                    end
                end
            end
        end
        
        -- 3. Отключаем TweenService
        local TweenService = game:GetService("TweenService")
        if hookfunction then
            local originalCreate = TweenService.Create
            hookfunction(TweenService.Create, function(self, ...)
                local tween = originalCreate(self, ...)
                tween.Play = function() end
                tween.Pause = function() end
                return tween
            end)
        end
        
        -- 4. Отключаем все партиклы и эффекты
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
            if obj:IsA("Sound") then
                obj:Stop()
                obj.Playing = false
            end
            if obj:IsA("Part") and (obj.Name:lower():find("egg") or obj.Name:lower():find("hatch") or obj.Name:lower():find("pet") or obj.Name:lower():find("effect")) then
                obj.Transparency = 1
                obj.CanCollide = false
            end
        end
        
        -- 5. Блокируем создание новых эффектов
        if hookmetatable then
            local mt = getrawmetatable(game)
            if mt then
                local originalIndex = mt.__index
                hookmetatable(mt, {
                    __index = function(self, key)
                        if key == "Clone" then
                            return function(...)
                                local clone = originalIndex(self, key)(...)
                                if clone:IsA("ParticleEmitter") or clone:IsA("Beam") then
                                    clone.Enabled = false
                                end
                                return clone
                            end
                        end
                        return originalIndex(self, key)
                    end
                })
            end
        end
        
        print("✅ All animations disabled!")
    end)
end

-- Включение анимаций обратно
local function enableAnimations()
    pcall(function()
        print("🔄 Restoring animations...")
        
        -- Восстанавливаем сохраненные функции
        if getgenv().savedFunctions then
            local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
            for _, controller in pairs(Knit.GetControllers()) do
                for name, func in pairs(getgenv().savedFunctions) do
                    if controller[name] then
                        controller[name] = func
                    end
                end
            end
            getgenv().savedFunctions = nil
        end
        
        print("✅ Animations restored!")
    end)
end

-- Секция анимаций (перенесена к яйцам)
PetTab:CreateSection("💥 Анимации")
PetTab:CreateToggle({
    Name = "💥 NUCLEAR Disable All Animations",
    CurrentValue = false,
    Flag = "NuclearDisable",
    Callback = function(Value)
        if Value then
            nuclearDisableAnimations()
            Rayfield:Notify({
                Title = "NUCLEAR MODE ACTIVATED",
                Content = "ALL animations and effects disabled",
                Duration = 3
            })
        else
            enableAnimations()
            Rayfield:Notify({
                Title = "Animations Restored",
                Content = "All animations enabled again",
                Duration = 2
            })
        end
    end,
})

local function getEggsWithPrices()
    local eggs = {}
    pcall(function()
        local EggListModule = require(ReplicatedStorage.Shared.List.Pets.Eggs)
        for eggName, eggData in pairs(EggListModule) do
            local cost = eggData.cost or 0
            if type(cost) == "number" then
                table.insert(eggs, { 
                    name = eggName,
                    displayName = eggData.name or eggName,
                    cost = cost,
                })
            end
        end
        table.sort(eggs, function(a, b)
            return a.cost < b.cost
        end)
    end)
    return eggs
end

local eggList = getEggsWithPrices()
local dropdownOptions = {}
local eggNameMap = {}

for _, egg in ipairs(eggList) do
    local formattedCost
    if egg.cost >= 1000000 then
        formattedCost = string.format("%.1fM", egg.cost / 1000000)
    elseif egg.cost >= 1000 then
        formattedCost = string.format("%.1fK", egg.cost / 1000)
    else
        formattedCost = tostring(egg.cost)
    end
    
    local displayText = egg.displayName .. " - " .. formattedCost
    table.insert(dropdownOptions, displayText)
    eggNameMap[displayText] = egg.name
end

PetTab:CreateSection("🥚 Авто-Яйца")
PetTab:CreateDropdown({
    Name = "🎁 Select Egg",
    Options = dropdownOptions,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "selected_egg",
    Callback = function(selected)
        local selectedText = selected[1]
        local realEggName = eggNameMap[selectedText]
        if realEggName then
            getgenv().selectedEgg = realEggName
        end
    end,
})

PetTab:CreateToggle({
    Name = "⚡ Auto Open Eggs",
    CurrentValue = false,
    Flag = "auto_open_egg",
    Callback = function(Value)
        getgenv().autoopenegganywhere = Value
        
        if Value then
            spawn(function()
                local Knit
                repeat
                    Knit = require(ReplicatedStorage.Packages.Knit)
                    task.wait(1)
                until Knit ~= nil
                
                local DataController = Knit.GetController("DataController")
                local EggService = Knit.GetService("EggService")
                local LocalPlayer = game.Players.LocalPlayer
                local Eggs = require(ReplicatedStorage.Shared.List.Pets.Eggs)
                local Util = require(ReplicatedStorage.Shared.Util)
                
                while getgenv().autoopenegganywhere do
                    pcall(function()
                        local currentSelectedEgg = getgenv().selectedEgg or ""
                        if currentSelectedEgg ~= "" then
                            local eggData = Eggs[currentSelectedEgg]
                            
                            if eggData then
                                local maxQuantity = Util.eggUtils.getMaxAffordable(LocalPlayer, DataController.data, currentSelectedEgg)
                                local hasEnough = Util.eggUtils.hasEnoughToOpen(DataController.data, currentSelectedEgg, maxQuantity)
                                
                                if maxQuantity > 0 and hasEnough then
                                    EggService.openEgg:Fire(currentSelectedEgg, maxQuantity)
                                    task.wait(0.02)
                                else
                                    task.wait(0.5)
                                end
                            end
                        else
                            getgenv().autoopenegganywhere = false
                        end
                    end)
                    task.wait(0.02)
                end
            end)
        end
    end,
})

-- Уведомление о загрузке
Rayfield:Notify({
    Title = "Auto Farm Loaded",
    Content = "All features ready",
    Duration = 2
})
