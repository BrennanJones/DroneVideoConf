//
//  MainViewController.h
//  DVC-InvestigatorClient-iOS
//


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <libARDiscovery/ARDISCOVERY_BonjourDiscovery.h>


@class MainViewController;

@protocol ServerConnectionDelegate <NSObject>
- (void)onConnectToServer:(NSString *)serverURL;
- (void)onDisconnectFromServer;
@end


@interface MainViewController : UIViewController <UITextFieldDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) id <ServerConnectionDelegate> serverConnectionDelegate;

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

@end
