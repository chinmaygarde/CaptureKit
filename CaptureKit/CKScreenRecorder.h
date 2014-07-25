//
//  CKScreenRecorder.h
//  CaptureKit
//
//  Created by Chinmay Garde on 7/20/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^CKScreenRecorderCallback)(BOOL success);

@interface CKScreenRecorder : NSObject

@property (nonatomic, weak) IBOutlet UIView *targetView;
@property (nonatomic, readonly) NSUInteger capturedFrames;

-(void) startRecording:(CKScreenRecorderCallback) completion;
-(void) endRecordingWithCompletionHandler:(CKScreenRecorderCallback) completion;

@end
