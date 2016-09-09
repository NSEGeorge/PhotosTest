//
//  PhotosVC.m
//  Photos
//
//  Created by Georgij on 06.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "PhotosVC.h"
#import "UICollectionView+Convenience.h"
#import "NSIndexSet+Convenience.h"
#import "EGLibraryPhotosVC.h"
@import Photos;

@interface PhotosVC () <EGLibraryPhotosVCDelegate>

@property (weak, nonatomic) IBOutlet UIView* cameraCaptureArea;
@property (weak, nonatomic) IBOutlet UIImageView* imageView;

@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureStillImageOutput* stillImageOutput;

@end

@implementation PhotosVC

- (IBAction)showBtnWasTapped:(id)sender {
    
    EGLibraryPhotosVC* vc = [EGLibraryPhotosVC new];
    vc.delegate = self;
    vc.assetType = EGAssetTypeImage;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

//-(void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - LibraryVCDelegate -

- (void)closePhotosVCWithImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)closePhotosVCWithVideoSnapshot:(UIImage *)image andVideoURL:(NSURL *)videoURL {
    self.imageView.image = image;
}

/////////////

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.session = [[AVCaptureSession alloc] init];
//    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
//    
//    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    NSError *error;
//    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
//    
//    if ([self.session canAddInput:deviceInput]) {
//        [self.session addInput:deviceInput];
//    }
//    
//    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
//    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//    CALayer *rootLayer = [self.view layer];
//    [rootLayer setMasksToBounds:YES];
//    CGRect frame = self.cameraCaptureArea.frame;
//    [previewLayer setFrame:frame];
//    [rootLayer insertSublayer:previewLayer atIndex:0];
//    
//    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
//    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
//    [self.stillImageOutput setOutputSettings:outputSettings];
//    
//    [self.session addOutput:self.stillImageOutput];
//    
//    [self.session startRunning];
}

- (IBAction)takePhoto:(UIButton *)sender {
//    AVCaptureConnection *videoConnection = nil;
//    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
//        for (AVCaptureInputPort *port in [connection inputPorts]) {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection) {
//            break;
//        }
//    }
//    
//    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//        if (imageDataSampleBuffer) {
//            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//            UIImage *image = [UIImage imageWithData:imageData];
//            self.imageView.image = image;
//        }
//    }];
}



@end
