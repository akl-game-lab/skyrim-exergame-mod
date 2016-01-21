Scriptname P4PQuestScript extends Quest

import ObjectReference
import StringUtil
import FISSFactory

MiscObject Property OrbOfExperience  Auto  

{This function schedules an update in the next hour}
Event OnInit()
	;Use when testing as waiting an hour is too long
	Debug.Notification("NEXT UPDATE REGISTERED IN 30SECS")
	RegisterForSingleUpdate(30)
	;When shipping the game, switch to 3600 seconds for each update
	;RegisterForSingleUpdate(3600)
EndEvent

Event OnUpdate()

	Debug.Notification("UPDATE TRIGGERED")
	;testing to see the orb of exp
	Actor player = Game.GetPlayer()
	
	int stage = GetStage()

	;If the player holds atleast 1 OrbOfExperience, level up the character
	If ((player.GetItemCount(OrbOfExperience) > 0) && (0))
		;This message gets shown to the player to prevent them from being able to quit mid level up.
		;Think of how other games have a message saying "Saving game... Please do not turn off the system".
		;We do not want users to quit mid level up as it will likely break the file FISS reads/writes and also result in a lost level up.
		Debug.MessageBox("An orb of experience resonates")
		
		;Provides a level up to the player and then returns the remaining level up distributions to be written into the level up distribution file again.
		string[] levelDists = levelUp()
		player.RemoveItem(OrbOfExperience, 1)
		tidyDistributionFile(levelDists)
	
		;If the player still has orbs of experience, their experience bar should be full to indicate this. Otherwise it should be proportional to the points they have towards the level. 
		If (player.GetItemCount(OrbOfExperience) > 0)
			float requiredXPToLevelUp =  Game.GetExperienceForLevel(player.GetLevel())
			Game.SetPlayerExperience(requiredXPToLevelUp - 1)
		Else
			FISSInterface fread = FISSFactory.getFISS()
			If !fread 
				Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
				return None
			EndIf
	
				fread.beginLoad("Exercise_data.txt")
		
				int strengthPoints = fread.loadInt("Outstanding_strength_points")
				int fitnessPoints = fread.loadInt("Outstanding_fitness_points")
				int sportPoints = fread.loadInt("Outstanding_sport_points")
			
				string end = fread.endLoad()

			Game.SetPlayerExperience(strengthPoints + fitnessPoints + sportPoints)
		EndIf
	EndIf

	;Re-register for an update
	RegisterForSingleUpdate(30)
EndEvent

string[] Function levelUp()
	;Bug: If both fiss calls are done at the same time, it is very likely it'll fuck up causing only one of the updates to occur. Threading issue. Not sure how we'll tackle it.

	FISSInterface fread = FISSFactory.getFISS()
	If !fread 
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return None
	EndIf

	fread.beginLoad("StackedLevelDistributions.txt")
	string levelDistToUse = fread.LoadString("Level Distribution 0")
	string levelDistOne = fread.LoadString("Level Distribution 1")
	string levelDistTwo = fread.LoadString("Level Distribution 2")
	string levelDistThree = fread.LoadString("Level Distribution 3")
	string levelDistFour = fread.LoadString("Level Distribution 4")

	string end = fread .endLoad()
	Debug.MessageBox("X" + levelDistToUse + "X")
	
	string[] remainingDists = new string[4]
	remainingDists[0] = levelDistOne
	remainingDists[1] = levelDistTwo
	remainingDists[2] = levelDistThree
	remainingDists[3] = levelDistFour

	;just changed the implementation of the substring to grab the correct values
	string healthString = SubString(levelDistToUse, 1, 2)
	string staminaString = SubString(levelDistToUse, 4, 2)
	string magickaString = SubString(levelDistToUse, 7, 2)
	
	Debug.MessageBox("ADDED HEALTH: " + healthString)
	Debug.MessageBox("ADDED STAMINA: " + staminaString)
	Debug.MessageBox("ADDED MAGICKA: " + magickaString)
	
	int healthAmount = healthString as int 
	int staminaAmount = staminaString as int
	int magickaAmount = magickaString as int

	;Need to adjust positions of other levelDists in the file so we dont lose them/reuse the same one over and over
	Actor player = Game.GetPlayer()
	player.ModActorValue("health", healthAmount)
	player.ModActorValue("stamina", staminaAmount)
	player.ModActorValue("magicka", magickaAmount)

	Game.SetPlayerLevel(Game.GetPlayer().GetLevel() + 1)
	Game.SetPerkPoints(Game.GetPerkPoints() + 1)

	Debug.MessageBox("An orb of experience has been used to level up. You have gained " + healthAmount + " into health, " + staminaAmount + " into stamina, " + magickaAmount + " into magicka!")
	return remainingDists
EndFunction

;Reposition 
Function tidyDistributionFile(string[] levelDists)
	FISSInterface fwrite = FISSFactory.getFISS()
	If !fwrite
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return
	EndIf

	fwrite.beginSave("StackedLevelDistributions.txt", "P4P")

	int pos = 0
	Actor player = Game.GetPlayer()
	int numberOfOrbs = player.GetItemCount(OrbOfExperience)
	While (pos < numberOfOrbs)
		fwrite.saveString("Level Distribution " + pos, levelDists[pos])
		pos = pos + 1 
	EndWhile

	string end = fwrite.endSave()
	;File looks very fucked after a tidy when opened in notepad, however it functions correctly when manipulated by Creation Kit.
EndFunction
