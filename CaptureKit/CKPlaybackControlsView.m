
#import "CKPlaybackControlsView.h"

static const CGSize CKPlaybackControlsButtonSize = { 30.0, 30.0 };
static const CGSize CKPlaybackControlsViewExpandedSize = { 240.0, 38.0 };
static const CGSize CKPlaybackControlsViewContractedSize = { 38.0, 38.0 };
static const CGFloat CKPlaybackControlsInset = 10.0;

@interface CKPlaybackControlsView ()

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *expandCollapseButton;

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) NSTimer *updateTimer;

@end

@implementation CKPlaybackControlsView {
    NSDateFormatter *_timeFormatter;
    BOOL _isCollapsed;
}

-(void) performCommonPlaybackControlsInitialization {
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setDateFormat:@"mm:ss"];
    
    [self setupAppearance];
    
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];

    self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.recordButton setImage: [UIImage imageNamed:@"CKPlay" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                       forState: UIControlStateNormal];

    [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.expandCollapseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.expandCollapseButton setImage: [UIImage imageNamed:@"CKContract" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                               forState: UIControlStateNormal];
    
    [self.expandCollapseButton addTarget:self action:@selector(expandCollapseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.timeLabel];
    [self addSubview:self.recordButton];
    [self addSubview:self.expandCollapseButton];
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

-(void) setupAppearance {
    CAGradientLayer *layer = (CAGradientLayer *)self.layer;

    layer.colors = @[
        (id)[UIColor colorWithWhite:0.6 alpha:1.0].CGColor,
        (id)[UIColor colorWithWhite:0.23 alpha:1.0].CGColor,
        (id)[UIColor colorWithWhite:0.102 alpha:1.0].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor,
    ];
    
    layer.locations = @[
        @(0.0),
        @(0.05),
        @(0.5),
        @(1.0),
    ];
    
    layer.cornerRadius = 5.0;

    layer.borderColor = [UIColor darkGrayColor].CGColor;
    
    layer.borderWidth = 1.0;
    
    layer.opacity = 0.975;
}

-(void) setRecorder:(CKScreenRecorder *)recorder {
    if (_recorder == recorder)
        return;
    
    [_recorder removeObserver:self forKeyPath:@"state"];
    
    _recorder = recorder;
    
    [_recorder addObserver:self forKeyPath:@"state" options:0 context:NULL];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(CKScreenRecorder *) recorder change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL showRecordButton = NO;
        BOOL showTimeLabel = NO;
        
        switch (recorder.state) {
            case CKScreenRecorderNotSetup:
                break;
            case CKScreenRecorderReady:
                showRecordButton = YES;
                showTimeLabel = YES;
                break;
            case CKScreenRecorderRecording:
                showRecordButton = YES;
                showTimeLabel = YES;
                break;
            case CKScreenRecorderFinishing:
                break;
            case CKScreenRecorderFinished:
                break;
            case CKScreenRecorderFailed:
                break;
        }
        
        self.recordButton.hidden = !showRecordButton;
        self.timeLabel.hidden = !showTimeLabel;
    });
}

-(void) recordButtonPressed:(id) sender {
    switch (self.recorder.state) {
        case CKScreenRecorderReady:
            [self startRecording];
            break;
        case CKScreenRecorderRecording:
            [self stopRecording];
            break;
        default:
            break;
    }
}

-(void) expandCollapseButtonPressed:(id) sender {
    _isCollapsed = !_isCollapsed;
    
    NSString *imageName = _isCollapsed ? @"CKExpand" : @"CKContract";
    
    [self.expandCollapseButton setImage: [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                               forState: UIControlStateNormal];
    
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect bounds = CGRectZero;
        
        bounds.size = _isCollapsed ? CKPlaybackControlsViewContractedSize : CKPlaybackControlsViewExpandedSize;
        
        self.bounds = bounds;
    }];
}

-(void) startRecording {
    // Update the UI
    [self.recordButton setImage: [UIImage imageNamed:@"CKStop" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                       forState: UIControlStateNormal];
    
    // Setup timer for UI
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateWhileCapturing) userInfo:nil repeats:YES];
    
    // Start recording
    [self.recorder startRecording:nil];
}

-(void) updateWhileCapturing {
    self.timeLabel.text = [_timeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.recorder.capturedInterval]];
    
    [self setNeedsLayout];
}

-(void) stopRecording {
    [self.recordButton setImage: [UIImage imageNamed:@"CKPlay" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil]
                       forState: UIControlStateNormal];
    
    [self.updateTimer invalidate];
    self.updateTimer = nil;
    
    [self.recorder stopRecording:nil];
}

-(void) layoutSubviews {
    
    const CGRect bounds = self.bounds;
    
    self.recordButton.hidden = _isCollapsed;
    self.timeLabel.hidden = _isCollapsed;
    
    self.recordButton.bounds = CGRectMake(0.0, 0.0, CKPlaybackControlsButtonSize.width, CKPlaybackControlsButtonSize.height);
    self.recordButton.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
    
    const CGSize timeBounds = [self.timeLabel sizeThatFits:bounds.size];
    self.timeLabel.frame = CGRectMake(CKPlaybackControlsInset, (bounds.size.height - timeBounds.height) / 2.0, timeBounds.width, timeBounds.height);
    
    
    if (_isCollapsed) {
        self.expandCollapseButton.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
    } else {
        self.expandCollapseButton.frame = CGRectMake(bounds.size.width - CKPlaybackControlsInset - CKPlaybackControlsButtonSize.width,
                                                     (bounds.size.height - CKPlaybackControlsButtonSize.height) / 2.0,
                                                     CKPlaybackControlsButtonSize.width,
                                                     CKPlaybackControlsButtonSize.height);
    }
}

-(CGSize) sizeThatFits:(CGSize)size {
    return _isCollapsed ? CKPlaybackControlsViewContractedSize : CKPlaybackControlsViewExpandedSize;
}

+(Class) layerClass {
    return [CAGradientLayer class];
}

-(void) dealloc {
    [_recorder removeObserver:self forKeyPath:@"state"];
}

@end
