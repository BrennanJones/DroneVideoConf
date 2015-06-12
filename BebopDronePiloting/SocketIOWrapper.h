//
//  SocketIOWrapper.h
//  BebopDronePiloting
//
//  Created by Brennan Jones on 2015-06-12.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DVC-Swift.h"

@interface SocketIOWrapper : NSObject

+ (void)emit:(SocketIOClient * __nonnull)socket withEvent:(NSString * __nonnull)event withItems:(NSArray * __nonnull)items;

@end
