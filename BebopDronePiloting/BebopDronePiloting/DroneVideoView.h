//
//  DroneVideoView.h
//  BebopDronePiloting
//
//  Created by Brennan Jones on 2015-04-02.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "PilotingViewController.h"

@import AVFoundation;

@interface DroneVideoView : UIView

@property (nonatomic, retain) AVSampleBufferDisplayLayer *videoLayer;

//@property (nonatomic, assign) uint8_t *currentBufferPixels;
//@property (nonatomic, assign) size_t currentBufferWidth;
//@property (nonatomic, assign) size_t currentBufferHeight;
//@property (nonatomic, assign) size_t currentBufferSize;
//@property (nonatomic, assign) BOOL currentBufferLocked;

-(void) setupVideoView;
-(void) updateVideoViewWithFrame:(uint8_t *)frame frameSize:(uint32_t)frameSize;

@end
