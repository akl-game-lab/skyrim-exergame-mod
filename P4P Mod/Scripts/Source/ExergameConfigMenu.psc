Scriptname ExergameConfigMenu extends ski_configbase  

import myPluginScript;
import FISSFactory;

;###################################################
;MCM MENU CONFIGURATION
;###################################################
;option IDs
int exergamingOID;
int syncOID;
int syncStatusOID;
int inputTestOID;

;option values
bool exergamingBool = false
string syncedUserName = ""
int syncedSaveID = 0
;Defines the number of pages in the MCM
event OnConfigInit()
	Pages = new string[1]
	Pages[0] = "Settings"
endEvent


;This event decides what the page looks like
event OnPageReset(string page)

	;DEFAULT IMAGE
	if (page == "")
		LoadCustomContent("testImage.swf")
		return


	;SETTINGS PAGE
	elseif (page == "Settings")
		UnloadCustomContent()
		;initial options setup
		SetCursorFillMode(TOP_TO_BOTTOM) 
		SetCursorPosition(0)
		AddHeaderOption("Exergaming Mode")
		if (exergamingBool)
			exergamingOID = AddToggleOption("Turn off Exergaming Mode", exergamingBool)
		else
			exergamingOID = AddToggleOption("Turn On Exergaming Mode", exergamingBool)
		endIf

		;if exergaming mode is on, then show the rest of the options
		if (exergamingBool)
			;if the exergaming mode is on, show the rest of the options
			if (syncedUserName == "")
				syncStatusOID = AddTextOption("Currently synced with: ", "Not Synced")
			else
				syncStatusOID = AddTextOption("Currently synced with: ", syncedUserName)
			endIf
			SyncOID = AddInputOption("Click here to sync...", "")
		EndIf
	endIf
endEvent


;This determines what will happen when an option is selected.
event OnOptionSelect(int option)
	if (option == exergamingOID)
		;if the option is off then turn it on and refresh the page
		if (exergamingBool == false)
			exergamingBool = !exergamingBool
			SetToggleOptionValue(exergamingOID, exergamingBool)
			ForcePageReset()
		else
			;otherwise the option is turned on so have to check if there is a currently synced account
			if (syncedUserName != "")
				;if there is a currently synced account, then show the confirmation to unsync the account
				;need to change this message prompt to use the implementation for a yes no message from the mcm github
				bool chosenOption = ShowMessage("This will unsync the current account from this save file. \nAre you sure you want to turn off exergaming mode?", true, "$Yes", "$No")
				if (!chosenOption)
					Debug.messagebox("pressed no")
					return
				else 
					Debug.messagebox("pressed yes")
					
					SetTextOptionValue(SyncStatusOID, "Not Synced")
					FISSInterface fiss = FISSFactory.getFISS()
					If !fiss
						debug.MessageBox("Fiss is not installed, Please install Fiss before using this mod.")
						return
					endif
					exergamingBool = !exergamingBool
					fiss.beginLoad("SaveManager.txt")
					int saveID = fiss.loadInt("saveID")
					syncedUserName = ""
					syncedSaveID = 0
					Debug.messageBox("the saveID is: " + saveID)
					fiss.endLoad()
					fiss.beginSave("SaveManager.txt", "P4P")
					fiss.saveBool("accountCurrentlySynced", false)
					fiss.saveInt("saveID", saveID)
					fiss.endSave()
					game.requestsave()
					ForcePageReset()
				endIf
			else
				;there is no synced account so can just turn off the exergaming mode
				exergamingBool = !exergamingBool
				SetToggleOptionValue(exergamingOID, exergamingBool)
				ForcePageReset()
			endIf
		endIf
	endIf
endEvent


;this executes when the input menu first pops up
Event OnOptionInputOpen( int option)
	if (option == SyncOID )	
		SetInputDialogStartText("Please enter your username...")
	endIf
EndEvent


;This executes when the user input window is closed
Event OnOptionInputAccept(int option, string userInput)
	
	if (option == SyncOID)
		string userName = userInput

		;this will be executed when the sync button is pressed
		FISSInterface fiss = FISSFactory.getFISS()
		
		If !fiss
			debug.MessageBox("Fiss is not installed, Please install Fiss before using this mod.")
			return
		endif
		
		;checking if the file exists
		fiss.beginLoad("SaveManager.txt")
		string readInSuccess = fiss.endLoad()

		;If readInSuccess != "" it implies that the file has not been found
		If readInSuccess != ""
			;if the textfile does not exist, then make a file with boolean to true, and integer to 1. and set the name of sync.
			fiss.beginSave("SaveManager.txt", "P4P")
			fiss.saveBool("AccountCurrentlySynced", true)
			fiss.saveInt("saveID", 1)
			fiss.endSave()
			syncedUserName = userName
			syncedSaveID = 1

			;also need to make an clean exercise data file with necessary tags.
			;get time stamp from c++ function
			fiss.beginSave(syncedUserName + syncedSaveID + "_Exercise_Data.txt", "P4P")
			;fiss.saveString("first_import_date", C++ time)
			fiss.saveint("first_week_points", 0)
			;fiss.saveString("last_update_date", c++ time)
			fiss.saveBool("first_week_completed", false)
			fiss.saveInt("outstanding_strength_points", 0)
			fiss.saveInt("outstanding_fitness_points", 0)
			fiss.saveInt("outstanding_sports_points", 0)
			fiss.endSave()

			SetTextOptionValue(SyncStatusOID, userName)
			game.requestsave()
			Debug.messageBox("Sync with " + userName + " Complete!")
			
		Else
			;otherwise there is already a file so we need to read it and check the state of the account sync
			fiss.beginLoad("SaveManager.txt")
			if (fiss.loadBool("AccountCurrentlySynced"))
				;this means that there is already an account that is connected so we need to tell the user to unsync the other account before connecting this one.
				Debug.messageBox("There is a save file already synced with this account. Please disconnect the other save file before syncing.")
				fiss.endLoad()
				return
			else
				;this means that there is no account currently synced, so all we need to do is increment the integer and set the boolean to true.
				int updatedSaveID = fiss.loadInt("saveID") + 1
				fiss.endLoad()
				fiss.beginSave("SaveManager.txt", "P4P")
				fiss.saveInt("saveID", updatedSaveID)
				fiss.savebool("AccountCurrentlySynced", true)
				fiss.endSave()
				syncedUserName = userName
				syncedSaveID = updatedSaveID
				SetTextOptionValue(SyncStatusOID, userName)
				game.requestsave()
				Debug.messageBox("Sync with " + userName + " Complete!")				
			endIf
		EndIf
	endIf
endEvent

;This event determines the default value for each of the 
event OnOptionDefault(int option)
	;removed this default option at the moment as it doesn't make logivcal sense
	; if (option == exergamingOID)
	; 	exergamingBool = false;
	; 	SetToggleOptionValue(exergamingOID, exergamingBool)
	; 	ForcePageReset()
	; endIf
endEvent

;This is the text that is showed at the bottom of the MCM menu.
event OnOptionHighlight(int option)
	if (option == exergamingOID)
		SetInfoText("Turns off in-game experience and allows you to gain experience from logged workouts.\nDefault: false")
	endIf
endEvent

;##################################################
;NORMAL QUEST EVENTS
;##################################################

Event OnPlayerLoadGame()

	;when the player loads in, need to grab the previous exercisedata if there is a synced account
	if (syncedUserName != "")
		FISSInterface fiss = FISSFactory.getFISS()
		If !fiss
			debug.MessageBox("Fiss is not installed, Please install Fiss before using this mod.")
			return
		endif
	
		fiss.beginLoad( syncedUserName + syncedSaveID + "_Exercise_Data.txt")
		string readInSuccess = fiss.endLoad()
	endif
endEvent