class Extension extends Julia.Extension implements Julia.InterestedInCommandDispatched,Julia.InterestedInPlayerConnected,HTTP.ClientOwner;


/**********************************************************************************************//**
 * @enum	eClientError
 *
 * @brief	Values that represent client errors.
 **************************************************************************************************/

import enum eClientError from HTTP.Client;

/**********************************************************************************************//**
 * @property	var protected HTTP.Client Client
 *
 * @brief	HTTP client instance
 * 			@type class'HTTP.Client'.
 *
 * @return	The client.
 **************************************************************************************************/

var protected HTTP.Client Client;

/**********************************************************************************************//**
 * @property	var config string URL
 *
 * @brief	Whois service URL
 * 			@type string.
 *
 * @return	The URL.
 **************************************************************************************************/

var config string URL;

/**********************************************************************************************//**
 * @property	var config string Key
 *
 * @brief	Server credentials
 * 			@type string.
 *
 * @return	The key.
 **************************************************************************************************/

var config string Key;

/**********************************************************************************************//**
 * @property	var config bool Auto
 *
 * @brief	Indicate whether a whois query should be automatically sent upon a player connection
 * 			@type bool.
 *
 * @return	true if automatic, false if not.
 **************************************************************************************************/

var config bool Auto;

/**********************************************************************************************//**
 * @fn	public function PreBeginPlay()
 *
 * @brief	Pre begin play.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	void.
 **************************************************************************************************/

public function PreBeginPlay()
{
	Super.PreBeginPlay();

    if (Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer)
    {
        if (Level.Game != None && SwatGameInfo(Level.Game) != None)
        {
            if (self.URL != "" || self.Key != "")
            {
                return;
            }
        }
    }
	self.Destroy();
}

/**********************************************************************************************//**
 * @fn	public function BeginPlay()
 *
 * @brief	Begins a play.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	A function.
 **************************************************************************************************/

public function BeginPlay()
{
	
    Super.BeginPlay();
	log("Kinnngg's Mod (KMod) has been initialized");
	self.Core.RegisterInterestedInPlayerConnected(self);
    self.Client = Spawn(class'HTTP.Client');
    self.RegisterCommands();
}



/**********************************************************************************************//**
 * @fn	protected function RegisterCommands()
 *
 * @brief	Registers the commands.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	A function(void).
 **************************************************************************************************/

protected function RegisterCommands()
{
    self.Core.GetDispatcher().Bind("time", self, "!time", "Displays the Current Server Time.");
    self.Core.GetDispatcher().Bind("date", self, "!date", "Displays the Current Server date.");
	self.Core.GetDispatcher().Bind("whois", self, "!whois name", "Display player Detail for Respected Playername");
}

/**********************************************************************************************//**
 * @fn	public function OnCommandDispatched(Julia.Dispatcher Dispatcher, string Name, string Id, array<string> Args, Julia.Player Player)
 *
 * @brief	Executes the command dispatched action.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Dispatcher	The dispatcher.
 * @param	Name	  	The name.
 * @param	Id		  	The identifier.
 * @param	Args	  	The arguments.
 * @param	Player	  	The player.
 *
 * @return	A function.
 **************************************************************************************************/

public function OnCommandDispatched(Julia.Dispatcher Dispatcher, string Name, string Id, array<string> Args, Julia.Player Player)
{
   local Julia.Player MatchedPlayer;
   local string ArgsCombined;
   local string TimeFormatted, DateFormatted, Response;

    // A command handler is always passed the lowercase version of a registered command
    switch (Name)
    {
        case "time":

             // Display HH:MM time (eg. 19:47)
            TimeFormatted = class'Utils.LevelUtils'.static.FormatTime(
              class'Utils.LevelUtils'.static.GetTime(self.Level),
              "%H:%M"
            );
            Response = "Current server time is " $ TimeFormatted;
			Dispatcher.Respond(Id, Response);
            break;

        case "date":

            DateFormatted = class'Utils.LevelUtils'.static.FormatTime(
              class'Utils.LevelUtils'.static.GetTime(self.Level),
              "%Y:%m:%d"
            );
            Response = "Current server date is " $ DateFormatted;
			Dispatcher.Respond(Id, Response);
            break;
		
    }
	
	if(Name=="whois")
	{
		ArgsCombined = class'Utils.ArrayUtils'.static.Join(Args, " ");
		MatchedPlayer = self.Core.GetServer().GetPlayerByWildName(ArgsCombined);
		// whois commands require an argument
		if (Len(ArgsCombined) == 0)
		{
			Dispatcher.ThrowUsageError(Id);
			return;
		}
		// If No Players Matched with Server Name
		if (MatchedPlayer == None)
        {
			if(Len(ArgsCombined) < 1)
			{
				Dispatcher.ThrowError(Id, self.Locale.Translate("WhoisCommandLessCharsError"));
				return;
			}
			log("Getting Player Whois From Database for."$MatchedPlayer.GetName());
			self.SendWhoisRequest (ArgsCombined$"$$0.0.0.0$$yes$$"$self.Key);
			
		}
		else
		{
			// Found a Player with name playing in server
			log("Getting Player From Database.with IP");
			self.SendWhoisRequest(MatchedPlayer.GetName() $ "$$" $ MatchedPlayer.GetIPAddr()$"$$no$$"$self.Key);
			
		}
		
		Dispatcher.Respond(Id, "---------------------");
	}
}

/**********************************************************************************************//**
 * @fn	public function OnPlayerConnected(Julia.Player Player)
 *
 * @brief	Executes the player connected action.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Player	The player.
 *
 * @return	A function.
 **************************************************************************************************/

public function OnPlayerConnected(Julia.Player Player)
{
    // Only perform a whois lookup if Auto is turned on(true)
    if (!self.Auto)                                 //  || self.Core.GetServer().GetGameState() != GAMESTATE_MidGame
    {
        return;
    }
	self.SendWhoisRequest(Player.GetName() $ "$$" $ Player.GetIPAddr()$"$$justjoined$$"$self.Key);
}

/**********************************************************************************************//**
 * @fn	public function OnRequestSuccess(int StatusCode, string Response, string Hostname, int Port)
 *
 * @brief	Parse a successful HTTP request in order to respond to a dispatched player command
 * 			(whois)
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	StatusCode	The status code.
 * @param	Response  	The response.
 * @param	Hostname  	The hostname.
 * @param	Port	  	The port.
 *
 * @return	A function.
 *
 * @see	HTTP.ClientOwner.OnRequestSuccess
 **************************************************************************************************/

public function OnRequestSuccess(int StatusCode, string Response, string Hostname, int Port)
{
	local array<string> Lines;
    local string Message;
	local int i;
	
	Lines = class'Utils.StringUtils'.static.Part(Response, "\n");
	
	Message = Left(class'Utils.ArrayUtils'.static.Join(Lines, "\n"), 1000); // 512 - dont let chat overflow
    if (StatusCode == 200)
    {
		// Printing line by line to avoid overflow
		for(i=1;i<Lines.Length;i++)
		{
			class'Utils.LevelUtils'.static.TellAll(self.Level, Lines[i] , "FFFFFF");
		}
		return;
    }
    log(self $ " Received invalid response from " $ Hostname $ " (" $ StatusCode $ ":" $ Left(Response, 20) $ ")");
}

/**********************************************************************************************//**
 * @fn	public function OnRequestFailure(eClientError ErrorCode, string ErrorMessage, string Hostname, int Port)
 *
 * @brief	Executes the request failure action.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	ErrorCode   	The error code.
 * @param	ErrorMessage	Message describing the error.
 * @param	Hostname		The hostname.
 * @param	Port			The port.
 *
 * @return	A function.
 *
 * @see	HTTP.ClientOwner.OnRequestFailure
 **************************************************************************************************/

public function OnRequestFailure(eClientError ErrorCode, string ErrorMessage, string Hostname, int Port)
{
    log(self $ " failed a request(HTTP/whois) to " $ Hostname $ " (" $ ErrorMessage $ ")");
}

/**********************************************************************************************//**
 * @fn	protected function SendWhoisRequest(string Args)
 *
 * @brief	Assemble a whois request and send it over.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Args	Command.
 *
 * @return	void.
 *
 * ### param	string	Args.
 * ### param	string	Id.
 **************************************************************************************************/

protected function SendWhoisRequest(string Args)
{
    local HTTP.Message Message;

    Message = Spawn(class'Message');

//  Message.AddQueryString('key', self.Key);
    Message.AddQueryString('data', Args);
//	Message.AddQueryString('type', ID);
	log("Send a HTTP Request to " $ self.URL );
    self.Client.Send(Message, self.URL, 'GET', self, 1);  // 1 attempt
}


/** @brief	Event queue for all listeners interested in () events. */
event Destroyed()
{
	if(self.Client != None)
    {
      self.Client.Destroy();
    }
	
	if(self.Core != None)
    {
        self.Core.GetDispatcher().UnbindAll(self);
        self.Core.UnregisterInterestedInPlayerConnected(self);
    }
	
    Super.Destroyed();
}


defaultproperties
{
    Title="Kinnngg/KMod/Whois";
    Version="1.0.0";
    LocaleClass=class'Locale';
}