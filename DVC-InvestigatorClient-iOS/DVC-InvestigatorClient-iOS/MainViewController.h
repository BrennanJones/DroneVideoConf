//
//  MainViewController.h
//  DVC-InvestigatorClient-iOS
//


#import <UIKit/UIKit.h>


@class MainViewController;

@protocol ServerConnectionDelegate <NSObject>
- (void)onConnectToServer:(NSString *)serverURL;
- (void)onDisconnectFromServer;
@end

@protocol ManualOverrideStateDelegate <NSObject>
- (void)onManualOverrideStateChanged:(BOOL)newState;
@end

@protocol DroneStateDelegate <NSObject>
- (void)onDroneConnectionUpdate:(BOOL)newState;
- (void)onDroneBatteryUpdate:(BOOL)newPercentage;
@end


@interface MainViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) id <ServerConnectionDelegate> serverConnectionDelegate;
@property (nonatomic, weak) id <ManualOverrideStateDelegate> manualOverrideStateDelegate;
@property (nonatomic, weak) id <DroneStateDelegate> droneStateDelegate;

@property (nonatomic, strong) IBOutlet UILabel *batteryLabel;
@property (nonatomic, strong) IBOutlet UIButton *takeoffBt;
@property (nonatomic, strong) IBOutlet UIButton *landingBt;
@property (strong, nonatomic) IBOutlet UIButton *emergencyBt;
@property (strong, nonatomic) IBOutlet UITextField *serverConnectionTextField;
@property (strong, nonatomic) IBOutlet UIButton *serverConnectionButton;
@property (strong, nonatomic) IBOutlet UILabel *serverConnectionStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *droneConnectionStatusLabel;

- (IBAction)connectToServerClick:(id)sender;

- (IBAction)emergencyClick:(id)sender;
- (IBAction)takeoffClick:(id)sender;
- (IBAction)landingClick:(id)sender;

- (IBAction)upClick:(id)sender;
- (IBAction)downClick:(id)sender;

@end
