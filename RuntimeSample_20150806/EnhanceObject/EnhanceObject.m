//
//  EnhanceObject.m
//  RuntimeSample_20150806
//
//  Created by 啟倫 陳 on 2015/8/1.
//  Copyright (c) 2015年 ChilunChen. All rights reserved.
//

#import "EnhanceObject.h"
#import <objc/runtime.h>

@interface EnhanceObject ()

@property (nonatomic, strong) NSMutableArray *storage;

@end

@implementation EnhanceObject

#pragma mark - function

NSInteger randomIntegerValue() {
    return randomPart1() + randomPart2();
}

NSInteger randomPart1() {
    return arc4random() % 5000;
}

NSInteger randomPart2() {
    return randomPart1();
}

#pragma mark - instance method

- (void)invoke {
    NSDate *startDate = [NSDate date];
    
    self.storage = [NSMutableArray array];
    NSMutableArray *storage = self.storage;
    
    SEL addObjectSelector = @selector(addObject:);
    IMP addObjectIMP = class_getMethodImplementation(objc_getClass("NSMutableArray"), addObjectSelector);
    
    Class numberClass = objc_getClass("NSNumber");
    SEL numberWithIntegerSelector = @selector(numberWithInteger:);
    IMP numberWithIntegerIMP = class_getMethodImplementation(objc_getMetaClass("NSNumber"), numberWithIntegerSelector);
    
    for (NSInteger i = 0; i < 1000; i++) {
        for (NSInteger j = 0; j < 1000; j++) {
            // [NormalObject randomIntegerValue] => randomIntegerValue()
            // [NSNumber numberWithInteger:[NormalObject randomIntegerValue]] => numberWithIntegerIMP(numberClass, numberWithIntegerSelector, randomIntegerValue())
            // [self.storage addObject:[NSNumber numberWithInteger:[NormalObject randomIntegerValue]]] => addObjectIMP(storage, addObjectSelector, numberWithIntegerIMP(numberClass, numberWithIntegerSelector, randomIntegerValue()));
            addObjectIMP(storage, addObjectSelector, numberWithIntegerIMP(numberClass, numberWithIntegerSelector, randomIntegerValue()));
        }
    }
    self.storage = nil;
    
    NSLog(@"IMPObject cost : %f", -[startDate timeIntervalSinceNow]);
}

@end
