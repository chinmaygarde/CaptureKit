//
//  CKScreenRecorderHUD.m
//  CaptureKit
//
//  Created by Chinmay Garde on 7/25/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import "CKScreenRecorderHUD.h"
#import "CKPlaybackControlsView.h"

static const CGFloat CKScreenRecorderHUDInset = 10.0;

@interface CKScreenRecorderHUD () <CKPlaybackControlsViewDelegate>

@property (nonatomic, readwrite, strong) CKScreenRecorder *recorder;

@property (nonatomic, strong) CKPlaybackControlsView *controls;

@end

@implementation CKScreenRecorderHUD

-(void) performCommonScreenRecorderHUDInitialization {
    self.windowLevel = UIWindowLevelNormal + 1;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(windowDimensionsNeedUpdate)
                                                 name: UIDeviceOrientationDidChangeNotification
                                               object: [UIDevice currentDevice]];
    
    self.hidden = NO;
    
    self.recorder = [[CKScreenRecorder alloc] init];

    self.controls = [[CKPlaybackControlsView alloc] init];
    self.controls.delegate = self;

    [self addSubview:self.controls];
    
    [self windowDimensionsNeedUpdate];
}

-(instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self performCommonScreenRecorderHUDInitialization];
    }
    
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self performCommonScreenRecorderHUDInitialization];
    }
    
    return self;
}

-(void) setTargetView:(UIView *)targetView {
    self.recorder.targetView = targetView;
}

-(UIView *) targetView {
    return self.recorder.targetView;
}

-(void) playbackControlsDidToggleRecording:(CKPlaybackControlsView *)controls {
    switch (self.recorder.state) {
        case CKScreenRecorderReady:
            [self.recorder startRecording:nil];
            break;
        case CKScreenRecorderRecording:
            [self.recorder stopRecording:nil];
            break;
        default:
            break;
    }
}

-(void) layoutSubviews {
    CKPlaybackControlsView *controls = self.controls;
    
    const CGSize boundsSize = self.bounds.size;
    
    CGSize controlsSize = [controls sizeThatFits:CGSizeMake(0.0, 0.0)];
    
    controls.frame = CGRectMake((boundsSize.width - controlsSize.width) / 2.0,
                                 boundsSize.height - controlsSize.height - CKScreenRecorderHUDInset,
                                 controlsSize.width, controlsSize.height);
}

-(void) windowDimensionsNeedUpdate {
    
    CGSize orientedScreenSize = [UIScreen mainScreen].bounds.size;
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    BOOL isValid = UIDeviceOrientationIsValidInterfaceOrientation(orientation);
    
    BOOL isLandscape = isValid && UIDeviceOrientationIsLandscape(orientation);
    
    if (isLandscape)
        orientedScreenSize = CGSizeMake(orientedScreenSize.height, orientedScreenSize.width);
    
    self.frame = CGRectMake(0.0, 0.0, orientedScreenSize.width, orientedScreenSize.height);
}

-(UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitTest = [super hitTest:point withEvent:event];
    
    return (hitTest == self) ? nil : hitTest;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
