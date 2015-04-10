/*
    Copyright (C) 2014 Parrot SA

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the 
      distribution.
    * Neither the name of Parrot nor the names
      of its contributors may be used to endorse or promote products
      derived from this software without specific prior written
      permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.
*/
//
//  PilotingViewController.m
//  BebopDronePiloting
//
//  Created on 19/01/2015.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#import "PilotingViewController.h"
#import "DeviceController.h"
#import "SocketIOPacket.h"
#import "NSData+Conversion.h"

#define TAG "PilotingViewController"

static const int SERVER_PORT_NUMBER = 12345;

//static const int NUM_FRAMES_PER_PACKAGE = 4;

int frameCount = 0;
//bool sendingFrame = false;
//uint8_t *framePackage[NUM_FRAMES_PER_PACKAGE];
//int numFramesPackaged = 0;

@interface PilotingViewController () <DeviceControllerDelegate>
@property (nonatomic, strong) DeviceController* deviceController;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation PilotingViewController

@synthesize service = _service;
@synthesize batteryLabel = _batteryLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad ...");
    
    [_batteryLabel setText:@"?%"];
    
    _alertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Connecting ..."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    
    //[_droneVideoView setupVideoView:self];
    [_droneVideoView setupVideoView];
    
    [self initializeSocketIO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_alertView show];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _deviceController = [[DeviceController alloc]initWithARService:_service];
        [_deviceController setDelegate:self];
        BOOL connectError = [_deviceController start];
        
        NSLog(@"connectError = %d", connectError);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_alertView dismissWithClickedButtonIndex:0 animated:TRUE];
            
        });
        
        if (connectError)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
    });
}

- (void) viewDidDisappear:(BOOL)animated
{
    _alertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Disconnecting ..."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [_alertView show];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self disconnectFromServer];
        [_deviceController stop];
        [_alertView dismissWithClickedButtonIndex:0 animated:TRUE];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark events

- (IBAction)connectToServerClick:(id)sender
{
    if (self.socketIO.isConnected)
    {
        self.serverConnectionButton.enabled = false;
        self.serverConnectionStatusLabel.text = @"Disconnecting from server...";
        
        [self disconnectFromServer];
    }
    else
    {
        self.serverConnectionTextField.enabled = false;
        self.serverConnectionButton.enabled = false;
        self.serverConnectionStatusLabel.text = @"Connecting to server...";
        
        [self connectToServer:self.serverConnectionTextField.text onPort:SERVER_PORT_NUMBER];
    }
}

- (IBAction)emergencyClick:(id)sender
{
    [_deviceController sendEmergency];
}

- (IBAction)takeoffClick:(id)sender
{
    [_deviceController sendTakeoff];
}

- (IBAction)landingClick:(id)sender
{
    [_deviceController sendLanding];
}

//events for gaz:
- (IBAction)gazUpTouchDown:(id)sender
{
    [_deviceController setGaz:50];
}
- (IBAction)gazDownTouchDown:(id)sender
{
    [_deviceController setGaz:-50];
}

- (IBAction)gazUpTouchUp:(id)sender
{
    [_deviceController setGaz:0];
}
- (IBAction)gazDownTouchUp:(id)sender
{
    [_deviceController setGaz:0];
}

//events for yaw:
- (IBAction)yawLeftTouchDown:(id)sender
{
    [_deviceController setYaw:-50];
    
}
- (IBAction)yawRightTouchDown:(id)sender
{
    [_deviceController setYaw:50];
    
}

- (IBAction)yawLeftTouchUp:(id)sender
{
    [_deviceController setYaw:0];
}

- (IBAction)yawRightTouchUp:(id)sender
{
    [_deviceController setYaw:0];
}

//events for yaw:
- (IBAction)rollLeftTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setRoll:-50];
}
- (IBAction)rollRightTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setRoll:50];
}

- (IBAction)rollLeftTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setRoll:0];
}
- (IBAction)rollRightTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setRoll:0];
}

//events for pitch:
- (IBAction)pitchForwardTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setPitch:50];
}
- (IBAction)pitchBackTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setPitch:-50];
}

- (IBAction)pitchForwardTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setPitch:0];
}
- (IBAction)pitchBackTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setPitch:0];
}

- (IBAction)endCommandClick:(id)sender
{
    [self.socketIO sendEvent:@"EndCommand" withData:nil];
    [_endCommandButton setAlpha:0.0];
    _commandLabel.text = @"";
}

#pragma mark DeviceControllerDelegate

- (void)onDisconnectNetwork:(DeviceController *)deviceController
{
    NSLog(@"onDisconnect ...");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)initializeSocketIO
{
    if (self.socketIO == nil)
    {
        self.socketIO = [[SocketIO alloc]initWithDelegate:self];
    }
}

- (BOOL)connectToServer:(NSString *)address onPort:(NSInteger)port
{
    [self disconnectFromServer];
    
    [self.socketIO connectToHost:address onPort:port];
    
    if (self.socketIO.isConnected)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)disconnectFromServer
{
    if (self.socketIO.isConnected)
    {
        [self.socketIO disconnect];
    }
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    _alertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Connection with server failed."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [_alertView show];
    
    self.serverConnectionStatusLabel.text = @"Disconnected from server.";
    [self.serverConnectionButton setTitle:@"Connect to server" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
    self.serverConnectionTextField.enabled = true;
}


- (void) socketIODidConnect:(SocketIO *)socket
{
    [self.socketIO sendEvent:@"MobileClientConnect" withData:nil];
    
    self.serverConnectionStatusLabel.text = @"Connected to server.";
    [self.serverConnectionButton setTitle:@"Disconnect from server" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
    
    [self.serverConnectionTextField setAlpha:0];
}


- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    self.serverConnectionStatusLabel.text = @"Disconnected from server.";
    [self.serverConnectionButton setTitle:@"Connect to server" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
    self.serverConnectionTextField.enabled = true;
    [self.serverConnectionTextField setAlpha:1];
}


- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveEvent(): %@", packet.name);
    
    NSArray* args = packet.args;
    NSDictionary* arg = args[0];
    
    if([packet.name isEqualToString:@"Command"])
    {
        [self displayCommand:(NSString *)arg[@"command"]];
        
        [_endCommandButton setAlpha:1.0];
        
        if (self.socketIO.isConnected)
        {
            NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
            [json setObject:(NSString *)arg[@"command"] forKey:@"command"];
            [self.socketIO sendEvent:@"CommandAcknowledged" withData:json];
        }
    }
}

- (void) displayCommand:(NSString *)command
{
    _incomingCommandLabel.text = command;
    _incomingCommandLabel.alpha = 1.0;
    _commandLabel.text = command;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:5.0];
    _incomingCommandLabel.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)onUpdateBattery:(DeviceController *)deviceController batteryLevel:(uint8_t)percent;
{
    NSLog(@"onUpdateBattery");
    
    // update battery label on the UI thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = [[NSString alloc] initWithFormat:@"%d%%", percent];
        [_batteryLabel setText:text];
    });
}

-(void)onFlyingStateChanged:(DeviceController *)deviceController flyingState:(eARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE)state
{
    NSLog(@"onFlyingStateChanged");
    
    // on the UI thread, disable and enable buttons according to flying state
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (state) {
            case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_LANDED:
                [_takeoffBt setEnabled:YES];
                [_landingBt setEnabled:NO];
                break;
            case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_HOVERING:
            case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_FLYING:
                [_takeoffBt setEnabled:NO];
                [_landingBt setEnabled:YES];
                break;
            default:
                // in all other cases, take of and landing are not enabled
                [_takeoffBt setEnabled:NO];
                [_landingBt setEnabled:NO];
                break;
        }
    });
}

- (void)onPositionChanged:(DeviceController *)deviceController latitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;
{
    NSLog(@"onUpdatePosition");
    
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *latText = [[NSString alloc] initWithFormat:@"%f", latitude];
        NSString *longText = [[NSString alloc] initWithFormat:@"%f", longitude];
        NSString *altText = [[NSString alloc] initWithFormat:@"%f", altitude];
        
        [_latitudeLabel setText:latText];
        [_longitudeLabel setText:longText];
        [_altitudeLabel setText:altText];
    });
     */
}

- (void)onFrameComplete:(DeviceController *)deviceController frame:(uint8_t *)frame frameSize:(uint32_t)frameSize;
{
    NSLog(@"onFrameComplete: %d", ++frameCount);
    
    if (self.socketIO.isConnected)
    {
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:frameSize/sizeof(uint8_t)];
        for (int i = 0; i < frameSize/sizeof(uint8_t); i++)
        {
            [array addObject: [NSString stringWithFormat: @"%d", frame[i]]];
        }
        
        NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
        [json setObject:array forKey:@"videoData"];
        [self.socketIO sendEvent:@"DroneVideoFrame" withData:json];
    }
     
    /*
    uint8_t *copiedFrame = malloc(frameSize);
    for (int i = 0; i < frameSize/sizeof(uint8_t); i++)
    {
        copiedFrame[i] = frame[i];
    }
    */
    
    [_droneVideoView updateVideoViewWithFrame:frame frameSize:frameSize];
    
    /*
    if (sendingFrame)
    {
        //free(copiedFrame);
    }
    else if (self.socketIO.isConnected)
    {
        if (_droneVideoView.currentBufferPixels != NULL && !_droneVideoView.currentBufferLocked)
        {
            sendingFrame = true;
            
            _droneVideoView.currentBufferLocked = true;
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *pixelArray = [[NSMutableArray alloc] initWithCapacity:_droneVideoView.currentBufferSize];
                for (int i = 0; i < _droneVideoView.currentBufferSize/sizeof(uint8_t); i++)
                {
                    [pixelArray addObject: [NSString stringWithFormat: @"%d", _droneVideoView.currentBufferPixels[i]]];
                }
                
                if (self.socketIO.isConnected)
                {
                    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
                    [json setObject:[NSNumber numberWithInt:_droneVideoView.currentBufferWidth] forKey:@"width"];
                    [json setObject:[NSNumber numberWithInt:_droneVideoView.currentBufferHeight] forKey:@"height"];
                    [json setObject:pixelArray forKey:@"pixels"];
                    [self.socketIO sendEvent:@"DroneVideoFrame" withData:json];
                }
                
                sendingFrame = false;
                
                _droneVideoView.currentBufferLocked = false;
            });
        }
        
        // ---------------
        
        framePackage[numFramesPackaged++] = copiedFrame;
        if (numFramesPackaged == NUM_FRAMES_PER_PACKAGE)
        {
            sendingFrame = true;
            
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *outerArray = [[NSMutableArray alloc] initWithCapacity:NUM_FRAMES_PER_PACKAGE];
                
                for (int c = 0; c < NUM_FRAMES_PER_PACKAGE; c++)
                {
                    NSMutableArray *innerArray = [[NSMutableArray alloc] initWithCapacity:frameSize/sizeof(uint8_t)];
                    for (int i = 0; i < frameSize/sizeof(uint8_t); i++)
                    {
                        [innerArray addObject: [NSString stringWithFormat: @"%d", framePackage[c][i]]];
                    }
                    
                    [outerArray addObject:innerArray];
                }
                
                if (self.socketIO.isConnected)
                {
                    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
                    [json setObject:outerArray forKey:@"videoData"];
                    [self.socketIO sendEvent:@"DroneVideoFrame" withData:json];
                }
                
                for (int c = 0; c < NUM_FRAMES_PER_PACKAGE; c++)
                {
                    free(framePackage[c]);
                }
                
                numFramesPackaged = 0;
                
                sendingFrame = false;
            });
        }
    }
    */
}

@end
