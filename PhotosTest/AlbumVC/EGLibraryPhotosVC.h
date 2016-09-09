//
//  EGLibraryPhotosVC.h
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Enums.h"

@protocol EGLibraryPhotosVCDelegate <NSObject>

@optional
- (void)closePhotosVCWithImage:(UIImage *)image;
- (void)closePhotosVCWithVideoSnapshot:(UIImage *)image andVideoURL:(NSURL *)videoURL;

@end

@interface EGLibraryPhotosVC : UIViewController

@property (weak, nonatomic) id<EGLibraryPhotosVCDelegate> delegate;
@property (assign, nonatomic) EGAssetType assetType;

@end
