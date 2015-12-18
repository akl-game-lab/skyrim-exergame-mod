;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 46
Scriptname QF_P4PExergameQuest_03001828 Extends Quest Hidden

;BEGIN ALIAS PROPERTY NPCQuestMaster
;ALIAS PROPERTY TYPE ReferenceAlias
ReferenceAlias Property Alias_NPCQuestMaster Auto
;END ALIAS PROPERTY

;BEGIN ALIAS PROPERTY PlayerAlias
;ALIAS PROPERTY TYPE ReferenceAlias
ReferenceAlias Property Alias_PlayerAlias Auto
;END ALIAS PROPERTY

;BEGIN FRAGMENT Fragment_39
Function Fragment_39()
;BEGIN CODE
;Reset variables to default Skyrim values
Game.SetGameSettingFloat("fXPLevelUpBase", 75)
Game.SetGameSettingFloat("fXPLevelUpMult", 25)
Game.SetPlayerExperience(0)
Game.SetGameSettingFloat("fXPPerSkillRank", 1)

Debug.MessageBox("Road to fitness quest has been abandoned. Skyrim has reset to it's vanilla levelling system")
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_4
Function Fragment_4()
;BEGIN CODE
;Set level modifiers to first week calibration values which match an average player's progression
;And reset the player's experience bar so that they start with a clean slate in terms of level progression
;as it should all be exercise based now
Game.SetGameSettingFloat("fXPLevelUpBase", (411/(540/16)))
Game.SetGameSettingFloat("fXPLevelUpMult", (411/(540/10)))
Game.SetPlayerExperience(0)
Game.SetGameSettingFloat("fXPPerSkillRank", 0.00000)

;Then award a free level up to the player for accepting the quest and trigger the next quest stage
Actor player = Game.GetPlayer()
int currentPlayerLevel =player.GetLevel()
int currentPerkPoints = Game.GetPerkPoints()
float currentHealth = player.GetActorValue("health")

player.SetActorValue("health", currentHealth + 10)
Game.SetPlayerLevel(currentPlayerLevel + 1)
Game.SetPerkPoints(currentPerkPoints + 1)
Debug.MessageBox("Congratulations on your quest to greater fitness! As a incentive, you have been awarded a free level!")

SetStage(20)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_43
Function Fragment_43()
;BEGIN CODE
SetObjectiveDisplayed(20)
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_41
Function Fragment_41()
;BEGIN CODE
SetObjectiveDisplayed(5)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

MiscObject Property OOXPmiscItem  Auto  

WEAPON Property BladeOfExperience  Auto  
