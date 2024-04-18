local mod	= DBM:NewMod(2586, "DBM-Party-WarWithin", 7, 1272)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(210271)
mod:SetEncounterID(2900)
--mod:SetHotfixNoticeRev(20220322000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 442525 432198 432179 432229",
--	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED 431896",
	"SPELL_AURA_REMOVED 442525 431896",
	"SPELL_PERIODIC_DAMAGE 432182",
	"SPELL_PERIODIC_MISSED 432182"
--	"UNIT_SPELLCAST_SUCCEEDED"--All units since we need to find adds casting it (unless boss does)
)

--TODO, or use 442611 removed (Disregard) if happy hour removed doesn't work
--TODO, upgrade brawl to higher prio warning?, assuming detection even valid
--TODO, verify nameplate aura for thirsty/Rowdy patrons, cause if they aren't hostile it won't work (in which case switch to auto marking probably)
--TODO, reset counts on happy hour?
local warnHappyHour							= mod:NewSpellAnnounce(442525, 3)
local warnHappyHourOver						= mod:NewEndAnnounce(442525, 2)
local warnThrowCinderbrew					= mod:NewSpellAnnounce(432179, 2)

local specWarnBlazingBelch					= mod:NewSpecialWarningDodgeCount(432198, nil, nil, nil, 2, 2)
local specWarnKegSmash						= mod:NewSpecialWarningCount(432229, nil, nil, nil, 1, 2)
--local yellSomeAbility						= mod:NewYell(372107)
local specWarnBrawl							= mod:NewSpecialWarningDodge(445180, nil, nil, nil, 2, 2)
local specWarnGTFO							= mod:NewSpecialWarningGTFO(432182, nil, nil, nil, 1, 8)

local timerHappyHourCD						= mod:NewAITimer(33.9, 442525, nil, nil, nil, 6)
local timerBlazingBelchCD					= mod:NewAITimer(33.9, 432198, nil, nil, nil, 3)
local timerThrowCinderbrewCD				= mod:NewAITimer(33.9, 432179, nil, nil, nil, 3)
local timerKegSmashCD						= mod:NewAITimer(33.9, 432229, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON)

mod:AddNamePlateOption("NPAuraOnThirsty", 431896)

mod.vb.happyHourCount = 0
mod.vb.belchCount = 0
mod.vb.cinderbrewCount = 0
mod.vb.kegCount = 0

function mod:OnCombatStart(delay)
	self.vb.happyHourCount = 0
	self.vb.belchCount = 0
	self.vb.cinderbrewCount = 0
	self.vb.kegCount = 0
	timerBlazingBelchCD:Start(1)
	timerHappyHourCD:Start(1)
	timerThrowCinderbrewCD:Start(1)
	timerKegSmashCD:Start(1)
	if self.Options.NPAuraOnThirsty then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
end

function mod:OnCombatEnd()
	if self.Options.NPAuraOnThirsty then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 442525 then
		self.vb.happyHourCount = self.vb.happyHourCount + 1
		warnHappyHour:Show()
		timerBlazingBelchCD:Stop()
		timerThrowCinderbrewCD:Stop()
		timerKegSmashCD:Stop()
	elseif spellId == 432198 then
		self.vb.belchCount = self.vb.belchCount + 1
		specWarnBlazingBelch:Show(self.vb.belchCount)
		specWarnBlazingBelch:Play("breathsoon")
		timerBlazingBelchCD:Start()
	elseif spellId == 432179 then
		self.vb.cinderbrewCount = self.vb.cinderbrewCount + 1
		warnThrowCinderbrew:Show(self.vb.cinderbrewCount)
		timerThrowCinderbrewCD:Start()
	elseif spellId == 432229 then
		self.vb.kegCount  = self.vb.kegCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnKegSmash:Show(self.vb.kegCount)
			specWarnKegSmash:Play("carefly")
		end
		timerKegSmashCD:Start()
	end
end

--[[
function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 372858 then

	end
end
--]]

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 431896 then
		if self.Options.NPAuraOnThirsty then
			DBM.Nameplate:Show(true, args.destGUID, spellId)
		end
	end
end
--mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 442525 then
		warnHappyHourOver:Show()
		if self:IsMythic() then
			specWarnBrawl:Show()
			specWarnBrawl:Play("watcstep")
		end
		timerHappyHourCD:Start(2)
		timerBlazingBelchCD:Start(2)
		timerThrowCinderbrewCD:Start(2)
		timerKegSmashCD:Start(2)
	elseif spellId == 431896 then
		if self.Options.NPAuraOnThirsty then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 432182 and destGUID == UnitGUID("player") and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

--[[
function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 193435 then

	end
end
--]]

--[[
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 445150 and self:AntiSpam(3, 1) then
		specWarnBrawl:Show()
	end
end
--]]
