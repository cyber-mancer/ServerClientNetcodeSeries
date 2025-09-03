class_name DebugConsole extends Node



# Set in _ready()
var runningHeadless:bool
var consoleInputThread:Thread

var quit:bool = false

static var playerStatesDict:Dictionary = {}

func _ready() -> void:
	# If running on server, don't bother doing any of the debug stuff.
	var runningOnServer:bool = OS.has_feature("dedicated_server")
	var headless:bool        = DisplayServer.get_name() == "headless"
	
	runningHeadless = runningOnServer or headless
	
	if runningHeadless:
		print(
			"Server: Running on server: ",
			runningOnServer,
			", headless: ",
			headless,
			"; disabling debug display."
		)
		%Head.queue_free()
		
		## These two lines are required to recieve input from the command line when
		## the server is run with --headless, or a dedicated server. The thread is told
		## to run getConsoleInput(), which continuously polls and handles the input from
		## the user.
		consoleInputThread = Thread.new()
		consoleInputThread.start(getConsoleInput)
	
	else:
		printr("Server: Not running on server/headless; enabling debug display.")



## Required to free the thread once the server is no longer on.
func _notification(type:int):
	if type == NOTIFICATION_WM_CLOSE_REQUEST:
		quit = true
		## TODO: FIX CONSTANT "NONEXISTENT FUNCTION WAIT TO FINISH IN BASE NIL"
		if consoleInputThread: await consoleInputThread.wait_to_finish()
		get_tree().quit()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta:float):
	
	if runningHeadless: return
	
	var fpsStr:String = getFpsStr(delta)
	
	var clientsInfo:String = getClientsDebugInfo()
	var stateInfo:String = getStateDebugInfo()
	
	var timeStr:String = "Current server clock: " + str(NetworkCore.serverClockMs)
	var tickStr:String = "Current server tick:  " + str(NetworkCore.serverTick)
	
	#var serverDataStr:String = str(ServerData.weaponData)
	
	var debugStr:String = "- Server Info -\n\n"
	debugStr += timeStr + "\n"
	debugStr += tickStr + "\n\n"
	debugStr += fpsStr + "\n"
	debugStr += clientsInfo + "\n"
	debugStr += stateInfo + "\n"
	#debugStr += "\n" + serverDataStr + "\n"
	
	%Info.text = debugStr
	
	if DebugCameraFly.mouseCaptured:
		%Head.modulate.a = 0.5
	else:
		%Head.modulate.a = 1.0



## Called in another thread; gets the console input whenever the user enters something
## NOTE: only called in headless mode.
func getConsoleInput() -> void:
	var inputArg:String = ""
	
	while inputArg != "quit":
		if quit: return
		
		OS.delay_msec(1000) # Sleep for 1000ms = 1s
		
		# NOTE: Max length of arg is 20 chars at the moment.
		inputArg = OS.read_string_from_stdin(20).strip_edges()
		if inputArg: handleCommand(inputArg)


func handleCommand(inCmd:String) -> void:
	if inCmd == "": return # There was no command
	if !runningHeadless: %InputEdit.text = "" # Clear the text input box
	
	# Get the command and arguments separately
	var cmd:String = inCmd.split(" ")[0]

	var args:PackedStringArray = inCmd.split(" ")
	args.remove_at(0)
	var isArgsProvided:bool = len(args) > 0 # It has args if there are 2+ segments.
	
	
	if cmd == "help" or cmd == "h":
		var fs:String = "    %-15s%s"
		printr("Commands:")
		printr(fs % ["help, h:", "displays this help information."])
		printr(fs % ["quit, exit:", "stops the server."])
		printr(fs % ["fps:", "displays current server tickrate."])
		printr(fs % ["list:", "lists currently connected clients."])
		printr(fs % ["state:", "displays current world state."])
		printr("")
		printr(fs % ["kick [int]:", "kicks a provided player index (use with list)."])
		printr(fs % ["maxplayers [int?]:", "sets/queries the number of players required to play."])
	
	
	elif cmd == "quit" or cmd == "exit":  get_tree().quit()
	elif cmd == "fps":                    printr(getFpsStr())
	elif cmd == "list":                   printr(getClientsDebugInfo())
	elif cmd == "state":                  printr(getStateDebugInfo())
	
	elif cmd == "kick":
		if not isArgsProvided: # If there were no args for kick
			printr("Expected client index to kick.")
			return
		
		# If there was an arg, then tell the server whom to disconnect
		if args[0].is_valid_int():
			# Kick one player if an index was provided
			NetworkServer.clientsToDisconnect.append(int(args[0]))
		elif args[0] == "*":
			# Kick all players if * was provided.
			for i in len(NetworkServer.connectedClients):
				NetworkServer.clientsToDisconnect.append(i)
		else: printr("Expected integer value for client ID.")
	
	elif cmd == "maxplayers":
		if not isArgsProvided: # If there were no args for kick
			printr("Max players: " + str(NetworkServer.maxPlayers))
			return
		else:
			if args[0].is_valid_int():
				NetworkServer.maxPlayers = int(args[0])
				printr("Max players updated to " + args[0] + ".")
			else:
				# TODO check to make sure it's 1-8
				printr("Expected integer value for max players (1-8).")

	else: printr("Unknown command \"" + cmd + "\"")


## Prints an array. Necessary because it determines whether to only print to the
## command line or also the GUI console.
func printa(stringArgs:Array):
	var resultString:String = ""
	
	for argument in stringArgs:
		resultString += str(argument)
	
	print(resultString) # First, print to the real console
	
	if runningHeadless: return
	
	# If NOT headless, then update the visual console.
	addLineToConsole(resultString)


## Prints a string. Necessary because it determines whether to only print to the
## command line or also the GUI console.
func printr(stringInput:String) -> void:
	print(stringInput) # First, print to the real console
	
	if runningHeadless: return
	
	# If NOT headless, then update the visual console.
	addLineToConsole(stringInput)


func addLineToConsole(line:String):
	%Console.text += line + "\n"
	%ScrollToBottomTimer.start() # Gotta wait a bit to scroll down, since it takes a bit to update
func scrollToBottom():
	if runningHeadless: return
	# Scroll to bottom, whenever a new line is printed.
	%ConsoleScroll.scroll_vertical = %ConsoleScroll.get_v_scroll_bar().max_value + 1000


####################################################################################################
#region DEBUG STRING BUILDERS ######################################################################


func getClientsDebugInfo() -> String:
	var connectedClientList:PackedInt32Array = NetworkServer.connectedClients
	var connectedClientCount:int = len(connectedClientList)
	
	var connectedClientsStr := str(connectedClientCount) + " Connected Clients:\n"
	connectedClientsStr += "    index  id\n"
	
	# Put the information about each client on its own line on the connect clients info
	for i in range(len(connectedClientList)):
		connectedClientsStr += "    " + str(i) + "   " + str(connectedClientList[i]) + "\n"
	
	return connectedClientsStr


func getStateDebugInfo() -> String:
	var stateStr:String = "  Player States: \n"
	
	var players:Dictionary = playerStatesDict.get("p", {})
	for i in players:
		stateStr += "    " + str(i) + ": " + str(players.get(i, {})) + "\n"
	
	return stateStr


## Will return the number of physics frames processed per second on the server.
## Live display works with delta calculation and is thus slightly more accurate.
func getFpsStr(delta:float=-1) -> String:
	if delta == -1:
		return "Server tickrate: " + str(Engine.get_frames_per_second()) + " ticks/sec\n"
	return "Server tickrate: " + str(snappedf(1.0/delta, 0.1)) + " ticks/sec\n"


#endregion DEBUG STRING BUILDERS ###################################################################
####################################################################################################
