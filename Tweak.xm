#define appBundleID @"com.apple.preference"
#define UIColorFromHex(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s & 0xFF00) >> 8))/255.0 blue:((s & 0xFF))/255.0  alpha:1.0]
#define iOS10Later ([UIDevice currentDevice].systemVersion.floatValue >= 10.0f)
#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

@interface _UIBackdropView : UIView
-(id)initWithPrivateStyle:(long long)arg1;
@end

@interface SpringBoard : NSObject
-(void)applicationDidFinishLaunching:(id)application;
@end

@interface FBSceneHostWrapperView : UIView
@end

@interface UIMutableApplicationSceneSettings : NSObject
-(void)setBackgrounded:(BOOL)arg1;
@end

@interface FBSceneHostManager : NSObject
-(id)hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
@end

@interface FBWindowContextHostManager : FBSceneHostManager
@end

@interface FBScene : NSObject
@property (nonatomic,retain,readonly) FBWindowContextHostManager *contextHostManager;
@property UIMutableApplicationSceneSettings *mutableSettings;
-(void)updateSettings:(UIMutableApplicationSceneSettings *)arg1 withTransitionContext:(id)arg2;
@end

@interface SBApplication : NSObject
-(int)pid;
-(FBScene *)mainScene;
@end

@interface FBProcessManager : NSObject
+(id)sharedInstance;
-(void)createApplicationProcessForBundleID:(id)arg1;
@end

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application {
	%orig;

	if (!iOS10Later)
	{
		return;
	}

	 // prepare for iWindowApp
	UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
	UIView *hostView = [[UIView alloc] initWithFrame:window.bounds];
	_UIBackdropView *backdockEffect = [[_UIBackdropView alloc] initWithPrivateStyle:1000];
	UIView *appView;

	window.windowLevel = UIWindowLevelStatusBar;

	// launch the app.
	[[UIApplication sharedApplication] launchApplicationWithIdentifier:appBundleID suspended:YES];
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:appBundleID]; 

	// re-launch the app if it hasn't been launched.
	do {
		[[UIApplication sharedApplication] launchApplicationWithIdentifier:appBundleID suspended:YES];
		[[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:appBundleID];

		dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] launchApplicationWithIdentifier:appBundleID suspended:YES];
			[[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:appBundleID];
        });

	}while ([app pid] == -1);

	// update settings and host the app.
    UIMutableApplicationSceneSettings *settings = [app mainScene].mutableSettings;

    [settings setBackgrounded:NO];
    [settings setInterfaceOrientation:UIApplication.sharedApplication.statusBarOrientation];
    [[app mainScene] updateSettings:settings withTransitionContext:nil];

    //[[app mainScene].contextHostManager hostViewForRequester:@"iWinDowApp" enableAndOrderFront:true];
    appView = (FBSceneHostWrapperView *)[[app mainScene].contextHostManager hostViewForRequester:@"iWinDowApp" enableAndOrderFront:YES];
	appView.frame = CGRectMake(0, 0, kWidth, kHeight);

    [hostView addSubview:backdockEffect];
    [hostView addSubview:appView];
    [window addSubview:hostView];

    hostView.transform=CGAffineTransformScale(hostView.transform, 0.6, 0.6);

}

%end