//
//  NSMutableArray+Queue.m
//  DVC-MobileClient-iOS
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (id)dequeue
{
    if (self.count == 0)
    {
        return nil;
    }
    else
    {
        id headObject = [self objectAtIndex:0];
        if (headObject != nil)
        {
            [self removeObjectAtIndex:0];
        }
        return headObject;
    }
}

- (void)enqueue:(id)newObject
{
    [self addObject:newObject];
}

@end
