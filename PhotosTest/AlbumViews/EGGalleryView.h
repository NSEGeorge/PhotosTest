//
//  EGGalleryView.h
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGImageCropView.h"
@import Photos;

@protocol EGGalleryViewDelegate <NSObject>

- (void)albumUnauthorized;

@end

@interface EGGalleryView : UIView

@property (weak, nonatomic) id<EGGalleryViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet EGImageCropView* imageCropView;

@property (strong, nonatomic) PHAsset* phAsset;
@property (assign, nonatomic) EGAssetType assetType;

- (EGGalleryView *)instance;
- (void)initialize;

@end
