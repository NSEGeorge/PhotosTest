//
//  EGImageCropView.m
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "EGImageCropView.h"
#import "VideoPlayer.h"

@interface EGImageCropView() <UIScrollViewDelegate, VideoPlayerDelegate>

@property (strong, nonatomic) UIImageView* imageView;
@property (strong, nonatomic) VideoPlayer* videoPlayer;

@end

@implementation EGImageCropView

- (void)changeScrollable:(BOOL)isScrollable {
    self.scrollEnabled = isScrollable;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        self.imageView = [UIImageView new];
        
        self.backgroundColor = [UIColor colorWithRed:33.f/255.f green:33.f/225.f blue:33.f/255.f alpha:1.0];
//        self.frame.size = CGSizeMake(0, 0);
        self.clipsToBounds = YES;
        self.imageView.alpha = 0.0;
        
        self.imageView.frame = CGRectMake(0.0, 0.0, 0.0, 0.0);
        
        self.maximumZoomScale = 2.0;
        self.minimumZoomScale = 0.8;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.bounces = YES;
        
        self.delegate = self;
    }
    
    return self;
}

- (void)setupVideoPlayer {
    
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.videoPlayer = [[VideoPlayer alloc] instance];
    self.videoPlayer.delegate = self;
    self.videoPlayer.videoURL = self.videoURL;
    self.videoPlayer.endAction = VideoPlayerEndActionLoop;
    
    [self.videoPlayer setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    
    [self addSubview:self.videoPlayer];
    
    [self.videoPlayer playVideo];
}

#pragma mark - VideoPlayerDelegate -

- (void)videoPlayer:(VideoPlayer *)videoPlayer changedState:(VideoPlayerState)state {
    
}

- (void)videoPlayer:(VideoPlayer *)videoPlayer encounteredError:(NSError *)error {
    
}

#pragma mark - UIScrollViewDelegate -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    switch (_assetType) {
        case EGAssetTypeImage:
            return self.imageView;
        case EGAssetTypeVideo:
            return self.videoPlayer;
        default:
            break;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    CGSize boundsSize = scrollView.bounds.size;
    CGRect contentsFrame;
    
    switch (_assetType) {
        case EGAssetTypeImage:
            contentsFrame = self.imageView.frame;
            break;
        case EGAssetTypeVideo:
            contentsFrame = self.videoPlayer.frame;
            break;
        default:
            break;
    }
    
    if (contentsFrame.size.width < boundsSize.width) {
        
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0;
        
    } else {
        contentsFrame.origin.x = 0.0;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0;
    } else {
        
        contentsFrame.origin.y = 0.0;
    }
    
    self.imageView.frame = contentsFrame;
    self.videoPlayer.frame = contentsFrame;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    
    switch (_assetType) {
        case EGAssetTypeImage:
            self.contentSize = CGSizeMake(self.imageView.frame.size.width + 1, self.imageView.frame.size.height + 1);
            break;
        case EGAssetTypeVideo:
            self.contentSize = CGSizeMake(self.videoPlayer.frame.size.width + 1, self.videoPlayer.frame.size.height + 1);
            break;
            
        default:
            break;
    }
}

- (void)setImage:(UIImage *)image {
    
    if (image) {
        if (![self.imageView isDescendantOfView:self] ) {
            self.imageView.alpha = 1.0;
            [self addSubview:self.imageView];
        }
        
    } else {
        self.imageView.image = nil;
        return;
    }
    
    CGSize imageSize = self.imageSize;
    
    if (imageSize.width < self.frame.size.width || imageSize.height < self.frame.size.height) {
        
        if (imageSize.width > imageSize.height) {
            
            CGFloat ratio = self.frame.size.width / imageSize.width;
            
            [self.imageView setFrame:CGRectMake(0.0, 0.0, self.frame.size.width, imageSize.height * ratio)];
        
            
        } else {
            
            CGFloat ratio = self.frame.size.height / imageSize.height;
            
            [self.imageView setFrame:CGRectMake(0.0, 0.0, imageSize.width * ratio, self.frame.size.height)];
        }
        
        self.imageView.center = self.center;
        
    } else {
        
        if (imageSize.width > imageSize.height) {
            
            CGFloat ratio = self.frame.size.height / imageSize.height;
            
            [self.imageView setFrame:CGRectMake(0.0, 0.0, imageSize.width * ratio, self.frame.size.height)];
            
        } else {
            
            CGFloat ratio = self.frame.size.width / imageSize.width;
            
            [self.imageView setFrame:CGRectMake(0.0, 0.0, self.frame.size.width, imageSize.height * ratio)];
            
        }
        
        self.contentOffset = CGPointMake(self.imageView.center.x - self.center.x,
                                         self.imageView.center.y - self.center.y);
    }
    
    self.contentSize = CGSizeMake(self.imageView.frame.size.width + 1, self.imageView.frame.size.height + 1);
    
    self.imageView.image = image;
    self.zoomScale = 1.0;
}

@end
