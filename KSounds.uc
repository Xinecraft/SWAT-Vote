class KSounds extends Julia.Extension implements Julia.InterestedInPlayerConnected;

var config Sound PlayerConnectedPlaySound;
var config Sound VoteStartedSound;
var config Sound VotedYesSound;
var config Sound VotedNoSound;
var config Sound VoteEndWinSound;
var config Sound VoteEndFailSound;
var config Sound Vote30SecWarningSound;
var config Sound KillStreakSound;
var config Sound ArrestStreakSound;
/**********************************************************************************************//**
 * @fn	function BeginPlay()
 *
 * @brief	Begins a play.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @return	A function.
 **************************************************************************************************/

function BeginPlay()
{
	Super.BeginPlay();
	if(Level.NetMode != NM_DedicatedServer)
    {
		self.Destroy();
		return;
    }
	self.Core.RegisterInterestedInPlayerConnected(self);
}

/**********************************************************************************************//**
 * @fn	public function SendSound(Sound ASound, optional Julia.Player Player)
 *
 * @brief	Sends a sound.
 *
 * @author	Kinnngg
 * @date	07-02-2015
 *
 * @param	ASound	The sound.
 * @param	Player	The player.
 *
 * @return	A function.
 **************************************************************************************************/

public function SendSound(Sound ASound, optional Julia.Player Player)
{
    local int i;
// local int CurrentPlayers; 
	local array<Julia.Player> Players;
	local Julia.Player LocalPlayer;
// CurrentPlayers = self.Core.GetServer().GetPlayerCount(); 
	Players = self.Core.GetServer().GetPlayers();
	
	if(Player == none)
	{
		for(i = 0;i < Players.Length; i++)
		{
			LocalPlayer=Players[i];
			
			if(LocalPlayer == none)
			{
				continue;
			}
			if(LocalPlayer.GetPC() == none)
			{
				continue;
			}
			SwatGamePlayerController(LocalPlayer.GetPC()).ClientReliablePlaySound(ASound);
		}
	}
	else
	{
		if(Player == none)
        {
            return;
        }
		if(Player.GetPC() == none)
        {
            return;
        }
		
		SwatGamePlayerController(Player.GetPC()).ClientReliablePlaySound(ASound);
	}
	return;
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
	if(self.Core.GetServer().GetGameState() != GAMESTATE_MidGame)
	{
		return;
	}
	self.SendSound(PlayerConnectedPlaySound);
	return;
}


/** @brief	Event queue for all listeners interested in () events. */
event Destroyed()
{
	if(self.Core != None)
    {
	self.Core.UnRegisterInterestedInPlayerConnected(self);
    }
	Super.Destroyed();
}

defaultproperties
{
	Title="Kinnngg/KMod/Sounds";
	Version="1.0.0";
	PlayerConnectedPlaySound=Sound'SW_ambients.Thunder2';
	VotedYesSound=Sound'SW_ambients.Beep2';
	VotedNoSound=Sound'SW_ambients.Beep1';
	Vote30SecWarningSound=Sound'SW_weapons.C2charge_Beeping1';
	VoteEndWinSound=Sound'SW_hits.ExploBomb2';
	VoteEndFailSound=Sound'SW_hits.ExploBomb1';
	VoteStartedSound=Sound'SW_bounce.exp_extinguisher';
	KillStreakSound=Sound'SW_objects.ElevDing1';
	ArrestStreakSound=Sound'SW_objects.BombDisarmed1';
}