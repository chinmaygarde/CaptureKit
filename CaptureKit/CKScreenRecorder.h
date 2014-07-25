//
//  CKScreenRecorder.h
//  CaptureKit
//
//  Created by Chinmay Garde on 7/20/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CKScreenRecorderState) {
    CKScreenRecorderNotSetup = 0,
    
    CKScreenRecorderReady,

    CKScreenRecorderRecording,
    
    CKScreenRecorderFinishing,
    CKScreenRecorderFinished
};

typedef void(^CKScreenRecorderCallback)(BOOL success);

@interface CKScreenRecorder : NSObject

@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, readonly) NSUInteger capturedFrames;

@property (nonatomic, readonly) CKScreenRecorderState state;

-(void) startRecording:(CKScreenRecorderCallback) completion;
-(void) stopRecording:(CKScreenRecorderCallback) completion;

@end
