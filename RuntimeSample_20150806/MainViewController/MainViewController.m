//
//  MainViewController.m
//  RuntimeSample_20150806
//
//  Created by 啟倫 陳 on 2015/8/1.
//  Copyright (c) 2015年 ChilunChen. All rights reserved.
//

#import "MainViewController.h"
#import "NormalObject.h"
#import "EnhanceObject.h"

@implementation MainViewController

#pragma mark - IBAction

- (IBAction)runAction:(id)sender {
    NormalObject *normalObject = [NormalObject new];
    [normalObject invoke];
    
    EnhanceObject *enhanceObject = [EnhanceObject new];
    [enhanceObject invoke];
}

@end
