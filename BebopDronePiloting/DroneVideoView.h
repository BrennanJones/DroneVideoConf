//
//  DroneVideoView.h
//  BebopDronePiloting
//
//  Created by Brennan Jones on 2015-04-02.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AVFoundation;

@interface DroneVideoView : UIView

@property (nonatomic, retain) AVSampleBufferDisplayLayer *videoLayer;

-(void) setupVideoView;

@end
