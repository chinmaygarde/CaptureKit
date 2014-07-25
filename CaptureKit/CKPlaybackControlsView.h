//
//  CKPlaybackControlsView.h
//  CaptureKit
//
//  Created by Chinmay Garde on 7/25/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CKPlaybackControlsView;
@protocol CKPlaybackControlsViewDelegate <NSObject>

@required
-(void) playbackControlsDidToggleRecording:(CKPlaybackControlsView *) controls;

@end

@interface CKPlaybackControlsView : UIView

@property (nonatomic, weak) id<CKPlaybackControlsViewDelegate> delegate;

@end
