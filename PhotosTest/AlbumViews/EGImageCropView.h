//
//  EGImageCropView.h
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Enums.h"

@interface EGImageCropView : UIScrollView

@property (strong, nonatomic) UIImage* image;
@property (assign, nonatomic) CGSize imageSize;

- (void)changeScrollable:(BOOL)isScrollable;
- (void)setupVideoPlayer;

@property (strong, nonatomic) NSURL* videoURL;
@property (assign, nonatomic) EGAssetType assetType;

@end
