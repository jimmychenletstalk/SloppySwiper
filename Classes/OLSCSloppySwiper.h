//
//  OLSCSloppySwiper.h
//  securedcomm
//
//  Created by onelab on 2017/11/20.
//  Copyright © 2017年 Jimmy.Chen. All rights reserved.
//

#import <SloppySwiper/SloppySwiper.h>

#define D_NOTIFICATION_ADD_NO_SWIPER @"D_NOTIFICATION_ADD_NO_SWIPER"
#define D_NOTIFICATION_REMOVE_NO_SWIPER @"D_NOTIFICATION_REMOVE_NO_SWIPER"

@interface NoSwiperInfo:NSObject
@property (nonatomic, strong) NSString *className;
@property (nonatomic) CGRect viewRect;
+ (CGRect)defaultIgnoreFrameByView:(UIView *)view;
@end

@interface OLSCSloppySwiper : SloppySwiper
//- (void)commonInit;
@property (weak, readonly, nonatomic) UIPanGestureRecognizer *panRecognizer;

@property BOOL smallLocationCheck;
@property BOOL disablePopCheck;

@end
