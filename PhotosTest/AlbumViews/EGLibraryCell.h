//
//  EGLibraryCell.h
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EGLibraryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView* badgeView;

@property (weak, nonatomic) UIImage* thumbnailImage;
@property (nonatomic, copy) NSString *representedAssetIdentifier;

@end
