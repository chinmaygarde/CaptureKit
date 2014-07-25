//
//  CKScreenRecorder.m
//  CaptureKit
//
//  Created by Chinmay Garde on 7/20/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import "CKScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>

static const int32_t CKScreenRecorderTimebase = 30;

@implementation CKScreenRecorder {
    dispatch_queue_t _captureQueue;
    dispatch_source_t _captureTimer;
    
    AVAssetWriter *_writer;
    AVAssetWriterInputPixelBufferAdaptor *_writerInputAdaptor;
    
    CGSize _videoSize;
}

-(void) startRecording:(CKScreenRecorderCallback) completion {
    if (_targetView == nil) {
        // A target view must be assigned
        completion(NO);
    }
    
    CGSize size = _targetView.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    _videoSize = CGSizeMake(size.width * scale, size.height * scale);
    _captureQueue = dispatch_queue_create("com.capturekit.recorder", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(_captureQueue, ^{
        BOOL startSuccess = [self startRecordingAtSize:_videoSize];
        
        // All callbacks to user facing APIs are performed on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(startSuccess);
        });
    });
}

-(BOOL) startRecordingAtSize:(CGSize) size {
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"Movie.mov"];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    // Asset Writer Setup
    NSError *writerError = nil;
    _writer = [AVAssetWriter assetWriterWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&writerError];
    
    if (writerError != nil) {
        [self cleanupResources];
        return NO;
    }
    
    
    NSDictionary *inputSettings = @{
                                    AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: @(size.width),
                                    AVVideoHeightKey: @(size.height),
                                    };
    
    // Asset Writer Input Setup
    
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:inputSettings];

    writerInput.expectsMediaDataInRealTime = YES;
    
    // Asset Writer Input Pixel Buffer Adaptor Setup
    
    _writerInputAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput: writerInput
                                                                                           sourcePixelBufferAttributes: @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32ARGB) }];
    
    // Finalize and Start Writing
    
    if (![_writer canAddInput:writerInput]) {
        [self cleanupResources];
        return NO;
    }

    [_writer addInput:writerInput];
    
    if (![_writer startWriting]) {
        [self cleanupResources];
        return NO;
    }
    
    [_writer startSessionAtSourceTime:CMTimeMake(0, CKScreenRecorderTimebase)];
    
    [self setupTimerOnCaptureQueue];
    
    return YES;
}

-(void) setupTimerOnCaptureQueue {
    NSAssert(_captureQueue, @"The capture queue must already be setup");
    
    _captureTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _captureQueue);
    
    dispatch_source_set_timer(_captureTimer, dispatch_walltime(NULL, 0), (1.0 / 30.0) * NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(_captureTimer, ^{
        [self captureFrame];
    });
    
    dispatch_resume(_captureTimer);
}

-(BOOL) cleanupResources {
    
    BOOL cleanupSuccess = NO;
    
    if (_writer.outputURL) {
        NSError *fileCleanupError = nil;
        
        [[NSFileManager defaultManager] removeItemAtURL: _writer.outputURL error: &fileCleanupError];
        
        cleanupSuccess = (fileCleanupError == nil);
    }
    
    _writer = nil;
    _writerInputAdaptor = nil;
    
    dispatch_suspend(_captureTimer);
    
    return cleanupSuccess;
}

-(void) captureFrame {
    
    AVAssetWriterInput *writerInput = _writerInputAdaptor.assetWriterInput;
    
    if (!writerInput.isReadyForMoreMediaData) {
        // Drop the frame
        return;
    }
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _writerInputAdaptor.pixelBufferPool, &pixelBuffer);
    
    if (status != kCVReturnSuccess) {
        // Drop the frame
        // Could not acquire the pixel buffer
        return;
    }
    
    status = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    if (status != kCVReturnSuccess) {
        // Drop the frame
        // Could not lock the base address
        return;
    }
    
    void *buffer = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGSize size = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(buffer, size.width, size.height, 8, 4 * size.width, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
    
    CGColorSpaceRelease(colorspace);
    
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    UIGraphicsPushContext(context);
    
    [self.targetView drawViewHierarchyInRect:CGRectMake(0, 0, size.width, size.height) afterScreenUpdates:NO];
    
    UIGraphicsPopContext();
    
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    [_writerInputAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(_capturedFrames ++, CKScreenRecorderTimebase)];
    
    CVPixelBufferRelease(pixelBuffer);
}

-(void) endRecordingWithCompletionHandler:(CKScreenRecorderCallback) completion {
    // FIXME: Check for invalid state transitions
    
    [_writerInputAdaptor.assetWriterInput markAsFinished];
    [_writer finishWritingWithCompletionHandler:^{
        BOOL writerSuccess = (_writer.status == AVAssetWriterStatusCompleted);
        BOOL cleanupSuccess = [self cleanupResources];

        // All callbacks to user facing APIs are performed on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(writerSuccess && cleanupSuccess);
        });
    }];
}

@end
