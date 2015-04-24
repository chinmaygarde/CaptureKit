
#import "AppDelegate.h"
#import <CaptureKit/CaptureKit.h>

@interface AppDelegate ()

@property (nonatomic, strong) CKScreenRecorderHUD *hud;

@end

@implementation AppDelegate

-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self addSubviews];
    
    self.hud = [[CKScreenRecorderHUD alloc] init];
    self.hud.targetView = self.window;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(void) addSubviews {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.fromValue = @( 0.0 );
    animation.toValue = @( M_PI * 2 );
    
    animation.duration = 4;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    animation.repeatCount = HUGE_VALF;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    view.center = CGPointMake(screenSize.width / 2.0 , screenSize.height / 2.0);
    
    view.backgroundColor = [UIColor blueColor];
    view.layer.cornerRadius = 50;
    
    [view.layer addAnimation:animation forKey:nil];
    
    UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(25, 25, 150, 150)];
    subview.backgroundColor = [UIColor greenColor];
    subview.layer.cornerRadius = 50;
    
    animation.autoreverses = YES;
    
    [subview.layer addAnimation:animation forKey:nil];
    
    [view addSubview:subview];
    
    [self.window addSubview:view];

    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 30, screenSize.width - 20, screenSize.height * 0.20)];
    textView.text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo";
    [self.window addSubview:textView];
}

@end
