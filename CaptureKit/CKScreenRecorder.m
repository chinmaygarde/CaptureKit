//
//  CKScreenRecorder.m
//  CaptureKit
//
//  Created by Chinmay Garde on 7/20/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import "CKScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>

void CKScreenRecorderCallbackPerform(CKScreenRecorderCallback callback, BOOL success) {
    if (callback == nil)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(success);
    });
}

static const int32_t CKScreenRecorderTimebase = 30;

@implementation CKScreenRecorder {
    dispatch_queue_t _captureQueue;
    dispatch_source_t _captureTimer;
    
    AVAssetWriter *_writer;
    AVAssetWriterInputPixelBufferAdaptor *_writerInputAdaptor;
    
    NSURL *_completedCaptureURL;
    CKScreenRecorderCallback _writeToFileCallback;
    
    CGSize _videoSize;
}

-(void) startRecording:(CKScreenRecorderCallback) completion {
    
    NSAssert(self.state == CKScreenRecorderReady, @"The recorder must be ready before attempting to start recording");
    
    CGSize size = _targetView.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    _videoSize = CGSizeMake(size.width * scale, size.height * scale);
    _captureQueue = dispatch_queue_create("com.capturekit.recorder", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(_captureQueue, ^{

        BOOL startSuccess = [self startRecordingAtSize:_videoSize];
        
        if (startSuccess)
            self.state = CKScreenRecorderRecording;

        CKScreenRecorderCallbackPerform(completion, startSuccess);
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

-(void)setState:(CKScreenRecorderState) state {
    if (_state == state)
        return;
    
    if (state < _state) {
        NSAssert(NO, @"Invalid state transition attempted in the recorder");
        return;
    }
    
    _state = state;
}

-(void) setTargetView:(UIView *)targetView {
    NSAssert(self.state == CKScreenRecorderNotSetup, @"Cannot change the recorder target view once it is setup");
    
    if (_targetView == targetView)
        return;
    
    _targetView = targetView;
    
    self.state = CKScreenRecorderReady;
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

-(void) cleanupResources {
    
    if (_writer.outputURL) {
        _completedCaptureURL = [_writer.outputURL copy];
    }
    
    _writer = nil;
    _writerInputAdaptor = nil;
    
    dispatch_suspend(_captureTimer);
    dispatch_source_cancel(_captureTimer);
}

-(void) writeToVideoLibrary:(CKScreenRecorderCallback) callback {
    
    if (_completedCaptureURL == nil) {
        CKScreenRecorderCallbackPerform(callback, NO);
        self.state = CKScreenRecorderFailed;
        return;
    }
    
    if (!UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(_completedCaptureURL.path)) {
        CKScreenRecorderCallbackPerform(callback, NO);
        self.state = CKScreenRecorderFailed;
        return;
    }
    
    _writeToFileCallback = callback;
    
    UISaveVideoAtPathToSavedPhotosAlbum(_completedCaptureURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
    
    _completedCaptureURL = nil;
}

-(void) video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    self.state = CKScreenRecorderFinished;
    
    CKScreenRecorderCallbackPerform(_writeToFileCallback, error != nil);
    
    _writeToFileCallback = nil;
}

-(void) captureFrame {
    
    AVAssetWriterInput *writerInput = _writerInputAdaptor.assetWriterInput;
    
    if (!writerInput.isReadyForMoreMediaData) {
        // Drop the frame
        return;
    }
    
    if (_writerInputAdaptor.pixelBufferPool == NULL) {
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
    
    if([_writerInputAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(_capturedFrames + 1, CKScreenRecorderTimebase)]) {
        // If writing was successful, update the book-keeping
        _capturedFrames ++;
        _capturedInterval = _capturedFrames / CKScreenRecorderTimebase;
    }
    
    CVPixelBufferRelease(pixelBuffer);
}

-(void) stopRecording:(CKScreenRecorderCallback) completion {
    NSAssert(self.state == CKScreenRecorderRecording, @"The recording must be ongoing to stop the same");
    
    [_writerInputAdaptor.assetWriterInput markAsFinished];

    [_writer finishWritingWithCompletionHandler:^{
    
        BOOL writerSuccess = (_writer.status == AVAssetWriterStatusCompleted);
        
        [self cleanupResources];

        if (writerSuccess) {

            self.state = CKScreenRecorderFinishing;

            [self writeToVideoLibrary: completion];

        } else {

            self.state = CKScreenRecorderFailed;
            
            CKScreenRecorderCallbackPerform(completion, NO);
            
        }
    }];
}

-(void) dealloc {
    [self cleanupResources];
    
    if (_completedCaptureURL) {
        // If for some reason the recorder is being collected without the
        // temporary file being written to the album, clean it up

        [[NSFileManager defaultManager] removeItemAtURL: _completedCaptureURL error: nil];
    }
}

@end
