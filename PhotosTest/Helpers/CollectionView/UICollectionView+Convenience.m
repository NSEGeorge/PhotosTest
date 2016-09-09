//
//  UICollectionView+Convenience.m
//  ProgressApp
//
//  Created by Georgij on 05.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "UICollectionView+Convenience.h"

@implementation UICollectionView (Convenience)

- (NSArray *)pa_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}


@end
