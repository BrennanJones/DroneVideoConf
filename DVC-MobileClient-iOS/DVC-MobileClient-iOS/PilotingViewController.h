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
//  PilotingViewController.h
//  DVC-MobileClient-iOS
//


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>

#import "DroneVideoView.h"
#import "DVC-Swift.h"


@interface PilotingViewController : UIViewController <UITextFieldDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) ARService *service;

@property (nonatomic, strong) SocketIOClient *socket;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) IBOutlet UILabel *batteryLabel;
@property (nonatomic, strong) IBOutlet UIButton *takeoffBt;
@property (nonatomic, strong) IBOutlet UIButton *landingBt;
@property (strong, nonatomic) IBOutlet UITextField *serverConnectionTextField;
@property (strong, nonatomic) IBOutlet UIButton *serverConnectionButton;
@property (strong, nonatomic) IBOutlet UILabel *serverConnectionStatusLabel;
@property (strong, nonatomic) IBOutlet DroneVideoView *droneVideoView;

@property (weak, nonatomic) IBOutlet UILabel *latPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *lonPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *latDroneLabel;
@property (weak, nonatomic) IBOutlet UILabel *lonDroneLabel;
@property (strong, nonatomic) IBOutlet UILabel *bearingDroneLabel;
@property (weak, nonatomic) IBOutlet UILabel *requiredBearingDroneLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneYawDirectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneToPhoneDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneCurrentSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneXSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneYSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneZSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneDirectionOfVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *altDroneLabel;

- (IBAction)connectToServerClick:(id)sender;

- (IBAction)emergencyClick:(id)sender;
- (IBAction)takeoffClick:(id)sender;
- (IBAction)landingClick:(id)sender;

- (IBAction)gazUpTouchDown:(id)sender;
- (IBAction)gazDownTouchDown:(id)sender;

- (IBAction)gazUpTouchUp:(id)sender;
- (IBAction)gazDownTouchUp:(id)sender;

- (IBAction)yawLeftTouchDown:(id)sender;
- (IBAction)yawRightTouchDown:(id)sender;

- (IBAction)yawLeftTouchUp:(id)sender;
- (IBAction)yawRightTouchUp:(id)sender;

- (IBAction)rollLeftTouchDown:(id)sender;
- (IBAction)rollRightTouchDown:(id)sender;

- (IBAction)rollLeftTouchUp:(id)sender;
- (IBAction)rollRightTouchUp:(id)sender;

- (IBAction)pitchForwardTouchDown:(id)sender;
- (IBAction)pitchBackTouchDown:(id)sender;

- (IBAction)pitchForwardTouchUp:(id)sender;
- (IBAction)pitchBackTouchUp:(id)sender;

- (IBAction)camUpClick:(id)sender;
- (IBAction)camDownClick:(id)sender;
- (IBAction)camLeftClick:(id)sender;
- (IBAction)camRightClick:(id)sender;

- (IBAction)resetHomeClick:(id)sender;

- (IBAction)takePhotoClick:(id)sender;

@end
