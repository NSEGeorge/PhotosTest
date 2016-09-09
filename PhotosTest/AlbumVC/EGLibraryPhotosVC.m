//
//  EGLibraryPhotosVC.m
//  Photos
//
//  Created by Georgij on 14.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "EGLibraryPhotosVC.h"
#import "EGGalleryView.h"
#import "EGImageCropView.h"
@import Photos;

@interface EGLibraryPhotosVC () <EGGalleryViewDelegate>

@property (weak, nonatomic) IBOutlet UIView* photoLibraryViewerContainer;

@property (weak, nonatomic) IBOutlet UIView* menuView;

@property (strong, nonatomic) EGGalleryView* albumView;

@end

@implementation EGLibraryPhotosVC

- (void)loadView {
    
    UIView* view = [[[UINib nibWithNibName:@"EGLibraryPhotosVC" bundle:[NSBundle bundleForClass:self.classForCoder]] instantiateWithOwner:self options:nil] firstObject];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.albumView = [[EGGalleryView alloc] instance];
    self.albumView.delegate = self;
    self.albumView.assetType = _assetType;
    
    [_photoLibraryViewerContainer addSubview:self.albumView];
    [self setupMenuBorder];
    [self.view bringSubviewToFront:self.menuView];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.albumView.frame = CGRectMake(0, 0, self.photoLibraryViewerContainer.frame.size.width, self.photoLibraryViewerContainer.frame.size.height);
    [self.albumView layoutIfNeeded];
    [self.albumView initialize];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - AlbumViewDelegate -

- (void)albumUnauthorized {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Доступ к фотоальбому" message:@"Пожалуйста, разрешите доступ к Вашему фотоальбому" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Разрешить" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL* url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Не разрешать" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Actions -

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)checkImage:(id)sender {
    
    EGImageCropView* view = self.albumView.imageCropView;
    
    CGFloat normalizedX = view.contentOffset.x / view.contentSize.width;
    CGFloat normalizedY = view.contentOffset.y / view.contentSize.height;
    
    CGFloat normalizedWidth = view.frame.size.width / view.contentSize.width;
    CGFloat normalizedHeight = view.frame.size.height / view.contentSize.height;
    
    CGRect cropRect = CGRectMake(normalizedX, normalizedY, normalizedWidth, normalizedHeight);
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        PHImageRequestOptions* options = [PHImageRequestOptions new];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        options.normalizedCropRect = cropRect;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        CGFloat targetWidth = floor((CGFloat)self.albumView.phAsset.pixelWidth * cropRect.size.width);
        CGFloat targetHeight = floor((CGFloat)self.albumView.phAsset.pixelHeight * cropRect.size.height);
        CGFloat dimension = MAX(MIN(targetWidth, targetHeight), 1024 * [UIScreen mainScreen].scale);
        
        CGSize targetSize = CGSizeMake(dimension, dimension);
        
        if (view.assetType == EGAssetTypeImage) {
            [[PHImageManager defaultManager] requestImageForAsset:self.albumView.phAsset
                                                       targetSize:targetSize
                                                      contentMode:PHImageContentModeAspectFill
                                                          options:options
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                        
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            
                                                            if ([_delegate respondsToSelector:@selector(closePhotosVCWithImage:)]) {
                                                                [_delegate closePhotosVCWithImage:result];
                                                                [self dismissViewControllerAnimated:YES completion:nil];
                                                            }
                                                        });
                                                    }];
        } else if (view.assetType == EGAssetTypeVideo) {
            [[PHImageManager defaultManager] requestAVAssetForVideo:self.albumView.phAsset
                                                            options:nil
                                                      resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                                          if ([asset isKindOfClass:[AVURLAsset class]]) {
                                                              NSURL* url = [(AVURLAsset *)asset URL];
                                                              NSLog(@"%@", url);
                                                              
                                                              Float64 durationSeconds = CMTimeGetSeconds([asset duration]);
                                                              if (durationSeconds > 30.0) {
                                                                  
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      
                                                                      [self showAlertWithTitle:[NSString stringWithFormat:@"Продолжительность видео: %f секунд", durationSeconds] andMessage:@"Максимальная продолжительность: 30 секунд"];
                                                                  });
                                                                  return;
                                                              }
                                                              
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
                                                                      if ([_delegate respondsToSelector:@selector(closePhotosVCWithVideoSnapshot:andVideoURL:)]) {
                                                                          [_delegate closePhotosVCWithVideoSnapshot:frameImage andVideoURL:url];
                                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }
                                                                  });
                                                              };
                                                              
                                                              generateImg.maximumSize = CGSizeZero;
                                                              [generateImg generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:time]] completionHandler:handler];
                                                          }
                                                      }];
            
        }
    });
}

#pragma mark -
- (void)setupMenuBorder {
    
    CALayer* border = [CALayer new];
    border.borderColor = [UIColor blackColor].CGColor;
    border.frame = CGRectMake(0, self.menuView.frame.size.height - 1.0, self.menuView.frame.size.width, 1.0);
    border.borderWidth = 1.0;
    [self.menuView.layer addSublayer:border];
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
