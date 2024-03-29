/* --------------------------------------------------------------------------------
 #
 #	4DPlugin-Control-QuickTime-Player.h
 #	source generated by 4D Plugin Wizard
 #	Project : Control QuickTime Player
 #	author : miyako
 #	2022/03/04
 #  
 # --------------------------------------------------------------------------------*/

#ifndef PLUGIN_CONTROL_QUICKTIME_PLAYER_H
#define PLUGIN_CONTROL_QUICKTIME_PLAYER_H

#include "4DPluginAPI.h"
#include "4DPlugin-Control-QuickTime-Player.h"
#include "4DPlugin-JSON.h"

#import <AppKit/AppKit.h>
#import <QuickTimePlayer.h>

#include <future>

typedef enum {
    
    request_permission_unknown = 0,
    request_permission_authorized = 1,
    request_permission_not_determined = 2,
    request_permission_denied = 3,
    request_permission_restricted = 4
    
}request_permission_t;

typedef enum {
    
    qtpc_new_movie_recording = 1,
    qtpc_new_audio_recording = 2,
    qtpc_new_screen_recording = 3,
    qtpc_play = 4,
    qtpc_start = 5,
    qtpc_pause = 9,
    qtpc_resume = 10,
    qtpc_stop = 11,
    qtpc_present = 12,
    qtpc_open = 13,
    qtpc_close = 14,
    qtpc_save = 15,
    qtpc_quit = 16
    
}quicktime_player_command_t;

#pragma mark -

static void QuickTime_Player_Execute(PA_PluginParameters params);

#endif /* PLUGIN_CONTROL_QUICKTIME_PLAYER_H */
