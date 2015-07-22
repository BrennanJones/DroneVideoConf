//
//  VideoChatViewController.h
//  DVC-MobileClient-iOS
//


#import <UIKit/UIKit.h>

#import "DeviceController.h"
#import "MainViewController.h"


@interface VideoChatViewController : UIViewController <UITextFieldDelegate, ServerConnectionDelegate>

@property(weak, nonatomic) IBOutlet UITextField* roomInput;
@property(weak, nonatomic) IBOutlet UITextView* instructionsView;
@property(weak, nonatomic) IBOutlet UITextView* logView;
@property(weak, nonatomic) IBOutlet UIView* blackView;
@property(weak, nonatomic) IBOutlet UITextField *idField;

- (IBAction)swapCameras:(id)sender;
- (IBAction)repositionViews:(id)sender;
- (IBAction)finishCall:(id)sender;

- (void)applicationWillResignActive:(UIApplication*)application;

@end
