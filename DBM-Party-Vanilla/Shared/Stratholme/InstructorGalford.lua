local mod	= DBM:NewMod(448, "DBM-Party-Vanilla", DBM:IsPostCata() and 10 or 16, 236)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(10811)
mod:SetEncounterID(477)
mod:SetZone(329)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 17293",
	"SPELL_CAST_SUCCESS 17366",
	"SPELL_AURA_APPLIED 17293"
)

local warningBurningWinds			= mod:NewTargetNoFilterAnnounce(17293, 2)
local warningFireNova				= mod:NewSpellAnnounce(17366, 2)

local timerBurningWindsCD			= mod:NewAITimer(180, 17293, nil, nil, nil, 3, nil, DBM_COMMON_L.MAGIC_ICON)
local timerFireNovaCD				= mod:NewAITimer(180, 17366, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	timerBurningWindsCD:Start(1-delay)
	timerFireNovaCD:Start(1-delay)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpell(17293) then
		timerBurningWindsCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpell(17366) then
		warningFireNova:Show()
		timerFireNovaCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpell(17293) then
		warningBurningWinds:Show(args.destName)
	end
end
