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

-- ✅ Основное окно
local Window = Rayfield:CreateWindow({
	Name = "Auto Farm + Eggs",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "by Zalina",
	ConfigurationSaving = {Enabled = true, FolderName = "AutoFarm", FileName = "Settings"},
	KeySystem = false
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
-- === ВКЛАДКА АВТО-ФАРМА (ВСЁ В ОДНОЙ) ===
--------------------------------------------------------
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

-- Настройки для всех типов фарма
local FarmSettings = {
	-- Кликер
	AutoClick = false,
	
	-- Перерождение
	AutoRebirth = false, 
	RebirthLevel = "Best",
	
	-- Метеориты
	AutoMeteor = false,
	
	-- Звезды
	AutoStars = false,
	
	-- Руды
	AutoOre = false,
	SelectedOres = {},
	TeleportInterval = 2.5,
	
	-- Апгрейды
	AutoUpgrade = false,
	SelectedUpgrades = {},
	
	-- Сундуки
	AutoChests = false,
	
	-- Крафт
	AutoCraft = false,
	CraftNormalToGold = false,
	CraftGoldToToxic = false,
	CraftToxicToGalaxy = false,
	
	-- Анимации
	NuclearDisable = false
}

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

-- Секция метеоритов
FarmTab:CreateSection("🌠 Метеориты")
FarmTab:CreateToggle({
	Name = "Auto Meteor Farm",
	CurrentValue = false,
	Flag = "AutoMeteor",
	Callback = function(v) FarmSettings.AutoMeteor = v end,
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
FarmTab:CreateSection("⭐ Звезды")
FarmTab:CreateToggle({
	Name = "Auto Collect Stars",
	CurrentValue = false,
	Flag = "AutoStars",
	Callback = function(v) FarmSettings.AutoStars = v end,
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

-- Секция руд
FarmTab:CreateSection("⛏️ Рулы")
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
	Name = "Auto Ore Teleport",
	CurrentValue = false,
	Flag = "AutoOre",
	Callback = function(v) FarmSettings.AutoOre = v end,
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

-- Секция крафта
FarmTab:CreateSection("🔨 Авто-Крафт")

-- Функция для получения питомцев по тиру
local function getPetsByTier(tier)
	local pets = {}
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local DataController = Knit.GetController("DataController")
		DataController:waitForData()
		
		local Items = require(ReplicatedStorage.Shared.Items)
		local petClass = Items.pet
		
		for petId, petData in pairs(DataController.data.inventory.pet or {}) do
			local petObj = petClass(petData.nm):setData(petData)
			if petObj:getTier() == tier then
				pets[petId] = petObj
			end
		end
	end)
	return pets
end

-- Функция для крафта определенного типа
local function craftPetsByType(craftType)
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local PetService = Knit.GetService("PetService")
		local DataController = Knit.GetController("DataController")
		DataController:waitForData()
		
		local Tiers = require(ReplicatedStorage.Shared.List.Pets.Tiers)
		local targetTier
		
		-- Определяем целевой тир для крафта
		if craftType == "normal_to_gold" then
			targetTier = 1 -- Обычные -> Золотые
		elseif craftType == "gold_to_toxic" then
			targetTier = 2 -- Золотые -> Токсичные
		elseif craftType == "toxic_to_galaxy" then
			targetTier = 3 -- Токсичные -> Галактические
		else
			return
		end
		
		-- Проверяем существует ли следующий тир
		if not Tiers[targetTier + 1] then
			print("❌ Следующий тир не существует:", targetTier)
			return
		end
		
		local pets = getPetsByTier(targetTier)
		local craftablePets = {}
		
		-- Собираем питомцев для крафта
		for petId, petObj in pairs(pets) do
			if not petObj:getLocked() and petObj:getAmount() >= 5 then
				table.insert(craftablePets, petId)
			end
		end
		
		-- Крафтим группами по 5
		for i = 1, #craftablePets, 5 do
			local batch = {}
			for j = i, math.min(i + 4, #craftablePets) do
				table.insert(batch, craftablePets[j])
			end
			
			if #batch >= 5 then
				local result = PetService:craft(batch, true)
				print("🔨 Крафт:", craftType, "Тир", targetTier, "->", targetTier + 1, "Результат:", result)
				task.wait(0.5)
			end
		end
	end)
end

-- Общий авто-крафт
local function autoCraftAllPets()
	pcall(function()
		local Knit = require(ReplicatedStorage.Packages.Knit)
		local PetService = Knit.GetService("PetService")
		local DataController = Knit.GetController("DataController")
		DataController:waitForData()
		
		-- Собираем всех питомцев для крафта (5+ одинаковых)
		local craftGroups = {}
		for petId, petData in pairs(DataController.data.inventory.pet or {}) do
			if petData.am and petData.am >= 5 then
				if not craftGroups[petData.nm] then
					craftGroups[petData.nm] = {}
				end
				table.insert(craftGroups[petData.nm], petId)
			end
		end
		
		-- Крафтим группы питомцев
		for petName, petGroup in pairs(craftGroups) do
			if not FarmSettings.AutoCraft then break end
			
			-- Крафтим группами по 5
			for i = 1, #petGroup, 5 do
				local batch = {}
				for j = i, math.min(i + 4, #petGroup) do
					table.insert(batch, petGroup[j])
				end
				
				if #batch >= 5 then
					local result = PetService:craft(batch, true)
					print("🔨 Крафт питомцев:", petName, "Результат:", result)
					task.wait(0.5)
				end
			end
		end
	end)
end

FarmTab:CreateToggle({
	Name = "🔨 Auto Craft Pets (Общий)",
	CurrentValue = false,
	Flag = "AutoCraft",
	Callback = function(v) 
		FarmSettings.AutoCraft = v 
	end,
})

FarmTab:CreateToggle({
	Name = "🟡 Обычные → Золотые",
	CurrentValue = false,
	Flag = "CraftNormalToGold",
	Callback = function(v) 
		FarmSettings.CraftNormalToGold = v 
	end,
})

FarmTab:CreateToggle({
	Name = "🟢 Золотые → Токсичные",
	CurrentValue = false,
	Flag = "CraftGoldToToxic",
	Callback = function(v) 
		FarmSettings.CraftGoldToToxic = v 
	end,
})

FarmTab:CreateToggle({
	Name = "🔵 Токсичные → Галактические",
	CurrentValue = false,
	Flag = "CraftToxicToGalaxy",
	Callback = function(v) 
		FarmSettings.CraftToxicToGalaxy = v 
	end,
})

-- Секция анимаций
FarmTab:CreateSection("💥 Анимации")
FarmTab:CreateToggle({
    Name = "💥 NUCLEAR Disable All Animations",
    CurrentValue = false,
    Flag = "NuclearDisable",
    Callback = function(Value)
        FarmSettings.NuclearDisable = Value
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
	-- Метеориты
	while task.wait(3) do
		if FarmSettings.AutoMeteor and player.Character then
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
		if FarmSettings.AutoStars then collectAllStars() end
	end
end)

Workspace.DescendantAdded:Connect(function(obj)
	if FarmSettings.AutoStars and obj:IsA("Model") and obj.Name == "FallingStar" then
		task.wait(0.05)
		collectStar(obj)
	end
end)

task.spawn(function()
	-- Рулы
	while task.wait(FarmSettings.TeleportInterval) do
		if FarmSettings.AutoOre and player.Character and #FarmSettings.SelectedOres > 0 then
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

task.spawn(function()
	-- Крафт
	while task.wait(3) do
		-- Общий авто-крафт
		if FarmSettings.AutoCraft then
			autoCraftAllPets()
		end
		
		-- Специфические типы крафта
		if FarmSettings.CraftNormalToGold then
			craftPetsByType("normal_to_gold")
		end
		
		if FarmSettings.CraftGoldToToxic then
			craftPetsByType("gold_to_toxic")
		end
		
		if FarmSettings.CraftToxicToGalaxy then
			craftPetsByType("toxic_to_galaxy")
		end
	end
end)

--------------------------------------------------------
-- === ВКЛАДКА ЯИЦ ===
--------------------------------------------------------
local PetTab = Window:CreateTab("Pets", 4483362458)
getgenv().autoopenegganywhere = false
getgenv().selectedEgg = ""

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
							
