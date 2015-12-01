Scriptname P4PTestScript extends ObjectReference

import FISSFactory  
import Game

Event OnDeath(Actor akKiller)
	;If player has levelled up, notify onscreen
	Actor player = Game.GetPlayer()
	
	If (akKiller == player)
		float preCalculationXP = Game.GetPlayerExperience()
		float requiredXP =  Game.GetExperienceForLevel(Game.GetPlayer().GetLevel())
		
		;Game.SetPlayerExperience(preCalculationXP  + (requiredXP - preCalculationXP) - 2)
		float postCalculationXP = Game.GetPlayerExperience()
		
		if (postCalculationXP >= requiredXP)
			Debug.MessageBox("You have levelled up, congratulations!")
		EndIf
	EndIf

	;saveJSON ;function test call
	;int value = LoadJSON()
	;saveJSON()

	;Game.SetGameSettingFloat("fXPPerSkillRank", 0.00000)

	Debug.MessageBox("FXXPERSKILLRANK" + Game.GetGameSettingFloat("fXPPerSkillRank"))

EndEvent

;Event OnLoad()
;	Debug.MessageBox("OnLoad")
;EndEvent

int Function LoadJSON()
	FISSInterface fiss = FISSFactory.getFISS()

	If !fiss
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
	EndIf

	fiss.beginLoad("MyTest.json")
	
	;string valueString = fiss.loadString("mystringtest")
	;int value = valueString as int
	int value = fiss.loadInt("xpValue")
	string valueString = fiss.loadString("type")
	
	string end = fiss.endLoad()
	;Debug.MessageBox("value = " + valueString + ", end = " + end)
	return value
EndFunction

Function saveJSON()
	FISSInterface fiss = FISSFactory.getFISS()

	If !fiss
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return
	EndIf

	fiss.beginSave("MyTest.json", "Rahul")
	
	;string mystring = "mystringtest"
	;fiss.saveString("mystringtest", mystring)
	int xpValue = 200
	fiss.saveInt("xpValue", xpValue)

	fiss.saveString("fitness_exercise 1", "Cycling")
	
	string saveResult = fiss.endSave()
	If saveResult != ""
		Debug.Trace(saveResult)
	EndIf
EndFunction