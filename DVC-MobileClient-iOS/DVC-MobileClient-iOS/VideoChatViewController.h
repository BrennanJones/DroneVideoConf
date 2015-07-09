//
//  VideoChatViewController.h
//  DVC-MobileClient-iOS
//

#import <UIKit/UIKit.h>

@interface VideoChatViewController : UIViewController <UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UITextField* roomInput;
@property(weak, nonatomic) IBOutlet UITextView* instructionsView;
@property(weak, nonatomic) IBOutlet UITextView* logView;
@property(weak, nonatomic) IBOutlet UIView* blackView;
@property(weak, nonatomic) IBOutlet UITextField *idField;

- (IBAction)finishCall:(id)sender;

- (void)applicationWillResignActive:(UIApplication*)application;

@end
