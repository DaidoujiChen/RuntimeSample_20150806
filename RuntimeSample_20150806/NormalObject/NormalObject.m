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
    NSLog(@"NormalObject Cost : %fs", -[startDate timeIntervalSinceNow]);
}

#pragma mark - life cycle

- (id)init {
    self = [super init];
    if (self) {
        self.storage = [NSMutableArray arrayWithObjects:@"1", @"2", nil];
    }
    return self;
}

@end
