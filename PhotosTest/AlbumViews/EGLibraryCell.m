//
//  EGLibraryCell.m
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "EGLibraryCell.h"

@interface EGLibraryCell()

@property (weak, nonatomic) IBOutlet UIImageView* imageView;

@end

@implementation EGLibraryCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

- (void)setSelected:(BOOL)selected {
    self.layer.borderColor = selected ? [UIColor colorWithRed:0.f green:150.f/255.f blue:136.f/255.f alpha:1.0].CGColor : [UIColor clearColor].CGColor;
    self.layer.borderWidth = selected ? 2 : 0;
}

@end
