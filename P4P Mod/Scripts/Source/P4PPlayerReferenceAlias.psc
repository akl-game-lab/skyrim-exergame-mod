Scriptname P4PPlayerReferenceAlias extends ReferenceAlias

import FISSFactory
import Game
import StringUtil

MiscObject Property OrbOfExperience  Auto  
Location Property HelgenKeep  Auto

int strengthPoints = 0
int fitnessPoints = 0
int sportsPoints = 0

string firstImportDate = ""
int firstWeekPoints = 0
string lastUpdateDate = ""
string firstWeekCompleted = ""

bool LeftHelgen = false

;Event called whenever a game is loaded. In Skyrim, when a player dies it counts as a game reload as well.
;might need to add a bit that checks fotr the quest stage.
Event OnPlayerLoadGame()
	Actor player = Game.GetPlayer()
	int currentPlayerLevel = Game.GetPlayer().GetLevel()
	bool readyForLeveling = false

	;Turn off in-game experience if it is on. This technically should never be entered but has been checked for as a safety precaution.
	If (Game.GetGameSettingFloat("fXPPerSkillRank") != 0)
		Game.SetGameSettingFloat("fXPPerSkillRank", 0)
	EndIf

	;If the quest stage is in stage 20, it means that the player will receive a level up once they've synced their accounts with the game.
	;If the exercise_data file exists, it implies they've synced and we can therefore award the player a level up.
	If (GetOwningQuest().GetStage() == 20)

		FISSInterface fread = FISSFactory.getFISS()
		If !fread 
			Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
			return None
		EndIf

		fread.beginLoad("Exercise_data.txt")
		string readInSuccess = fread.endLoad()

		;If readInSuccess != "" it implies that the file has not been found, therefore that the player has not synced the game with their accounts yet.
		If readInSuccess != ""
			return 
		EndIf
		
		int currentPerkPoints = Game.GetPerkPoints()
		float currentStamina = player.GetActorValue("stamina")

		player.SetActorValue("stamina", currentStamina + 10)
		Game.SetPlayerLevel(currentPlayerLevel + 1)
		Game.SetPerkPoints(currentPerkPoints + 1)

		GetOwningQuest().SetStage(25)
		Debug.MessageBox("Your first sync has been detected! Great work!")
		Debug.MessageBox("Congratulations you've leveled up. Keep up the good work!")

	;Else if the quest is in the first week calibration phase for the players fitness levels
	ElseIf (GetOwningQuest().GetStage() >= 25) && (GetOwningQuest().GetStage() <= 45)
		FISSInterface fread = FISSFactory.getFISS()
		If !fread 
			Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
			return None
		EndIf

		fread.beginLoad("Exercise_data.txt")
		firstWeekCompleted = fread.loadString("First_week_completed")
		;If the first week has been completed, progress the quest to stage 50.
		If (firstWeekCompleted == " True ")
			GetOwningQuest().SetStage(50)
		;Else readyForLevelling = true. This means that the player is in the first week, but needs to be levelled up and/or needs to have level modifiers adjusted
		Else
			readyForLeveling = true
		EndIf
		string end = fread.endLoad()

	EndIf

	;If the first week has been completed, or the player is in the first week, we must still update their attributes and the experience requirements for each level
	If ((GetOwningQuest().GetStage() > 45) || readyForLeveling)
		LoadSessionData()

		;Set the player's experience bar progress to 0 during the level modifer changing phase so that no inadvertent level ups occur
		Game.SetPlayerExperience(0)

		setLevelModifiers(readyForLeveling)

		;Update the player's stats based off the amount of experience they have gained from their exercise
		;Priority goes to levelling up health first, then stamina, then magicka. This was a design decision made by Rahul as health is a generic stat each class would require (i.e. mage or warrior)
		UpdatePlayerStats()

		;Remove points expended by these level ups from the exercise_data file
		RemoveThisSessionData()

		;Add left over experience to the player's progress bar
		UpdateExperienceProgressBar()
	EndIf

	;Ensure in-game experience cannot be earned/has been turned on
	If (Game.GetGameSettingFloat("fXPPerSkillRank") != 0)
		Game.SetGameSettingFloat("fXPPerSkillRank", 0)
	EndIf
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)	
	If (GetOwningQuest().GetStage() == 0)
		if ((akNewLoc != HelgenKeep ) && ( akOldLoc == HelgenKeep ) && (!LeftHelgen))
			GetOwningQuest().setstage(5)
			GetOwningQuest().setActive()
			LeftHelgen = true
			Debug.MessageBox("stage set to 5 and active")
		endif
	endif

EndEvent


;Adjusts the level modifiers which are used to determine the experience requirements for level ups in-game
;Param: firstWeekAdjustmentDue. This param is used to check whether the player is still in the calibration
;								week of the quest
Function setLevelModifiers(bool firstWeekAdjustmentDue)
	Actor player = Game.GetPlayer()
	int playerLevel = player.GetLevel()
	float levelUpBase = 0
	float levelUpMultiplier = 0
	
	float currentPlayerXP = Game.GetPlayerExperience()
	int questStage = GetOwningQuest().GetStage()

	;If the player has received their two free level ups from the quest, we need to start changing the experience requirements for level ups
	If (questStage >= 25)

		;Set the player's experience bar progress to 0 during the level modifer changing phase so that no inadvertent level ups occur
		Game.SetPlayerExperience(0)

		;The player's first week level adjustments are originally done when they accept the quest, in stage X.
		;These adjustments are fine until the player reaches levels 6, 7, 8, 9. At these levels, we want the amount
		;of work required to level up to increase so that players do not go past level 9 in the first week.

		;Level adjustments are done by manipulating the two variables the level up formula uses which are, fXPLevelUpBase and fXPLevelUpMult.
		;We detect where a player is in terms of their level using a stages system, instead of directly looking at their level, to recalculate these.
		;We look at stages, instead of the level directly as in future, it may be worth looking at different ways of implementing the calibration week
		;points system.

		If (firstWeekAdjustmentDue)
			If playerLevel == 6
				GetOwningQuest().SetStage(30)
			ElseIf playerLevel == 7
				GetOwningQuest().SetStage(35)
			ElseIf playerLevel == 8
				GetOwningQuest().SetStage(40)
			ElseIf playerLevel == 9
				GetOwningQuest().SetStage(45)
			EndIf

			If questStage == 25
				levelUpBase = 411/(540/16)
				levelUpMultiplier = 411/(540/10)
			ElseIf questStage == 30
				levelUpBase = (411/(540/16)) * 2
				levelUpMultiplier = (411/(540/10)) * 2
			ElseIf questStage == 35
				levelUpBase = (411/(540/16)) * 4
				levelUpMultiplier = (411/(540/10)) * 4
			ElseIf questStage == 40
				levelUpBase = (411/(540/16)) * 8
				levelUpMultiplier = (411/(540/10)) * 8
			ElseIf questStage == 45
				levelUpBase = (411/(540/16)) * 16
				levelUpMultiplier = (411/(540/10)) * 16
			EndIf

		Else
			FISSInterface fread = FISSFactory.getFISS()
			If !fread
				Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
				return None
			EndIf

			;Read in the first week points a player has accumulated
			fread.beginLoad("Exercise_data.txt")
			firstWeekPoints = fread.loadInt("First week points")
			string end = fread.endLoad()
	
			;We use 4 level brackets which scale the experience requirements for level ups to the player's progress in-game.
			;These brackets range from levels:
			;		4 to 9
			;		10 to 19
			;		20 to 29
			;		30 to infinite (As of patch 1.9, the level cap of 81 was removed which was what we initially based these brackets on)	
			;End game of Skyrim can be completed at around level 35 so levelling will be less important past this point

			;Look at the XP-Sheet DONE.xlsx and XP Documentation.pdf to see how bracket calculations were made to scale towards a player
			If (playerLevel < 10)
				levelUpBase = firstWeekPoints/33.75
				levelUpMultiplier = firstWeekPoints/54.0
			ElseIf (playerLevel >= 10) && (playerLevel <= 19)
				float temp = firstWeekPoints * 2.6666666667
				levelUpBase = temp/22.154
				levelUpMultiplier = temp/288.0
			ElseIf (playerLevel >= 20) && (playerLevel <= 29)
				float temp = firstWeekPoints * 2.6666666667 * 1.25
				levelUpBase = temp/17.143
				levelUpMultiplier = temp/600.0
			ElseIf (playerLevel >= 30)
				float temp = firstWeekPoints * 2.6666666667 * 1.25 * 1.4
				levelUpBase = temp/16.5
				levelUpMultiplier = temp/1237.5
			EndIf

		EndIf

		Game.SetGameSettingFloat("fXPLevelUpBase", levelUpBase)
		Game.SetGameSettingFloat("fXPLevelUpMult", levelUpMultiplier)
	EndIf
EndFunction


;Similar to the above method but this checks whether a player has entered a new bracket
;after levelling up, such as going from level 9 to 10.
Function UpdateLevelModifiers(int oldPlayerLevel, int newPlayerLevel)
	float levelUpBase = 0
	float levelUpMultiplier = 0
	int bracketChangedTo = 1

	;Check which level bracket the player has changed into
	If (oldPlayerLevel <= 9) && (newPlayerLevel >= 10)
		bracketChangedTo = 2
	ElseIf (oldPlayerLevel >= 10) && (newPlayerLevel >= 19) && (newPlayerLevel < 29)
		bracketChangedTo = 3
	ElseIf (oldPlayerLevel >= 20) && (newPlayerLevel >= 29)
		bracketChangedTo = 4
	EndIf

	If bracketChangedTo != 1
		FISSInterface fread = FISSFactory.getFISS()
		If !fread 
			Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
			return None
		EndIf
		
		fread.beginLoad("Exercise_data.txt")
		firstWeekPoints = fread.loadInt("First week points")
		string end = fread.endLoad()	

		;Using which bracket the player has switched to, recalculate the player's experience requirement
		If bracketChangedTo == 2
			float temp = firstWeekPoints * 2.6666666667
			levelUpBase = temp/22.154
			levelUpMultiplier = temp/288.0
		ElseIf bracketChangedTo == 3
			float temp = firstWeekPoints * 2.6666666667 * 1.25
			levelUpBase = temp/17.143
			levelUpMultiplier = temp/600.0
		ElseIf bracketChangedTo == 4
			float temp = firstWeekPoints * 2.6666666667 * 1.25 * 1.4
			levelUpBase = temp/16.5
			levelUpMultiplier = temp/1237.5
		EndIf

		Game.SetGameSettingFloat("fXPLevelUpBase", levelUpBase)
		Game.SetGameSettingFloat("fXPLevelUpMult", levelUpMultiplier)
		Debug.MessageBox("Congratulations on reaching level " + newPlayerLevel + "! Remember to work hard for the gains.")
	EndIf

EndFunction


;Load data required to level up the player
Function LoadSessionData()
	FISSInterface fread = FISSFactory.getFISS()
	If !fread
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return
	EndIf

	fread.beginLoad("Exercise_data.txt")

	firstImportDate = fread.loadString("First_import_date")
	firstWeekPoints = fread.loadString("First week points") as int
	lastUpdateDate = fread.loadString("Last_update_date")
	firstWeekCompleted = fread.loadString("First_week_completed")

	strengthPoints = fread.loadInt("Outstanding_strength_points")
	fitnessPoints = fread.loadInt("Outstanding_fitness_points")
	sportsPoints = fread.loadInt("Outstanding_sport_points")

	string endRead = fread.endLoad()
EndFunction


;Update the exercise_data file after points have been spent to ensure players cannot get multiple level ups from the same exercise session points
Function RemoveThisSessionData()
	FISSInterface fwrite = FISSFactory.getFISS()
	If !fwrite 
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return
	EndIf

	fwrite.beginSave("Exercise_data.txt", "P4P")

	fwrite.saveString("First_import_date", firstImportDate)
	fwrite.saveString("First week points", firstWeekPoints)
	fwrite.saveString("Last_update_date", lastUpdateDate)
	fwrite.saveString("First_week_completed", firstWeekCompleted)

	fwrite.saveString("Outstanding_strength_points", strengthPoints)
	fwrite.saveString("Outstanding_fitness_points", fitnessPoints)
	fwrite.saveString("Outstanding_sport_points", sportsPoints)

	string endWrite = fwrite.endSave()
EndFunction


;Increase the player's level by 1 and reward 1 perk point
Function levelUp()
	Game.SetPlayerLevel(Game.GetPlayer().GetLevel() + 1)
	Game.SetPerkPoints(Game.GetPerkPoints() + 1)	
EndFunction


;Update the player's main attributes based on the amount and types of exercise they've done
;The attributes are awarded in a certain order. Health has the priority of being levelled up,
;followed by stamina, and magicka.
Function UpdatePlayerStats()
	Actor player = Game.GetPlayer()
	int playerLevel = player.GetLevel()
	float currentPlayerXP = Game.GetPlayerExperience()
	float requiredXPToLevelUp = Game.GetExperienceForLevel(playerLevel) - currentPlayerXP
	int currentPerkPoints = Game.GetPerkPoints()

	float healthPercentage = 0
	float staminaPercentage = 0
	float magickaPercentage = 0

	int healthAmount = 0
	int staminaAmount = 0
	int magickaAmount = 0
	int remainingAmount = 0
	bool levelComplete = false

	If (strengthPoints >= requiredXPToLevelUp)
		healthAmount = 10
		player.ModActorValue("health", healthAmount)
		levelUp()
		strengthPoints = (strengthPoints - requiredXPToLevelUp) as int
		levelComplete = true
		requiredXPToLevelUp = 0
	Else
		healthPercentage = strengthPoints/requiredXPToLevelUp
		healthAmount = (10*healthPercentage) as int
		requiredXPToLevelUp = requiredXPToLevelUp - strengthPoints
	EndIf

	If (!levelComplete) && (fitnessPoints >= requiredXPToLevelUp)
		remainingAmount = (10 - healthAmount) as int
		staminaAmount = remainingAmount
		If staminaAmount < 0
			staminaAmount = 0
		EndIf
		
		player.ModActorValue("health", healthAmount)
		player.ModActorValue("stamina", staminaAmount)
		levelUp()

		strengthPoints = 0
		If (requiredXPToLevelUp > 0)
			float temp = requiredXPToLevelUp
			requiredXPToLevelUp = requiredXPToLevelUp - fitnessPoints
			fitnessPoints = (fitnessPoints - temp) as int
		EndIf

		levelComplete = true
		requiredXPToLevelUp = 0
	ElseIf levelComplete != true
		staminaPercentage = fitnessPoints/requiredXPToLevelUp
		staminaAmount = ((10 - healthAmount) * staminaPercentage) as int
		requiredXPToLevelUp = requiredXPToLevelUp - fitnessPoints
	EndIf

	If (!levelComplete) && (sportsPoints >= requiredXPToLevelUp)
		remainingAmount = 10 - healthAmount - staminaAmount
		magickaAmount =  remainingAmount
		If magickaAmount < 0
			magickaAmount = 0
		EndIf

		player.ModActorValue("health", healthAmount)
		player.ModActorValue("stamina", staminaAmount)
		player.ModActorValue("magicka", magickaAmount)
		levelUp()

		strengthPoints = 0
		fitnessPoints = 0

		If (requiredXPToLevelUp > 0)
			float temp = requiredXPToLevelUp
			requiredXPToLevelUp = requiredXPToLevelUp - sportsPoints
			sportsPoints = (sportsPoints - temp) as int
		EndIf

		levelComplete = true
		requiredXPToLevelUp = 0
	ElseIf levelComplete != true
		magickaPercentage = sportsPoints/requiredXPToLevelUp
		magickaAmount = ((10 - healthAmount - staminaAmount) * magickaPercentage) as int
		requiredXPToLevelUp = requiredXPToLevelUp - sportsPoints
	EndIf

	If levelComplete
		int newPlayerLevel = player.GetLevel()
		UpdateLevelModifiers(playerLevel, newPlayerLevel)
	EndIf

	;After a level up has been awarded, check whether the player has enough experience to level up again (and therefore be awarded Orbs of Experience)
	stackRemainingXP()

	If levelComplete != True
		Debug.MessageBox("No level up this time. Go harder in the gym next time! You still need " + ((Game.GetExperienceForLevel(player.GetLevel()) - Game.GetPlayerExperience()) as int) + " XP to level up.")
	Else
		Debug.MessageBox("Congratulations you've leveled up with " + healthAmount + " points into health, " + staminaAmount + " points into stamina and " + magickaAmount + " points into magicka!")
	EndIf

EndFunction


;Award the player Orbs of Experience if they still have enough experience to level up again after their first level up
Function stackRemainingXP()
	;This array stores arrays which indicate the distribution of attribute points to award for each Orb of Experience
	;The strings will be in the format of
	;		hX sY mZ 		where X, Y, Z are positive integers
	string[] stackedLevelDistributions = new string[4]
	int arrayPos = 0

	Actor player = Game.GetPlayer()
	int playerLevel = Game.GetPlayer().GetLevel()
	float currentPlayerXP = Game.GetPlayerExperience()
	float requiredXPToLevelUp = Game.GetExperienceForLevel(playerLevel) - currentPlayerXP
	
	;Duplicated the fields as we do not want threading to break the logic
	int strengthPointsCopy = strengthPoints
	int fitnessPointsCopy = fitnessPoints
	int sportsPointsCopy = sportsPoints

	;StackLevels is the number of pending levels the player will have. Increment this whenever the player has enough XP to earn another level up.
	int stackLevels = 0
	int remainingXP = strengthPointsCopy + fitnessPointsCopy + sportsPointsCopy

	int healthAmount = 0
	int staminaAmount = 0
	int magickaAmount = 0
	
	int count = 1
	bool levelComplete = False

	;As long as the total amount of experience that hasn't been "used" is greater than 0, go through and check if the player can get any Orbs of Experience.
	;There is also a check for how many times it has been looped through with count, and caps at 10 times through to prevent infinite loops.
	While (remainingXP > 0) && (count < 10)
		If (!levelComplete) && (strengthPointsCopy >= requiredXPToLevelUp)
			healthAmount = 10	
	
			string levelDist = "h"+ healthAmount + " s" + staminaAmount + " m" + magickaAmount
			stackedLevelDistributions[arrayPos] = levelDist
			arrayPos = arrayPos + 1

			healthAmount = 0
			stackLevels = stackLevels + 1

			remainingXP = remainingXP - requiredXPToLevelUp as int
			strengthPointsCopy = strengthPointsCopy - requiredXPToLevelUp as int
	
			requiredXPToLevelUp = 0
			levelComplete = True
		ElseIf levelComplete != true
			float healthPercentage = strengthPointsCopy/requiredXPToLevelUp
			healthAmount = (10*healthPercentage) as int

			requiredXPToLevelUp = requiredXPToLevelUp - strengthPointsCopy	
			remainingXP = remainingXP - strengthPointsCopy 
			
		EndIf

		If (!levelComplete) && (fitnessPointsCopy >= requiredXPToLevelUp)
			int remainingAmount = (10 - healthAmount) as int
			staminaAmount = remainingAmount

			string levelDist = "h"+ healthAmount + " s" + staminaAmount + " m" + magickaAmount
			stackedLevelDistributions[arrayPos] = levelDist
			arrayPos = arrayPos + 1

			healthAmount = 0
			staminaAmount = 0
			stackLevels = stackLevels + 1

			remainingXP = remainingXP - requiredXPToLevelUp as int
			fitnessPointsCopy = fitnessPointsCopy - requiredXPToLevelUp as int

			requiredXPToLevelUp = 0
			levelComplete = True

			strengthPointsCopy = 0
		ElseIf levelComplete != true
			float staminaPercentage = fitnessPointsCopy/requiredXPToLevelUp
			staminaAmount = (10*staminaPercentage) as int

			requiredXPToLevelUp = requiredXPToLevelUp - fitnessPointsCopy 
			remainingXP = remainingXP - fitnessPointsCopy

		EndIf

		If (!levelComplete) && (sportsPointsCopy >= requiredXPToLevelUp)
			int remainingAmount = 10 - healthAmount - staminaAmount
			magickaAmount =  remainingAmount

			string levelDist = "h"+ healthAmount + " s" + staminaAmount + " m" + magickaAmount
			stackedLevelDistributions[arrayPos] = levelDist
			arrayPos = arrayPos + 1

			healthAmount = 0
			staminaAmount = 0
			magickaAmount = 0
			stackLevels = stackLevels + 1

			remainingXP = remainingXP - requiredXPToLevelUp as int
			sportsPointsCopy = sportsPointsCopy - requiredXPToLevelUp as int

			levelComplete = True

			strengthPointsCopy = 0
			fitnessPointsCopy = 0
		ElseIf levelComplete != true
			float magickaPercentage = sportsPointsCopy/requiredXPToLevelUp
			magickaAmount = (10*magickaPercentage) as int
			
			requiredXPToLevelUp = requiredXPToLevelUp - sportsPointsCopy
			remainingXP = remainingXP - sportsPointsCopy
			
		EndIf
	
		requiredXPToLevelUp = Game.GetExperienceForLevel(playerLevel + count)
		count = count + 1
		levelComplete = False

	EndWhile

	;Add Orb(s) of Experience to the player's inventory. The number of orbs given is the number of stackLevels.
	player.AddItem(OrbOfExperience, stackLevels, false)
	
	;Write the attribute distributions to a file so that they can be read in after X amount of time (see quest script) when an Orb of Experience is consumed.
	writeDistsToFile(stackedLevelDistributions)
	
	;Map points variables we manipulated to the points fields
	strengthPoints = strengthPointsCopy
	fitnessPoints = fitnessPointsCopy
	sportsPoints = sportsPointsCopy
EndFunction


;Write attribute distributions to a file so that they may be read in when an Orb of Experience is used
Function writeDistsToFile(string[] levelDists)
	FISSInterface fiss = FISSFactory.getFISS()
	If !fiss
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return
	EndIf

	fiss.beginSave("StackedLevelDistributions.txt", "P4P")

	int arrayPos = 0
	While arrayPos < 5
		; Can clean up by only writing dists that have values in the array
		fiss.saveString("Level Distribution " + arrayPos, levelDists[arrayPos])
		arrayPos = arrayPos + 1
	EndWhile

	string end = fiss.endSave()
EndFunction


;Set the player's experience points to their progress bar
;If they have received any Orbs of Experience then the progress bar should show up as full, and if not it should 
;be the amount they have progressed towards the next level
Function UpdateExperienceProgressBar()
	Actor player = Game.GetPlayer()
	If (player.GetItemCount(OrbOfExperience) > 0)
		float requiredXPToLevelUp =  Game.GetExperienceForLevel(player.GetLevel())
		Game.SetPlayerExperience(requiredXPToLevelUp - 1)
	Else
		Game.SetPlayerExperience(strengthPoints + fitnessPoints + sportsPoints)
	EndIf

EndFunction  
