local mod	= DBM:NewMod(470, "DBM-Party-Vanilla", DBM:IsPostCata() and 13 or 18, 239)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(7206)
mod:SetEncounterID(551)
mod:SetZone(70)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 10132 10094"
)

local warningSandStorms				= mod:NewSpellAnnounce(10132, 2)

local timerSandStormsCD				= mod:NewAITimer(180, 10132, nil, nil, nil, 3)

function mod:OnCombatStart(delay)
	timerSandStormsCD:Start(1-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpell(10132, 10094) then
		warningSandStorms:Show()
		timerSandStormsCD:Start()
	end
end
