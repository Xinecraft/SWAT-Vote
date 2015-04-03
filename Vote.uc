class Vote extends Julia.Extension implements Julia.InterestedInCommandDispatched,Julia.InterestedInEventBroadcast,Julia.InterestedInPlayerDisconnected,Julia.InterestedInPlayerLoaded;

// Julia.InterestedInPlayerConnected

/**********************************************************************************************//**
 * @property	var KSounds KSounds
 *
 * @brief	Gets the sounds.
 *
 * @return	The k sounds.
 **************************************************************************************************/

var KSounds KSounds;

/**********************************************************************************************//**
 * @property	var config bool CanVoteAgainstAdmin
 *
 * @brief	Gets a value indicating whether we can vote against admin.
 *
 * @return	true if we can vote against admin, false if not.
 **************************************************************************************************/

var config bool CanVoteAgainstAdmin;

/** @brief	The delta secs. */
const DELTA = 0.5;

/**********************************************************************************************//**
 * @struct	sVoteDetails
 *
 * @brief	A vote details.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 **************************************************************************************************/

struct sVoteDetails
{
// Vote Starter
var Julia.Player Starter;

// Sufferrer
var Julia.Player Startee;


/**********************************************************************************************//**
 * @property	var int VoteType
 *
 * @brief	Gets the type of the vote.
 * 			0-None
 * 			1-Kick
 * 			2-ask
 * 			3-Map
 *
 * @return	The type of the vote.
 **************************************************************************************************/

var int VoteType;

// Is vote already started
var bool bVoteStarted;

//Vote Count Total
var int VoteCountTotal;

//Vote Yes Count
var int VoteYesCount;

//Vote No Count
var int VoteNoCount;

// Vote Start TimeStamp Level.TimeSecond
var int VoteStartTime;

//List of Player who has Voted till Now
var array<Julia.Player>Voters;

//Is 30 Sec Warning Displayed?
var bool bDisplayedVoteWarn;

//A Asked String Container
var string VoteAskedString;

// Vote Map ID
var int MapID;

//Vote Success Time for Map to delay change map to 10 secs
var int VoteMapSuccessTime;

};

//Previous Vote Started Time
var int PreVoteTime;

// Local String to Hold Map Name for Temp
var string MapName;


// Is Vote Map Enabled
var config bool bVoteMapEnabled;

// Is Only Admins Allowed to Vote?
var config bool OnlyAdminCanStartVote;

var sVoteDetails VoteDetails;

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
			return;
        }
    }
	self.Destroy();
}

/**********************************************************************************************//**
 * @fn	public function BeginPlay()
 *
 * @brief	Execute when begins The play.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	A function.
 **************************************************************************************************/

public function BeginPlay()
{

    Super.BeginPlay();
	self.SetTimer(class'Vote'.const.DELTA, true);
	if(KSounds==none)
	{
		KSounds = Spawn(class'KSounds');
	}
    log("Kinnngg's Vote Mod [KMod.Vote] has been initialized");
    self.Core.RegisterInterestedInPlayerDisconnected(self);
    self.Core.RegisterInterestedInEventBroadcast(self);
	self.Core.RegisterInterestedInPlayerLoaded(self);
    self.RegisterCommands();
}

public function OnPlayerLoaded(Player Player)
{
	class'Utils.LevelUtils'.static.TellPlayer(self.Level,"[b]SWAT4 Voting Mod by Kinnngg[\\b]",Player.GetPC(),"FFFF00");
}

/**********************************************************************************************//**
 * @fn	function RegisterCommands()
 *
 * @brief	Registers the commands.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	A function.
 **************************************************************************************************/

function RegisterCommands()
{
	self.Core.GetDispatcher().Bind("vote", self,self.Locale.Translate("VoteCommandUsage"), self.Locale.Translate("VoteCommandDescription"));
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

	/**
	 * For Vote Question All Arguments Should be combined to a Question
	**/
	local string ArgsCombinedForQuestion;
	
	if(Name=="vote")
	{
		/** 
		 * If only Admins allowed to start vote
		**/
		if(OnlyAdminCanStartVote)
		{
			if(!Player.IsAdmin())
			{
				return;
			}
		}

		/**
		 * Wait for 60 sec before starting new
		 */
		if((self.Level.TimeSeconds - self.PreVoteTime) <= 61)
		{
			Dispatcher.Respond(Id,"[c=FFFFFF]Can't Start a Vote Now. Try Again After 60 Seconds.[\\b]");
			return;
		}
	
	/**
	 * Condition for - Vote has been started to kick a player
	 */
	if(Args[0]~="kick")
	{
			if(Args[1]=="")
			{
				Dispatcher.Respond(Id, "[c=FF0000]Plz Provide A Name To Kick[\\b]");
				return;
			}
			if(self.VoteDetails.bVoteStarted)
			{
				Dispatcher.Respond(Id,self.Locale.Translate("VoteAlreadyStartedMessage"));
				return;
			}

			/** @AllOKforVote	All condition OK now VOTE can be started from here. */

			/** @brief	Setting the VoteDetails structure starter to the Player who is starting the vote.
			 *          Now all Structure variables will be set accordingly
			 *          */
			self.VoteDetails.Starter=Player;

			/** @brief	Match the Arg[1] i.e, Provided kickee name with Playername in Server. . */

			self.VoteDetails.Startee = self.Core.GetServer().GetPlayerByWildName(Args[1]);

			if(VoteDetails.Startee == None)
			{
				Dispatcher.Respond(Id,self.Locale.Translate("VoteCantFindPlayerMessage"));
				return;
			}
			if(!CanVoteAgainstAdmin)
			{
				if(VoteDetails.Startee.IsAdmin())
				{
					Dispatcher.Respond(Id,self.Locale.Translate("VoteCantAgainstAdminMsg"));
					return;
				}
			}
			Dispatcher.Respond(Id,"[c=FFFF00]Vote has been Started![\\c].");
			StartVote('kick',self.VoteDetails.Starter,self.VoteDetails.Startee);
			KSounds.SendSound(KSounds.VoteStartedSound);
			return;

			/**********************************************************************************************//**
			 * @fn	HandleVote(Player,"yes");
			 *
			 * @brief	The starter already voted Yes if this function is not commented.
			 *
			 * @author	Kinnngg
			 * @date	07-02-2015
			 *
			 * @param	parameter1	Julia Player
			 * @param	parameter2	yes or no
			 **************************************************************************************************/

//			HandleVote(Player,"yes");
	}
		
		/**
		 * @brief  If Vote Type is Ask a Question
		 */
		else if(Args[0]~="ask")
		{
			ArgsCombinedForQuestion = class'Utils.ArrayUtils'.static.Join(Args, " ");
			ArgsCombinedForQuestion = Right(ArgsCombinedForQuestion,Len(ArgsCombinedForQuestion)-4);
			if(Args[1]=="")
			{
				Dispatcher.Respond(Id, "[c=FF0000]Plz Provide A Question To Ask[\\b]");
				return;
			}
			if(self.VoteDetails.bVoteStarted)
			{
				Dispatcher.Respond(Id,self.Locale.Translate("VoteAlreadyStartedMessage"));
				return;
			}
			/**
			 * Vote Starter Player. 
			 */
			self.VoteDetails.Starter=Player;

			/**
			 * Match the Arg[1] ie Provided a Ask Question
			 */
			self.VoteDetails.VoteAskedString=ArgsCombinedForQuestion;
			
			Dispatcher.Respond(Id,"[c=FFFF00]Vote has been Started![\\c].");
			StartVote('ask',self.VoteDetails.Starter);
			KSounds.SendSound(KSounds.VoteStartedSound);
			
		}
	
		/**
		 * Handle if Vote has been started to change the Map
		 */
		else if(Args[0]~="map")
		{
			if(!bVoteMapEnabled)
			{
				return;
			}
			if(Args[1]=="")
			{
				Dispatcher.Respond(Id, "[c=FF0000]Please Provide a Map ID[\\b]");
				return;
			}
			if(!(Args[1] == "1" || Args[1] == "2" || Args[1] == "3" || Args[1] == "4" || Args[1] == "5"))
			{
				Dispatcher.Respond(Id, "[c=FF0000]Please Provide a Valid Map Id[\\b]");
				return;
			}
			if(self.VoteDetails.bVoteStarted)
			{
				Dispatcher.Respond(Id,self.Locale.Translate("VoteAlreadyStartedMessage"));
				return;
			}
			/**
			 * Vote Starter Player
			 */
			self.VoteDetails.Starter=Player;

			/**
			 * Match the Arg[1] ie Provided a Ask Question
			 */
			self.VoteDetails.MapID=int(Args[1]);

			/**
			 * Decrease Map ID by one becoz Julia start Map ID from 0
			 */
			--self.VoteDetails.MapID;
			self.MapName=class'Julia.Utils'.static.GetFriendlyMapName(GetMapNameFromID(self.VoteDetails.MapID));
			
			/**
			 * If ID not found
			 */
			if(self.MapName=="")
			{
				Dispatcher.Respond(Id, "[c=FF0000]Can't find map. Please try other Map ID[\\b]");
				return;
			}
			/**
			 * Exit if the Map ID provided by user is already in progress
			 */
			if(self.MapName == Level.Title)
			{
				Dispatcher.Respond(Id, "[c=FF0000]The provided map already running.[\\b]");
				return;
			}

			/**********************************************************************************************//**
			 * 
			 * @brief	Vote Started Now Set all things accordingly.
			 *
			 * @author	Kinnngg
			 * @date	07-02-2015
			 * 			
			 **************************************************************************************************/

			Dispatcher.Respond(Id,"[c=FFFF00]Vote has been Started![\\c].");
			StartVote('map',self.VoteDetails.Starter);
			KSounds.SendSound(KSounds.VoteStartedSound);

		}

		else
		{
			Dispatcher.Respond(Id,self.Locale.Translate("VoteNoArgsErrorMessage"));
		}
	}
}

/**********************************************************************************************//**
 * @fn	public function StartVote(name Type,Julia.Player Starter,optional Julia.Player Startee)
 *
 * @brief	Starts a vote.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Type   	Type of Vote Started.Kick,map,ask
 * @param	Starter	Julia Player Object of Starter
 * @param	Startee	If started against player as kick.
 *
 * @return	Void
 **************************************************************************************************/

public function StartVote(name Type,Julia.Player Starter,optional Julia.Player Startee)
{
	local int i;

	if(Type=='kick')
	{
		for(i=0;i<self.VoteDetails.Voters.Length;i++)
		{
			self.VoteDetails.Voters[i]=None;
		}
		self.VoteDetails.bVoteStarted=true;
		self.VoteDetails.VoteType=1;
		self.VoteDetails.VoteCountTotal=0;
		self.VoteDetails.VoteYesCount=0;
		self.VoteDetails.VoteNoCount=0;
		self.VoteDetails.VoteStartTime=self.Level.TimeSeconds;
		self.PreVoteTime=self.Level.TimeSeconds;
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteStartKickMessage",Starter.GetName(),Startee.GetName()),self.Locale.Translate("VoteMessageColor"));
		return;
	}
	else if(Type=='ask')
	{
		for(i=0;i<self.VoteDetails.Voters.Length;i++)
		{
			self.VoteDetails.Voters[i]=None;
		}
		self.VoteDetails.VoteType=2;
		self.VoteDetails.bVoteStarted=true;
		self.VoteDetails.VoteCountTotal=0;
		self.VoteDetails.VoteYesCount=0;
		self.VoteDetails.VoteNoCount=0;
		self.VoteDetails.VoteStartTime=self.Level.TimeSeconds;
		self.PreVoteTime=self.Level.TimeSeconds;
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteStartAskMessage",Starter.GetName(),self.VoteDetails.VoteAskedString),self.Locale.Translate("VoteMessageColor"));
		return;
	}
	
	else if(Type=='map')
	{
		for(i=0;i<self.VoteDetails.Voters.Length;i++)
		{
			self.VoteDetails.Voters[i]=None;
		}
		self.VoteDetails.VoteType=3;
		self.VoteDetails.bVoteStarted=true;
		self.VoteDetails.VoteCountTotal=0;
		self.VoteDetails.VoteYesCount=0;
		self.VoteDetails.VoteNoCount=0;
		self.VoteDetails.VoteStartTime=self.Level.TimeSeconds;
		self.PreVoteTime=self.Level.TimeSeconds;
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteStartMapMessage",Starter.GetName(),self.MapName),self.Locale.Translate("VoteMessageColor"));
		return;
	}
}

/**********************************************************************************************//**
 * @fn	public function OnPlayerDisconnected(Julia.Player Player)
 *
 * @brief	Executes the player disconnected action.Discard kick votes etc
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Player	Julia.Player Object
 *
 * @return	Void
 **************************************************************************************************/

public function OnPlayerDisconnected(Julia.Player Player)
{
	// Check if Vote has Started!
	if(!self.VoteDetails.bVoteStarted)
	{
		return;
	}

	// If not a Vote for kick
	if(self.VoteDetails.VoteType==2 || self.VoteDetails.VoteType==3)
	{
		return;
	}

	//Check if Player that Disconnected is the Startee
	if(self.VoteDetails.Startee == Player)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteAbortPlayerDisconnectMsg"), self.Locale.Translate("VoteMessageWarningColor"));
		KSounds.SendSound(KSounds.VoteEndFailSound);
		self.ResetVoteStats();
		return;
	}
}

/**********************************************************************************************//**
 * @fn	public function bool OnEventBroadcast(Julia.Player Player, Actor Sender, name Type, string Msg, optional PlayerController Receiver, optional bool bHidden)
 *
 * @brief	Executes the event broadcast action when yes or no vote plays
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Player  	The player.
 * @param	Sender  	The sender.
 * @param	Type		The type.
 * @param	Msg			The message.
 * @param	Receiver	The receiver.
 * @param	bHidden 	true to hide, false to show.
 *
 * @return	true if it succeeds, false if it fails.
 **************************************************************************************************/

public function bool OnEventBroadcast(Julia.Player Player, Actor Sender, name Type, string Msg, optional PlayerController Receiver, optional bool bHidden)
{
	if(!self.VoteDetails.bVoteStarted)
	{
		return true;
	}
	if(Type=='Say')
	{
		if(Msg~="yes")
		{
			HandleVote(Player,"yes");
			return false;
		}
		else if(Msg~="no")
		{
			HandleVote(Player,"no");
			return false;
		}
	    return true;
	}
    return true;
}

/**********************************************************************************************//**
 * @fn	public function HandleVote(Julia.Player Voter,string Type)
 *
 * @brief	Handles the vote.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Voter	The voter.
 * @param	Type 	The type.
 *
 * @return	Void
 **************************************************************************************************/

public function HandleVote(Julia.Player Voter,string Type)
{
			local Julia.Server Server;
			local int CurrentPlayers,MinVoteToWin;
			Server = self.Core.GetServer();
			CurrentPlayers = Server.GetPlayerCount();
			if(CurrentPlayers == 1)
			{
			MinVoteToWin=1;
			}
			else if(CurrentPlayers == 2)
			{
			MinVoteToWin=2;
			}
			else if(CurrentPlayers == 3)
			{
			MinVoteToWin = 2;
			}
			else if(CurrentPlayers > 3)
			{
			MinVoteToWin = ( CurrentPlayers / 2 ) + 1;
			}
			
	if(Type=="yes")
	{
		// Check if Player Already Voted
		if(CheckIfVoted(Voter))
		{
            class'Utils.LevelUtils'.static.TellPlayer(self.Level,"[b]You have already Voted![\\b]",Voter.GetPC(),"FFFFFF");
			return;
		}
		self.VoteDetails.Voters[self.VoteDetails.VoteCountTotal]=Voter;
		self.VoteDetails.VoteCountTotal++;
		self.VoteDetails.VoteYesCount++;
//      class'Utils.LevelUtils'.static.TellPlayer(self.Level,"[b]You Voted Yes![\\b]",Voter.GetPC(),"FF00FF");     // For Debug
		if(self.VoteDetails.VoteType==1 || self.VoteDetails.VoteType==3)
		{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteYesMessage",Voter.GetName(),( MinVoteToWin - VoteDetails.VoteYesCount )), self.Locale.Translate("VoteMessageColor"));
		}
		else if(self.VoteDetails.VoteType==2)
		{
			class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteYesAskMessage",Voter.GetName(),self.VoteDetails.VoteYesCount), self.Locale.Translate("VoteMessageColor"));
		}
		KSounds.SendSound(KSounds.VotedYesSound);
	}
	else if(Type=="no")
	{
		if(CheckIfVoted(Voter))
		{
            class'Utils.LevelUtils'.static.TellPlayer(self.Level,"[b]You have already Voted![\\b]",Voter.GetPC(),"FFFFFF");
			return;
		}
		self.VoteDetails.Voters[self.VoteDetails.VoteCountTotal]=Voter;
		self.VoteDetails.VoteCountTotal++;
		self.VoteDetails.VoteNoCount++;
//		class'Utils.LevelUtils'.static.TellPlayer(self.Level,"[b]You Voted No![\\b]",Voter.GetPC(),"FF00FF");     // For Debug
		if(self.VoteDetails.VoteType==1 || self.VoteDetails.VoteType==3)
		{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteNoMessage",Voter.GetName()), self.Locale.Translate("VoteMessageColor"));
		}
		else if(self.VoteDetails.VoteType==2)
		{
			class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteNoAskMessage",Voter.GetName(),self.VoteDetails.VoteNoCount), self.Locale.Translate("VoteMessageColor"));
		}
		KSounds.SendSound(KSounds.VotedNoSound);
	}
	GetVoteAction();
}


/**********************************************************************************************//**
 * @fn	public function bool CheckIfVoted(Julia.Player Player)
 *
 * @brief	Determine if player voted.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Player	The player.
 *
 * @return	true if it succeeds(voted), false if it fails(not voted).
 **************************************************************************************************/

public function bool CheckIfVoted(Julia.Player Player)
{
	local int i;
	for(i = 0;i < self.VoteDetails.Voters.Length;i++)
	{
		if(self.VoteDetails.Voters[i]==Player)
		{
			return true;
		}
	}
	return false;
}

/**********************************************************************************************//**
 * @fn	public function GetVoteAction()
 *
 * @brief	Gets vote action.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	The vote action.
 **************************************************************************************************/

public function GetVoteAction()
{	
		local Julia.Server Server;
		local int CurrentPlayers,MinVoteToWin;
			Server = self.Core.GetServer();
			CurrentPlayers = Server.GetPlayerCount();
			if(CurrentPlayers == 1)
			{
			MinVoteToWin=1;
			}
			else if(CurrentPlayers == 2)
			{
			MinVoteToWin=2;
			}
			else if(CurrentPlayers == 3)
			{
			MinVoteToWin = 2;
			}
			else if(CurrentPlayers > 3)
			{
			MinVoteToWin = ( CurrentPlayers / 2 ) + 1;
			}

	/** Take this action if Vote type id KICK
	 */
	if(self.VoteDetails.VoteType==1)
	{
		/**
		 * Success
		 */
		if(self.VoteDetails.VoteYesCount >= MinVoteToWin)
		{

			class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteSuccessMessage",self.VoteDetails.Startee.GetName()), self.Locale.Translate("VoteMessageColor"));
			KSounds.SendSound(KSounds.VoteEndWinSound);
			self.IssueAdminCommand("kick",self.VoteDetails.Startee);
			self.ResetVoteStats();
			return;
		}

		/**
		 * Failure
		 */
		else if(self.VoteDetails.VoteNoCount >= MinVoteToWin)
		{
			class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteUnSuccessMessage",self.VoteDetails.Startee.GetName()), self.Locale.Translate("VoteMessageColor"));
			KSounds.SendSound(KSounds.VoteEndFailSound);
			self.ResetVoteStats();
			return;
		}
	}
	
	/**
	 * Take this Action of Vote Type is Map Change
	 */
	if(self.VoteDetails.VoteType==3)
	{
		/**
		 * SUCCESS
		 */
		if(self.VoteDetails.VoteYesCount >= MinVoteToWin)
		{
			
			class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteMapSuccessMessage",self.MapName), self.Locale.Translate("VoteMessageColor"));
			KSounds.SendSound(KSounds.VoteEndWinSound);
			self.VoteDetails.VoteMapSuccessTime=self.Level.TimeSeconds;
			return;
		}
		/**
		 * FAILURE
		 */
		else if(self.VoteDetails.VoteNoCount >= MinVoteToWin)
		{
			class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteMapUnSuccessMessage",self.MapName), self.Locale.Translate("VoteMessageColor"));
			KSounds.SendSound(KSounds.VoteEndFailSound);
			self.ResetVoteStats();
			return;
		}
	}
}

/**********************************************************************************************//**
 * @brief	Event queue for all listeners interested in () events.
 *
 * ### summary	@brief	Event queue for all listeners interested in () events.
 **************************************************************************************************/

event Timer()
{
  // If Vote System Has Started!
  if(!self.VoteDetails.bVoteStarted)
  {
	return;
  }
  if(self.VoteDetails.VoteMapSuccessTime > 0 && self.VoteDetails.VoteType==3)
  {
	if((self.Level.TimeSeconds - self.VoteDetails.VoteMapSuccessTime) >= 5 && (self.Level.TimeSeconds - self.VoteDetails.VoteMapSuccessTime) < 6 )
	{
		self.IssueAdminCommand("setmap "$self.VoteDetails.MapID, none, self.Locale.Translate("VoteSuccessMapMessage",self.MapName));
		self.ResetVoteStats();
		self.IssueAdminCommand("restart", none);
	}
	return;
  }
  
  if((self.Level.TimeSeconds - self.VoteDetails.VoteStartTime) >= 30 && (self.Level.TimeSeconds - self.VoteDetails.VoteStartTime) < 31 )
  {
	if(!self.VoteDetails.bDisplayedVoteWarn)
	{
	
	self.VoteDetails.bDisplayedVoteWarn=True;
	if(self.VoteDetails.VoteType==1)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("Vote30SecWarningKickMsg",self.VoteDetails.Startee.GetName()), self.Locale.Translate("VoteMessageWarningColor"));
	}
	else if(self.VoteDetails.VoteType==2)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("Vote30SecWarningAskMsg",self.VoteDetails.VoteAskedString), self.Locale.Translate("VoteMessageWarningColor"));
	}
	else if(self.VoteDetails.VoteType==3)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("Vote30SecWarningMapMsg",self.MapName), self.Locale.Translate("VoteMessageWarningColor"));
	}
	
	KSounds.SendSound(KSounds.Vote30SecWarningSound);
	return;
	}
  }
  
  else if((self.Level.TimeSeconds - self.VoteDetails.VoteStartTime) >= 60 && (self.Level.TimeSeconds - self.VoteDetails.VoteStartTime) < 61 )
  {
    //Tell all Vote unsuccess by time and Destroy the Vote to Let start New
	if(self.VoteDetails.VoteType==1)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteTimeOutMessage",self.VoteDetails.Startee.GetName()), self.Locale.Translate("VoteMessageWarningColor"));
		KSounds.SendSound(KSounds.VoteEndFailSound);
		self.ResetVoteStats();
		return;
	}
	if(self.VoteDetails.VoteType==2)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteTimeOutAskMessage",self.VoteDetails.VoteAskedString,self.VoteDetails.VoteYesCount,self.VoteDetails.VoteNoCount), self.Locale.Translate("VoteMessageWarningColor"));
		KSounds.SendSound(KSounds.VoteEndFailSound);
		self.ResetVoteStats();
		return;
	}
	if(self.VoteDetails.VoteType==3)
	{
		class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteTimeOutMapMessage",self.Level.Title), self.Locale.Translate("VoteMessageWarningColor"));
		KSounds.SendSound(KSounds.VoteEndFailSound);
		self.ResetVoteStats();
		return;
	}
  }
  
// Check if Player got to Admin After Vote Started and If then Do Required Action
  if(self.VoteDetails.Startee.IsAdmin())
  {
	if(CanVoteAgainstAdmin)
	{
		return;
	}
	
	class'Utils.LevelUtils'.static.TellAll(self.Level,self.Locale.Translate("VoteAboutAdminLoginMsg",self.VoteDetails.Startee.GetName()), self.Locale.Translate("VoteMessageWarningColor"));
	KSounds.SendSound(KSounds.VoteEndFailSound);
	self.ResetVoteStats();
	return;
  }
}

/**********************************************************************************************//**
 * @fn	protected function IssueAdminCommand(string AdminCommand, optional Julia.Player Player, optional string ActionMessage)
 *
 * @brief	Issue an arbitrary AdminMod command. If Player argument is provided, append its AM
 * 			player id to the command.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	AdminCommand 	AdminCommand Arbitrary admin command.
 * @param	Player		 	Player Optional target.
 * @param	ActionMessage	ActionMessage An optional message to display upon the action being
 * 							taken.
 *
 * @return	void.
 **************************************************************************************************/

protected function IssueAdminCommand(string AdminCommand, optional Julia.Player Player, optional string ActionMessage)
{
    if (ActionMessage != "")
    {
        if (Player != None)
        {
            ActionMessage = class'Utils.StringUtils'.static.Format(ActionMessage, Player.GetLastName());
        }
        class'Utils.LevelUtils'.static.TellAdmins(self.Level, ActionMessage, Player.GetPC());
    }

    // Append the player's id
    if (Player != None)
    {
        AdminCommand = AdminCommand $ " " $ self.GetPlayerAMId(Player);
    }

    if (!class'Julia.Utils'.static.AdminModCommand(self.Level, AdminCommand, self.Locale.Translate("ServerAdminNameString"), ""))
    {
        // Show a warning upon a failure
        if (Player != None)
        {
            class'Utils.LevelUtils'.static.TellAdmins(
                self.Level,
                self.Locale.Translate("AdminActionFailure", AdminCommand, Player.GetLastName()),
                Player.GetPC()
            );
        }
    }
}

/**********************************************************************************************//**
 * @fn	protected function int GetPlayerAMId(Julia.Player Player)
 *
 * @brief	Return the player's AdminMod player id.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	Player	Player.
 *
 * @return	int.
 **************************************************************************************************/

protected function int GetPlayerAMId(Julia.Player Player)
{
    local SwatGame.SwatMutator SM;

    foreach DynamicActors(class'SwatGame.SwatMutator', SM)
    {
        if (SM.IsA('AMPlayerController'))
        {
            if (AMMod.AMPlayerController(SM).PC == Player.GetPC())
            {
                return AMMod.AMPlayerController(SM).id;
            }
        }
    }
    return -1;
}

//Reset the Vote Stats
protected function ResetVoteStats()
{
	local int i;
		for(i=0;i<self.VoteDetails.Voters.Length;i++)
		{
			self.VoteDetails.Voters[i]=None;
		}
		self.VoteDetails.Startee=None;
		self.VoteDetails.Starter=None;
		self.VoteDetails.bVoteStarted=false;
		self.VoteDetails.VoteType=0;
		self.VoteDetails.bDisplayedVoteWarn=false;
		self.VoteDetails.VoteCountTotal=0;
		self.VoteDetails.VoteYesCount=0;
		self.VoteDetails.VoteNoCount=0;
		self.VoteDetails.VoteStartTime=0;
		self.VoteDetails.MapID=0;
		self.VoteDetails.VoteMapSuccessTime=0;
		self.MapName="";
}



/**********************************************************************************************//**
 * @fn	function string GetMapNameFromID(int ID)
 *
 * @brief	Gets map name from identifier. Get the list of Available Maps in Array. 
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	ID	The identifier.
 *
 * @return	The map name from identifier.
 **************************************************************************************************/

function string GetMapNameFromID(int ID)
{
	local string Map;
	local int i;

	for ( i = 0 ; i < ServerSettings(Level.PendingServerSettings).NumMaps; i++ )
	{
	if(i==ID)
		Map = ServerSettings(Level.PendingServerSettings).Maps[i];
	}
	return Map;
}


/** @brief	Event queue for all listeners interested in () events. */
event Destroyed()
{

	if(self.Core != None)
    {
    self.Core.GetDispatcher().UnbindAll(self);
	self.Core.UnRegisterInterestedInEventBroadcast(self);
	self.Core.UnRegisterInterestedInPlayerDisconnected(self);
	self.Core.UnRegisterInterestedInPlayerLoaded(self);
    }
    Super.Destroyed();
}

defaultproperties
{
    Title="Kinnngg/KMod/VoteMod";
    Version="1.0.0";
    LocaleClass=class'Locale';
	CanVoteAgainstAdmin=True;
	bVoteMapEnabled=True;
	OnlyAdminCanStartVote=False;
}