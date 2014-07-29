
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CKScreenRecorderState) {
    CKScreenRecorderNotSetup = 0,
    
    CKScreenRecorderReady,

    CKScreenRecorderRecording,
    
    CKScreenRecorderFinishing,
    CKScreenRecorderFinished,
    CKScreenRecorderFailed,
};

typedef void(^CKScreenRecorderCallback)(BOOL success);

@interface CKScreenRecorder : NSObject

@property (nonatomic, weak) UIView *targetView;

@property (nonatomic, readonly) NSUInteger capturedFrames;
@property (nonatomic, readonly) NSTimeInterval capturedInterval;

@property (nonatomic, readonly) CKScreenRecorderState state;

-(void) startRecording:(CKScreenRecorderCallback) completion;
-(void) stopRecording:(CKScreenRecorderCallback) completion;

@end
