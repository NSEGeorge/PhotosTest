//
//  EGGalleryView.m
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "EGGalleryView.h"
#import "EGLibraryCell.h"
#import "NSIndexSet+Convenience.h"
#import "UICollectionView+Convenience.h"

#define imageCropViewOriginalConstraintTop 50.f
#define imageCropViewMinimalVisibleHeight 100.f
#define dragDiff 20.f

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionScroll,
    DirectionStop,
    DirectionUp,
    DirectionDown
};

@interface EGGalleryView() <UICollectionViewDataSource, UICollectionViewDelegate, PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UIView* imageCropViewContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* collectionViewContstraintHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* imageCropViewConstraintTop;

@property (strong, nonatomic) PHFetchResult* images;
@property (strong, nonatomic) PHCachingImageManager* imageManager;

@property (assign, nonatomic) CGRect previousPreheatRect;
@property (assign, nonatomic) CGSize cellSize;

@property (assign, nonatomic) Direction dragDirection;

@property (assign, nonatomic) CGFloat imaginaryCollectionViewOffsetStartPosY;
@property (assign, nonatomic) CGFloat cropBottomY;
@property (assign, nonatomic) CGPoint dragStartPos;

@end

@implementation EGGalleryView

- (void)setupVariables {
    _previousPreheatRect = CGRectZero;
    _cellSize = CGSizeMake(100, 100);
    _dragDirection = DirectionUp;
    _imaginaryCollectionViewOffsetStartPosY = 0.0f;
    _cropBottomY = 0.0f;
    _dragStartPos = CGPointZero;
}

- (EGGalleryView *)instance {
    return [[[UINib nibWithNibName:@"EGGalleryView" bundle:[NSBundle bundleForClass:self.classForCoder]] instantiateWithOwner:self options:nil] firstObject];
}

- (void)initialize {
    
    if (_images) {
        return;
    }
    
    self.hidden = NO;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self setupVariables];
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    _collectionViewContstraintHeight.constant = self.frame.size.height - _imageCropView.frame.size.height - imageCropViewOriginalConstraintTop;
    _imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop;
    
    _imageCropViewContainer.layer.shadowColor = [[UIColor blackColor] CGColor];
    _imageCropViewContainer.layer.shadowRadius = 30.0f;
    _imageCropViewContainer.layer.shadowOpacity = 0.9f;
    _imageCropViewContainer.layer.shadowOffset = CGSizeZero;
    
    [_collectionView registerNib:[UINib nibWithNibName:@"EGLibraryCell" bundle:nil] forCellWithReuseIdentifier:@"EGLibraryCell"];
    
    [self checkAuth];
    
    PHFetchOptions* options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    switch (_assetType) {
        case EGAssetTypeImage:
            _images = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
            break;
            
        case EGAssetTypeVideo:
            _images = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:options];
            break;
            
        default:
            break;
    }
    
    if (_images.count > 0) {
        [self changeImage:_images[0]];
        [_collectionView reloadData];
        [_collectionView selectItemAtIndexPath:0 animated:0 scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)panned:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIView* view = sender.view;
        CGPoint loc = [sender locationInView:view];
        UIView* subview = [view hitTest:loc withEvent:nil];
        
        if (subview == _imageCropView && _imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop) {
            return;
        }
        
        _dragStartPos = [sender locationInView:self];
        
        _cropBottomY = _imageCropViewContainer.frame.origin.y + _imageCropViewContainer.frame.size.height;
        
        if (_dragDirection == DirectionStop) {
            _dragDirection = (_imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop) ? DirectionUp : DirectionDown;
        }
        
        if ((_dragDirection == DirectionUp && _dragStartPos.y < _cropBottomY + dragDiff) ||
            (_dragDirection == DirectionDown && _dragStartPos.y > _cropBottomY)) {
            
            _dragDirection = DirectionStop;
            [_imageCropView changeScrollable:NO];
            
        } else {
            [_imageCropView changeScrollable:YES];
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        
        CGPoint currentPos = [sender locationInView:self];
        
        if (_dragDirection == DirectionUp && currentPos.y < _cropBottomY - dragDiff) {
            _imageCropViewConstraintTop.constant = MAX(imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.size.height, currentPos.y + dragDiff - _imageCropViewContainer.frame.size.height);
            
            _collectionViewContstraintHeight.constant = MIN(self.frame.size.height - imageCropViewMinimalVisibleHeight, self.frame.size.height - _imageCropViewConstraintTop.constant - _imageCropViewContainer.frame.size.height);
            
        } else if (_dragDirection == DirectionDown && currentPos.y > _cropBottomY) {
            _imageCropViewConstraintTop.constant = MIN(imageCropViewOriginalConstraintTop, currentPos.y - _imageCropViewContainer.frame.size.height);
            
            _collectionViewContstraintHeight.constant = MAX(self.frame.size.height - imageCropViewOriginalConstraintTop - _imageCropViewContainer.frame.size.height, self.frame.size.height - _imageCropViewConstraintTop.constant - _imageCropViewContainer.frame.size.height);
            
        } else if (_dragDirection == DirectionStop && _collectionView.contentOffset.y < 0) {
            _dragDirection = DirectionScroll;
            _imaginaryCollectionViewOffsetStartPosY = currentPos.y;
        }  else if (_dragDirection == DirectionScroll) {
            _imageCropViewConstraintTop.constant = imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.size.height + currentPos.y - _imaginaryCollectionViewOffsetStartPosY;
            
            _collectionViewContstraintHeight.constant = MAX(self.frame.size.height - imageCropViewOriginalConstraintTop - _imageCropViewContainer.frame.size.height, self.frame.size.height - _imageCropViewConstraintTop.constant - _imageCropViewContainer.frame.size.height);
        }
    } else {
        
        _imaginaryCollectionViewOffsetStartPosY = 0.0;
        
        if (sender.state == UIGestureRecognizerStateEnded && _dragDirection == DirectionStop) {
            [_imageCropView changeScrollable:YES];
            return;
        }
        
        CGPoint currentPos = [sender locationInView:self];
        
        if (currentPos.y < _cropBottomY - dragDiff && _imageCropViewConstraintTop.constant != imageCropViewOriginalConstraintTop) {
            
            [_imageCropView changeScrollable:NO];
            
            _imageCropViewConstraintTop.constant = imageCropViewMinimalVisibleHeight - self.imageCropViewContainer.frame.size.height;
            
            _collectionViewContstraintHeight.constant = self.frame.size.height - imageCropViewMinimalVisibleHeight;
            
            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self layoutIfNeeded];
                             } completion:nil];
            
            _dragDirection = DirectionDown;
            
        } else {
            
            [_imageCropView changeScrollable:YES];
            
            _imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop;
            _collectionViewContstraintHeight.constant = self.frame.size.height - imageCropViewOriginalConstraintTop - _imageCropViewContainer.frame.size.height;
            
            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self layoutIfNeeded];
                             } completion:nil];
            
            _dragDirection = DirectionUp;
        }
    }
}

#pragma mark - UICollectionViewDataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (_images) ? _images.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    EGLibraryCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EGLibraryCell" forIndexPath:indexPath];
    NSUInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset* asset = self.images[indexPath.item];
    
    switch (_assetType) {
        case EGAssetTypeImage: {
            
            [self.imageManager requestImageForAsset:asset
                                         targetSize:_cellSize
                                        contentMode:PHImageContentModeAspectFill
                                            options:nil
                                      resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                          if (cell.tag == currentTag) {
                                              cell.thumbnailImage = result;
                                              cell.badgeView.hidden = YES;
                                          }
                                      }];
        }
            break;
            
        case EGAssetTypeVideo: {
            [self.imageManager requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                if ([asset isKindOfClass:[AVURLAsset class]]) {
                    NSURL* url = [(AVURLAsset *)asset URL];
                    NSLog(@"%@", url);
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                        AVAssetImageGenerator* generateImg = [AVAssetImageGenerator assetImageGeneratorWithAsset:(AVURLAsset *)asset];
                        generateImg.appliesPreferredTrackTransform = YES;
                        
                        CMTime time = CMTimeMakeWithSeconds(0.0, 600);
                        __block CGImageRef refImage;
                        
                        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime,
                                                                           CGImageRef im,
                                                                           CMTime actualTime,
                                                                           AVAssetImageGeneratorResult result,
                                                                           NSError *error){
                            refImage = im;
                            UIImage* frameImage = [UIImage imageWithCGImage:refImage];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (cell.tag == currentTag) {
                                    cell.thumbnailImage = frameImage;
                                    cell.badgeView.hidden = NO;
                                }
                            });
                        };
                        
                        generateImg.maximumSize = CGSizeZero;
                        [generateImg generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:time]] completionHandler:handler];
                    });
                }
            }];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat width = (self.collectionView.bounds.size.width - 3) / 4.0f;
    return CGSizeMake(width, width);
}

#pragma mark - UICollectionViewDelegate - 

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self changeImage:_images[indexPath.row]];
    [_imageCropView changeScrollable:YES];
    
    _imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop;
    _collectionViewContstraintHeight.constant = self.frame.size.height - imageCropViewOriginalConstraintTop - _imageCropViewContainer.frame.size.height;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self layoutIfNeeded];
                     } completion:nil];
    
    _dragDirection = DirectionUp;
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

#pragma mark - UIScrollViewDelegate - 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _collectionView) {
        [self updateCachedAssets];
    }
}

#pragma mark - PHPhotoLibraryChangeObserver -

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Check if there are changes to the assets we are showing.
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.images];
    if (collectionChanges == nil) {
        return;
    }
    
    /*
     Change notifications may be made on a background queue. Re-dispatch to the
     main queue before acting on the change as we'll be updating the UI.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the new fetch result.
        self.images = [collectionChanges fetchResultAfterChanges];
        
        UICollectionView *collectionView = self.collectionView;
        
        if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
            // Reload the collection view if the incremental diffs are not available
            [collectionView reloadData];
            
        } else {
            /*
             Tell the collection view to animate insertions and deletions if we
             have incremental diffs.
             */
            [collectionView performBatchUpdates:^{
                NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                if ([removedIndexes count] > 0) {
                    [collectionView deleteItemsAtIndexPaths:[removedIndexes pa_indexPathsFromIndexesWithSection:0]];
                }
                
                NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                if ([insertedIndexes count] > 0) {
                    [collectionView insertItemsAtIndexPaths:[insertedIndexes pa_indexPathsFromIndexesWithSection:0]];
                }
                
                NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                if ([changedIndexes count] > 0) {
                    [collectionView reloadItemsAtIndexPaths:[changedIndexes pa_indexPathsFromIndexesWithSection:0]];
                }
            } completion:NULL];
        }
        
        [self resetCachedAssets];
    });
}

#pragma mark - 

- (void)changeImage:(PHAsset *)asset {
    self.imageCropView.image = nil;
    self.phAsset = asset;
    self.imageCropView.assetType = _assetType;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        
        PHImageRequestOptions* options = [PHImageRequestOptions new];
        options.networkAccessAllowed = YES;
        
        switch (_assetType) {
            case EGAssetTypeImage: {
                [self.imageManager requestImageForAsset:asset
                                             targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                                            contentMode:PHImageContentModeAspectFill
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  self.imageCropView.imageSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
                                                  self.imageCropView.image = result;
                                              });
                                          }];
            }
                break;
                
            case EGAssetTypeVideo: {
                [self.imageManager requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    if ([asset isKindOfClass:[AVURLAsset class]]) {
                        NSURL* url = [(AVURLAsset *)asset URL];
                        NSLog(@"%@", url);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.imageCropView.videoURL = url;
                            [self.imageCropView setupVideoPlayer];
                        });
                    }
                }];
            }
                break;
                
            default:
                break;
        }
    });
}

- (void)checkAuth {
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized:
                self.imageManager = [PHCachingImageManager new];
                if (self.images && self.images.count > 0) {
                    [self changeImage:self.images[0]];
                }
                break;
            case PHAuthorizationStatusDenied: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([_delegate respondsToSelector:@selector(albumUnauthorized)]) {
                        [_delegate albumUnauthorized];
                    }
                });
            }
                break;
            
            case PHAuthorizationStatusRestricted: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([_delegate respondsToSelector:@selector(albumUnauthorized)]) {
                        [_delegate albumUnauthorized];
                    }
                });
            }
                break;
                
            default:
                break;
        }
    }];
}

- (void)updateCachedAssets {
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 5.f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView pa_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView pa_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:_cellSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:_cellSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.images[indexPath.item];
        [assets addObject:asset];
    }
    
    return assets;
}

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    _previousPreheatRect = CGRectZero;
}

@end
