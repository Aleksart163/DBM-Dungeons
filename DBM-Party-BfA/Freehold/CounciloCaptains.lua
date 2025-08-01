local mod	= DBM:NewMod(2093, "DBM-Party-BfA", 2, 1001)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic,challenge,timewalker"

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(126845, 126847, 126848)--Captain Jolly, Captain Raoul, Captain Eudora
mod:SetEncounterID(2094)
mod:DisableRegenDetection()
mod:DisableFriendlyDetection()
mod:SetHotfixNoticeRev(20230922000000)
mod:SetMinSyncRevision(20230922000000)
mod:SetZone(1754)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 258338 256589 257117 267522 272884 267533 272902 265088 264608 265168 256979 281329",
	"SPELL_CAST_SUCCESS 258381",
	"SPELL_AURA_APPLIED 265085 265056 278467",
	"SPELL_DAMAGE 272397",
	"SPELL_MISSED 272397",
	"UNIT_DIED"
)

--TODO: target scan Blackout Barrel?
--TODO, rework brews if target scanning of which boss it's being casting toward is possible.
--[[
(ability.id = 258338 or ability.id = 256589 or ability.id = 257117 or ability.id = 267522 or ability.id = 272884 or ability.id = 267533 or ability.id = 272902 or ability.id = 265088 or ability.id = 264608 or ability.id = 265168 or ability.id = 256979 or ability.id = 281329) and type = "begincast"
 or ability.id = 258381 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 --]]
--General
----Announce Brews
--text, color, icon, optionDefault, optionName, soundOption, spellID
local warnGoodBrew					= mod:NewAnnounce("warnGoodBrew", 1, 265088, nil, nil, nil, 264605)
local warnCausticBrew				= mod:NewCastAnnounce(265168, 4)
local warnCausticBrewOnBoss			= mod:NewTargetNoFilterAnnounce(278467, 1)

local specWarnBrewOnBoss			= mod:NewSpecialWarning("specWarnBrewOnBoss", "Tank", nil, nil, 1, 2)

local timerTendingBarCD				= mod:NewNextTimer(8, 264605, nil, nil, nil, 3)

--mod:GroupSpells(264605, 265168)--Group good brew and bad brew with "tending Bar"
--Jolly
mod:AddTimerLine(DBM:EJ_GetSectionInfo(17025))
local warnLuckySevens				= mod:NewSpellAnnounce(257117, 1)

local specWarnCuttingSurge			= mod:NewSpecialWarningDodge(267522, nil, nil, nil, 2, 2)
local specWarnWhirlpoolofBlades		= mod:NewSpecialWarningDodge(267533, nil, nil, nil, 2, 2)
local specWarnGTFO					= mod:NewSpecialWarningGTFO(272397, nil, nil, nil, 1, 8)

----Hostile
local timerCuttingSurgeCD			= mod:NewCDTimer(22.7, 267522, nil, nil, nil, 3)
local timerWhirlpoolofBladesCD		= mod:NewCDTimer(22.7, 267533, nil, nil, nil, 3)
----Friendly
local timerLuckySevensCD			= mod:NewNextTimer(29.1, 257117, nil, nil, nil, 5)
local timerTradeWindsVigorCD		= mod:NewNextTimer(26.7, 281329, nil, nil, nil, 5)

mod:AddRangeFrameOption(5, 267522)
--Raoul
mod:AddTimerLine(DBM:EJ_GetSectionInfo(17023))
local warnTappedKeg					= mod:NewSpellAnnounce(272884, 1)

local specWarnBarrelSmash			= mod:NewSpecialWarningRun(256589, "Melee", nil, nil, 4, 2)
local specWarnBlackoutBarrel		= mod:NewSpecialWarningSwitch(258338, "-Healer", nil, 2, 1, 2)

----Hostile
local timerBarrelSmashCD			= mod:NewCDTimer(22.9, 256589, nil, "Melee", nil, 3)--22.9-24.5
local timerBlackoutBarrelCD			= mod:NewCDTimer(46.1, 258338, nil, nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON)
----Friendly
local timerTappedKegCD				= mod:NewNextTimer(22.3, 272884, nil, nil, nil, 5)
--Eudora
mod:AddTimerLine(DBM:EJ_GetSectionInfo(17024))
local warnChainShot					= mod:NewSpellAnnounce(272902, 1)
local warnPowderShot				= mod:NewTargetNoFilterAnnounce(256979, 3)

local specWarnGrapeShot				= mod:NewSpecialWarningDodge(258381, nil, nil, nil, 3, 2)
local specWarnPowderShot			= mod:NewSpecialWarningYou(256979, nil, nil, nil, 1, 2)

----Hostile
local timerGrapeShotCD				= mod:NewNextTimer(30.2, 258381, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
----Friendly
local timerChainShotCD				= mod:NewNextTimer(15.3, 272902, nil, nil, nil, 5)

local function scanCaptains(self, isPull, delay)
	local foundOne, foundTwo, foundThree
	for i = 1, 3 do
		local unitID = "boss"..i
		if UnitExists(unitID) then
			local cid = self:GetUnitCreatureId(unitID)
			local bossGUID = UnitGUID(unitID)
			if not UnitIsFriend("player", unitID) then
				if not foundOne then foundOne = cid
				elseif not foundTwo then foundTwo = cid
				else foundThree = cid end
				--Set hostile timers
				if isPull then--Only do on pull, if recovery, these will be synced when vb table sent
					if cid == 126845 then--Jolly
						timerCuttingSurgeCD:Start(4.1-delay, bossGUID)
						timerWhirlpoolofBladesCD:Start(9.8-delay, bossGUID)
						if self.Options.RangeFrame then
							DBM.RangeCheck:Show(5)
						end
					elseif cid == 126847 then--Raoul
						timerBarrelSmashCD:Start(5-delay, bossGUID)
						timerBlackoutBarrelCD:Start(16.9-delay, bossGUID)
					else--Eudora
						timerGrapeShotCD:Start(7.3-delay, bossGUID)
					end
				end
			else--Friendly
				--Set friendly Timers
				if isPull then--Only do on pull, if recovery, these will be synced when vb table sent
					if cid == 126845 then--Jolly
						if not self:IsMythicPlus() then--On M+ he uses Trade Wind's Vigor 1 second into pull
							timerLuckySevensCD:Start(9.8-delay, bossGUID)
						end
					elseif cid == 126847 then--Raoul
						timerTappedKegCD:Start(12.2-delay, bossGUID)
					else--Eudora
						timerChainShotCD:Start(4.2-delay, bossGUID)
					end
				end
			end
		end
	end
	if foundTwo then
		if foundThree then
			self:SetCreatureID(foundOne, foundTwo, foundThree)
		else
			self:SetCreatureID(foundOne, foundTwo)
		end
	end
end

function mod:PowderShotTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnPowderShot:Show()
		specWarnPowderShot:Play("targetyou")
	else
		warnPowderShot:Show(targetname)
	end
end

function mod:OnCombatStart(delay)
	if not self:IsNormal() then
		timerTendingBarCD:Start(8-delay)
	end
	self:Schedule(1, scanCaptains, self, true, delay)--1 second delay to give IEEU time to populate boss unitIDs
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:OnTimerRecovery()
	scanCaptains(self)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 258338 then
		specWarnBlackoutBarrel:Show()
		specWarnBlackoutBarrel:Play("changetarget")
		timerBlackoutBarrelCD:Start(nil, args.sourceGUID)
	elseif spellId == 256589 then
		specWarnBarrelSmash:Show()
		specWarnBarrelSmash:Play("justrun")
		timerBarrelSmashCD:Start(nil, args.sourceGUID)
	elseif spellId == 257117 then
		warnLuckySevens:Show()
		timerLuckySevensCD:Start(nil, args.sourceGUID)
	elseif spellId == 281329 then

		timerTradeWindsVigorCD:Start(nil, args.sourceGUID)
	elseif spellId == 267522 then
		specWarnCuttingSurge:Show()
		specWarnCuttingSurge:Play("chargemove")
		timerCuttingSurgeCD:Start(nil, args.sourceGUID)
	elseif spellId == 272884 then
		warnTappedKeg:Show()
		timerTappedKegCD:Start(nil, args.sourceGUID)
	elseif spellId == 267533 then
		specWarnWhirlpoolofBlades:Show()
		specWarnWhirlpoolofBlades:Play("watchstep")
		timerWhirlpoolofBladesCD:Start(nil, args.sourceGUID)
	elseif spellId == 272902 then
		warnChainShot:Show()
		timerChainShotCD:Start(nil, args.sourceGUID)
	elseif spellId == 265088 or spellId == 264608 or spellId == 265168 then
		if spellId == 265168 then
			warnCausticBrew:Show()
		elseif spellId == 265088 then
			warnGoodBrew:Show(L.critBrew)
		else--264608
			warnGoodBrew:Show(L.hasteBrew)
		end
		timerTendingBarCD:Start()
	elseif spellId == 256979 and self:IsMythic() then
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "PowderShotTarget", 0.1, 16, true, nil, nil, nil, true)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 258381 then
		specWarnGrapeShot:Show()
		specWarnGrapeShot:Play("stilldanger")
		timerGrapeShotCD:Start(nil, args.sourceGUID)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if (spellId == 265085 or spellId == 265056) and self:AntiSpam(3, 2) then
		local unitId = self:GetUnitIdFromGUID(args.destGUID, true)
		if unitId and UnitIsEnemy("player", unitId) then
			specWarnBrewOnBoss:Show(args.destName)
			specWarnBrewOnBoss:Play("moveboss")
		end
	elseif spellId == 278467 and self:AntiSpam(3, 2) then
		local unitId = self:GetUnitIdFromGUID(args.destGUID, true)
		if unitId and UnitIsEnemy("player", unitId) then
			warnCausticBrewOnBoss:Show(args.destName)
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 272397 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) and not self:IsTank() then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 126845 then--Captain Jolly
		timerCuttingSurgeCD:Stop(args.destGUID)
		timerWhirlpoolofBladesCD:Stop(args.destGUID)
		timerLuckySevensCD:Stop(args.destGUID)
		timerTradeWindsVigorCD:Stop(args.destGUID)
	elseif cid == 126847 then--Captain Raoul
		timerBarrelSmashCD:Stop(args.destGUID)
		timerBlackoutBarrelCD:Stop(args.destGUID)
		timerTappedKegCD:Stop(args.destGUID)
	elseif cid == 126848 then--Captain Eudora
		timerGrapeShotCD:Stop(args.destGUID)
		timerChainShotCD:Stop(args.destGUID)
	elseif cid == 133219 then--Rummy Mancomb (You bastard, you killed Rummy!)
		timerTendingBarCD:Stop()
	end
end
