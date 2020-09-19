#include "main\Lib\Lib.sp"

public void 
OnMapStart()
{
    ServerCommand("sm plugins unload compiled/[UserId]hns.smx");
    ServerCommand("sm plugins unload compiled/[UserId]RankControl.smx");
    ServerCommand("sm plugins unload compiled/[UserId]JumpStats.smx");
    ServerCommand("sm plugins unload compiled/[UserId]DoubleDuck.smx");
    ServerCommand("sm plugins load compiled/[UserId]hns.smx");
    ServerCommand("sm plugins load compiled/[UserId]RankControl.smx");
    ServerCommand("sm plugins load compiled/[UserId]JumpStats.smx");
    ServerCommand("sm plugins load compiled/[UserId]DoubleDuck.smx");
    
}