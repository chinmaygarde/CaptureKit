//
//  AppDelegate.m
//  CaptureKitExample
//
//  Created by Chinmay Garde on 7/24/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import "AppDelegate.h"
#import <CaptureKit/CaptureKit.h>

@implementation AppDelegate

-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self addSubviews];
    
    [self recordWindow];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(void) recordWindow {
    CKScreenRecorder *recorder = [[CKScreenRecorder alloc] init];
    
    recorder.targetView = self.window;
    
    [recorder startRecording:^(BOOL success) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [recorder endRecordingWithCompletionHandler:^(BOOL success) {
                NSLog(@"Completed Recording %d", success);
            }];
        });
    }];
}

-(void) addSubviews {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.fromValue = @( 0.0 );
    animation.toValue = @( M_PI * 2 );
    
    animation.duration = 4;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    animation.repeatCount = HUGE_VALF;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    view.center = CGPointMake(screenSize.width / 2.0 , screenSize.height / 2.0);
    
    view.backgroundColor = [UIColor blueColor];
    view.layer.cornerRadius = 50;
    
    [view.layer addAnimation:animation forKey:nil];
    
    UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(25, 25, 150, 150)];
    subview.backgroundColor = [UIColor greenColor];
    subview.layer.cornerRadius = 50;
    
    animation.autoreverses = YES;
    
    [subview.layer addAnimation:animation forKey:nil];
    
    [view addSubview:subview];
    
    [self.window addSubview:view];
}

@end
