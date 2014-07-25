//
//  CaptureKitTests.m
//  CaptureKitTests
//
//  Created by Chinmay Garde on 7/20/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CaptureKit/CaptureKit.h>

@interface CaptureKitTests : XCTestCase


@end

@implementation CaptureKitTests

-(void) testRecordingStartAndEnd {
    UIView *target = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 300, 200)];
    target.backgroundColor = [UIColor redColor];
    
    CKScreenRecorder *recorder = [[CKScreenRecorder alloc] init];
    recorder.targetView = target;
    
    XCTAssertTrue([recorder startRecording]);
    
    XCTestExpectation *endExpectation = [self expectationWithDescription:@"end recording"];
    
    [recorder endRecordingWithCompletionHandler:^(BOOL success) {
        XCTAssertTrue(success);
        [endExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

-(void) testRecordingStartFailureWhenNoTargetView {
    CKScreenRecorder *recorder = [[CKScreenRecorder alloc] init];
    XCTAssertFalse([recorder startRecording]);
}

-(void) testFrameCapture {
    UIView *target = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 200, 100)];
    target.backgroundColor = [UIColor redColor];
    
    CKScreenRecorder *recorder = [[CKScreenRecorder alloc] init];
    recorder.targetView = target;
    
    XCTAssertTrue([recorder startRecording]);
    
    XCTestExpectation *endExpectation = [self expectationWithDescription:@"end recording"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [recorder endRecordingWithCompletionHandler:^(BOOL success) {
            XCTAssertTrue(success);
            XCTAssertTrue(recorder.capturedFrames > 10);
            [endExpectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:7 handler:nil];
}

@end
