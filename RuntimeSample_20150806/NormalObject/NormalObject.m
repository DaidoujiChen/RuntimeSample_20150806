//
//  NormalObject.m
//  RuntimeSample_20150806
//
//  Created by 啟倫 陳 on 2015/8/1.
//  Copyright (c) 2015年 ChilunChen. All rights reserved.
//

#import "NormalObject.h"

@interface NormalObject ()

@property (nonatomic, strong) NSMutableArray *storage;

@end

@implementation NormalObject

#pragma mark - private class method

+ (NSInteger)randomIntegerValue {
    return [self randomPart1] + [self randomPart2];
}

+ (NSInteger)randomPart1 {
    return arc4random() % 5000;
}

+ (NSInteger)randomPart2 {
    return [self randomPart1];
}

#pragma mark - instance method

- (void)invoke {
    NSDate *startDate = [NSDate date];
    
    self.storage = [NSMutableArray array];
    for (NSInteger i = 0; i < 1000; i++) {
        for (NSInteger j = 0; j < 1000; j++) {
            [self.storage addObject:[NSNumber numberWithInteger:[NormalObject randomIntegerValue]]];
        }
    }
    self.storage = nil;
    
    NSLog(@"NormalObject Cost : %fs", -[startDate timeIntervalSinceNow]);
}

@end
