Scriptname PlayerCurrentLevelScript extends Quest  

Int Property RealPlayerLevel = 0 Auto  
Potion Property LevelUpPotion  Auto  

Event OnPlayerLoadGame()
	if (RealPlayerLevel == 0)
		Actor player = Game.getPlayer()
		int playerLevel = player.getLevel()
		int potionCount = player.getItemCount(LevelUpPotion)
		RealPlayerLevel = playerLevel + potionCount
	EndIf
endEvent

