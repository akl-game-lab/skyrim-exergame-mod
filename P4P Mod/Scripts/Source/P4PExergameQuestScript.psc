Scriptname P4PExergameQuestScript extends Quest  

import FISSFactory
import Game

Potion Property LevelUpPotion Auto

Function givePlayerFreePotion(String typeOfPotion)
	Actor player = game.getPlayer()
	String levelDist = "" 
	
	if (typeOfPotion == "health")
		levelDist = "h10 s00 m00"
	elseif(typeOfPotion == "stamina")
		levelDist = "h00 s10 m00"
	else
		levelDist = "h00 s00 m10"
	endIf
	
	;write the level distribution to file
	FISSInterface fread = FISSFactory.getFISS()
	If !fread 
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return None
	EndIf
	
	fread.beginSave("StackedLevelDistributions.txt", "P4P")
	fread.saveString("Level Distributions", levelDist)
	string end = fread.endSave()

	;add a potion to the player's inventory
	player.AddItem(LevelUpPotion, 1)
	
	
EndFunction