Scriptname testscript12 extends TopicInfo  

import ObjectReference
import StringUtil
import FISSFactory


Function testFunction()
FISSInterface fwrite = FISSFactory.getFISS()
	If !fwrite
		Debug.MessageBox("Fiss is not installed. Mod will not work correctly")
		return
	EndIf

	fwrite.beginSave("fissTest.txt", "P4P")
	fwrite.saveString("teststring1", "11115")
	fwrite.saveString("teststring2", "22221")
	string end = fwrite.endSave()
EndFunction
