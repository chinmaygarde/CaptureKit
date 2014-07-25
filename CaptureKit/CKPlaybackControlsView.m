//
//  CKPlaybackControlsView.m
//  CaptureKit
//
//  Created by Chinmay Garde on 7/25/14.
//  Copyright (c) 2014 Chinmay Garde. All rights reserved.
//

#import "CKPlaybackControlsView.h"

static const CGSize CKPlaybackControlsViewMinimumSize = { 300.0, 44.0 };

@interface CKPlaybackControlsView ()

@property (nonatomic, strong) UIButton *recordButton;

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation CKPlaybackControlsView

-(void) performCommonPlaybackControlsInitialization {
    self.layer.cornerRadius = 10;
    self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85];
    
    self.timeLabel = [[UILabel alloc] init];
    self.statusLabel = [[UILabel alloc] init];

    self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.recordButton.backgroundColor = [UIColor whiteColor];
    
    [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.timeLabel];
    [self addSubview:self.statusLabel];
    [self addSubview:self.recordButton];
}

-(instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self performCommonPlaybackControlsInitialization];
    }
    
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self performCommonPlaybackControlsInitialization];
    }
    
    return self;
}

-(void) recordButtonPressed:(id) sender {
    [self.delegate playbackControlsDidToggleRecording:self];
}

-(void) layoutSubviews {
    
    const CGRect bounds = self.bounds;
    
    self.recordButton.bounds = CGRectMake(0.0, 0.0, 30.0, 30.0);
    self.recordButton.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
}

-(CGSize) sizeThatFits:(CGSize)size {
    return CGSizeMake(MAX(CKPlaybackControlsViewMinimumSize.width, size.width),
                      MAX(CKPlaybackControlsViewMinimumSize.height, size.height));
}

@end
