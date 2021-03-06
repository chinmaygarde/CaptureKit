
#import "CKScreenRecorderHUD.h"
#import "CKPlaybackControlsView.h"

static const CGFloat CKScreenRecorderHUDInset = 10.0;

@interface CKScreenRecorderHUD ()

@property (nonatomic, strong) CKPlaybackControlsView *controls;

@end

@implementation CKScreenRecorderHUD {
    CGPoint _startingLocationInPan;
}

-(void) performCommonScreenRecorderHUDInitialization {
    self.windowLevel = UIWindowLevelNormal + 1;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(windowDimensionsNeedUpdate)
                                                 name: UIDeviceOrientationDidChangeNotification
                                               object: [UIDevice currentDevice]];
    
    self.hidden = NO;

    self.controls = [[CKPlaybackControlsView alloc] init];

    [self addSubview:self.controls];
    
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanControls:)];
    [self.controls addGestureRecognizer:recognizer];
    
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
    self.controls.recorder.targetView = targetView;
}

-(UIView *) targetView {
    return self.controls.recorder.targetView;
}

-(void) layoutSubviews {
    CKPlaybackControlsView *controls = self.controls;
    
    const CGSize boundsSize = self.bounds.size;
    
    CGSize controlsSize = [controls sizeThatFits:CGSizeMake(0.0, 0.0)];
    
    if (CGPointEqualToPoint(controls.center, CGPointZero)) {
        controls.frame = CGRectMake((boundsSize.width - controlsSize.width) / 2.0,
                                    boundsSize.height - controlsSize.height - CKScreenRecorderHUDInset,
                                    controlsSize.width, controlsSize.height);
    }
}

-(void) onPanControls:(UIPanGestureRecognizer *) pan {
    switch (pan.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
            _startingLocationInPan = self.controls.center;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [pan translationInView:self];
            self.controls.center = CGPointMake(_startingLocationInPan.x + translation.x, _startingLocationInPan.y + translation.y);
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            _startingLocationInPan = CGPointZero;
            break;
    }
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
