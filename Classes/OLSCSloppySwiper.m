//
//  OLSCSloppySwiper.m
//  securedcomm
//
//  Created by onelab on 2017/11/20.
//  Copyright © 2017年 Jimmy.Chen. All rights reserved.
//

#import "OLSCSloppySwiper.h"
#import "OLSCSSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"

@implementation NoSwiperInfo
+ (CGRect)defaultIgnoreFrameByView:(UIView *)view{
    if (!view.superview){
        return CGRectZero;
    }
    
    CGFloat extent =  30;
    CGRect extentFrame = CGRectMake(view.frame.origin.x - (extent/2),
                                    view.frame.origin.y - (extent/2),
                                    view.frame.size.width + extent,
                                    view.frame.size.height + extent);
    CGRect ignoreFrame = [view.superview convertRect:extentFrame toView:nil];
    
    return ignoreFrame;
}
@end

@interface OLSCSloppySwiper() <UIGestureRecognizerDelegate, SSWAnimatorDelegate>
@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (weak, nonatomic) IBOutlet UINavigationController *navigationController;
@property (strong, nonatomic) SSWAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the navigation controller is currently animating a push/pop operation.
@property (nonatomic) BOOL duringAnimation;
@property (nonatomic, strong) NSMutableArray *noSwiperInfos;

@end

@implementation OLSCSloppySwiper
- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
{
    NSCParameterAssert(!!navigationController);
    
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    SSWDirectionalPanGestureRecognizer *panRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panRecognizer.direction = SSWPanDirectionRight;
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [_navigationController.view addGestureRecognizer:panRecognizer];
    self.panRecognizer = panRecognizer;
    
    _animator = [[OLSCSSWAnimator alloc] init];
    _animator.delegate = self;
    
    self.noSwiperInfos = [NSMutableArray new];
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:D_NOTIFICATION_ADD_NO_SWIPER object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NoSwiperInfo *info = (NoSwiperInfo *)note.object;
        [strongSelf.noSwiperInfos addObject:info];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:D_NOTIFICATION_REMOVE_NO_SWIPER object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.noSwiperInfos removeAllObjects];
    }];
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.disablePopCheck) {
        return NO;
    }
    BOOL isContain = NO;
    CGPoint startLocation = [gestureRecognizer locationInView:self.navigationController.view];
    
    if (self.smallLocationCheck) {
        if (startLocation.x > self.navigationController.view.frame.size.width/4) {
            return NO;
        }
    }
    
    CGRect rect = [self.navigationController.navigationBar.superview convertRect:self.navigationController.navigationBar.frame toView:nil];
    isContain = CGRectContainsPoint(rect, startLocation);
    if (!isContain){
        NSString *className = NSStringFromClass([self.navigationController.topViewController class]);
        for (NoSwiperInfo *info in self.noSwiperInfos){
            if ([info.className isEqualToString:className]){
                isContain = CGRectContainsPoint(info.viewRect, startLocation);
                if (isContain){
                    break;
                }
            }
        }
    }
    
    if (NO == isContain && self.navigationController.viewControllers.count > 1){
        return YES;
    }
    
    return NO;
}

@end
