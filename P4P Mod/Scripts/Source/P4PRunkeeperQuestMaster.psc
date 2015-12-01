Scriptname P4PRunkeeperQuestMaster extends ObjectReference  

import Game

Event OnDeath(Actor akKiller)
	;If player has levelled up, notify onscreen
	Actor player = Game.GetPlayer()
	
	If (akKiller == player)
		float currentXP = Game.GetPlayerExperience()
		Game.SetPlayerExperience(currentXP + 2000)

		Debug.MessageBox("You have slain Exer of Cise. You sir are a tough nuts and have received 2000 XP.")
	EndIf

EndEvent