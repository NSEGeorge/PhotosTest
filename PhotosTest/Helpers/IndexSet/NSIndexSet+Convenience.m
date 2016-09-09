//
//  NSIndexSet+Convenience.m
//  ProgressApp
//
//  Created by Georgij on 05.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

@import UIKit;
#import "NSIndexSet+Convenience.h"

@implementation NSIndexSet (Convenience)

- (NSArray *)pa_indexPathsFromIndexesWithSection:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}


@end
