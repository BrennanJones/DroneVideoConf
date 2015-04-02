//
//  DroneVideoView.m
//  BebopDronePiloting
//
//  Created by Brennan Jones on 2015-04-02.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#import "DroneVideoView.h"

@implementation DroneVideoView

-(void) setupVideoView
{
    self.videoLayer = [[AVSampleBufferDisplayLayer alloc] init];
    self.videoLayer.bounds = self.bounds;
    self.videoLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.videoLayer.backgroundColor = [[UIColor greenColor] CGColor];
    
    //set Timebase
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock( CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase );
    
    self.videoLayer.controlTimebase = controlTimebase;
    CMTimebaseSetTime(self.videoLayer.controlTimebase, CMTimeMake(5, 1));
    CMTimebaseSetRate(self.videoLayer.controlTimebase, 1.0);
    
    // connecting the videolayer with the view
    
    [[self layer] addSublayer:_videoLayer];
}

-(void) updateVideoViewWithTrack:(AVAssetTrack *)track outputSettings:(NSDictionary *)outputSettings
{
    __block AVAssetReaderTrackOutput *outVideo = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:outputSettings];
    
    if( [assetReaderVideo startReading] )
    {
        [_videoLayer requestMediaDataWhenReadyOnQueue: assetQueue usingBlock: ^{
            while( [_videoLayer isReadyForMoreMediaData] )
            {
                CMSampleBufferRef *sampleVideo = [outVideo copyNextSampleBuffer];
                
                [_videoLayer enqueueSampleBuffer:sampleVideo.data];
            }
        }];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
