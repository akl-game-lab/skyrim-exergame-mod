Scriptname ewfewfwef extends ReferenceAlias  

import FISSFactory
import Game
import StringUtil
import MyPluginScript

potion property healthpotion auto	

Event OnActivate(ObjectReference ref)
	game.getplayer().additem(healthpotion)

EndEvent


