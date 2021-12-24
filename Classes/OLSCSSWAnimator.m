//
//  OLSCSSWAnimator.m
//  securedcomm
//
//  Created by onelab on 2017/11/20.
//  Copyright © 2017年 Jimmy.Chen. All rights reserved.
//

#import "OLSCSSWAnimator.h"
UIViewAnimationOptions const SSWNavigationTransitionCurve = 7 << 16;

@implementation UIView (TransitionShadow)
- (void)addLeftSideShadowWithFading
{
    CGFloat shadowWidth = 4.0f;
    CGFloat shadowVerticalPadding = -20.0f; // negative padding, so the shadow isn't rounded near the top and the bottom
    CGFloat shadowHeight = CGRectGetHeight(self.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = [shadowPath CGPath];
    self.layer.shadowOpacity = 0.2f;
    
    // fade shadow during transition
    CGFloat toValue = 0.0f;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue = @(self.layer.shadowOpacity);
    animation.toValue = @(toValue);
    [self.layer addAnimation:animation forKey:nil];
    self.layer.shadowOpacity = toValue;
}
@end


@interface OLSCSSWAnimator(){
    BOOL fromVCOriTabHidden;
}
@property (weak, nonatomic) UIViewController *toViewController;
@property (weak, nonatomic) UIViewController *fromViewController;
@end

@implementation OLSCSSWAnimator
// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    // parallax effect; the offset matches the one used in the pop animation in iOS 7.1
    CGFloat toViewControllerXTranslation = - CGRectGetWidth([transitionContext containerView].bounds) * 0.3f;
//    toViewController.view.bounds = [transitionContext containerView].bounds;
//    toViewController.view.center = [transitionContext containerView].center;
    toViewController.view.transform = CGAffineTransformMakeTranslation(toViewControllerXTranslation, 0);
    
    // add a shadow on the left side of the frontmost view controller
    [fromViewController.view addLeftSideShadowWithFading];
    BOOL previousClipsToBounds = fromViewController.view.clipsToBounds;
    fromViewController.view.clipsToBounds = NO;
    
    //fix hidesBottomBarWhenPushed issue
    _isPreviousViewHideTabBar = toViewController.tabBarController.tabBar.isHidden;
    
    fromVCOriTabHidden = fromViewController.hidesBottomBarWhenPushed;//fromViewController.tabBarController.tabBar.isHidden;
    UIImageView *imageView;
    if(!_isPreviousViewHideTabBar){ //if tabbar had hidden don't do anything.
        UIImage *tabBarScreenShot = [self getScreenShotFromView:toViewController.tabBarController.tabBar];
        CGRect tabBarRect = toViewController.tabBarController.tabBar.frame;
        
        [toViewController.view setFrame:CGRectMake(toViewController.view.frame.origin.x, toViewController.view.frame.origin.y, toViewController.view.frame.size.width, toViewController.view.frame.size.height)];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, toViewController.view.frame.size.height, tabBarRect.size.width, tabBarRect.size.height)];
//        fix UITableViewController position issue
        if ([toViewController isKindOfClass:[UITableViewController class]]) {
            UITableViewController *toTableViewControler = (UITableViewController *)toViewController;
            [imageView setFrame:CGRectMake(0, toTableViewControler.tableView.contentOffset.y+toTableViewControler.view.frame.size.height-tabBarRect.size.height, tabBarRect.size.width, tabBarRect.size.height)];
        }
        [imageView setImage:tabBarScreenShot];
        [toViewController.view addSubview:imageView];
        [toViewController.tabBarController.tabBar setHidden:YES];
    }
    
    // in the default transition the view controller below is a little dimmer than the frontmost one
    UIView *dimmingView = [[UIView alloc] initWithFrame:toViewController.view.bounds];
    CGFloat dimAmount = [self.delegate animatorTransitionDimAmount:self];
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:dimAmount];
    [toViewController.view addSubview:dimmingView];
    
    // Uses linear curve for an interactive transition, so the view follows the finger. Otherwise, uses a navigation transition curve.
    UIViewAnimationOptions curveOption = [transitionContext isInteractive] ? UIViewAnimationOptionCurveLinear : SSWNavigationTransitionCurve;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionTransitionNone | curveOption animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.transform = CGAffineTransformMakeTranslation(toViewController.view.frame.size.width, 0);
        dimmingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [dimmingView removeFromSuperview];
        fromViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.clipsToBounds = previousClipsToBounds;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        
        //remove subviews
        if (!_isPreviousViewHideTabBar) {
            [imageView removeFromSuperview];
//            [toViewController.tabBarController.tabBar setHidden:NO];
//            NSLog(@"TRACE Bill_Bug");
        }
    }];
    
    self.toViewController = toViewController;
    self.fromViewController = fromViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was cancelled
    if (!transitionCompleted) {
        self.toViewController.view.transform = CGAffineTransformIdentity;
        if (fromVCOriTabHidden) {
            [self.fromViewController.tabBarController.tabBar setHidden:YES];
        }
    }else{
        if (!_isPreviousViewHideTabBar) {
            [self.toViewController.tabBarController.tabBar setHidden:NO];
        }
    }
}

-(UIImage *)getScreenShotFromView:(UIView *)view{
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [UIScreen mainScreen].scale);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return viewImage;
}
@end
