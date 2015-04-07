//
// Credit for this code goes to Dave Gallagher on Stack Overflow
//  (http://stackoverflow.com/questions/1305225/best-way-to-serialize-a-nsdata-into-an-hexadeximal-string)
//

#import <Foundation/Foundation.h>

@interface NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString;

@end
