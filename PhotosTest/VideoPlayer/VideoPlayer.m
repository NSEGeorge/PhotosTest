//
//  VideoPlayer.m
//  CustomVideoPlayer
//
//  Created by Georgij on 16.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import "VideoPlayer.h"
@import AVFoundation;

@interface VideoPlayer()

@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerLayer* playerLayer;

@property (assign, nonatomic) BOOL isLoaded;
@property (assign, nonatomic) BOOL isBufferEmpty;

@end

@implementation VideoPlayer

- (VideoPlayer *)instance {
    
    self.endAction = VideoPlayerEndActionStop;
    self.state = VideoPlayerStateStopped;
    
    return [[[UINib nibWithNibName:@"VideoPlayer" bundle:[NSBundle bundleForClass:self.classForCoder]] instantiateWithOwner:self options:nil] firstObject];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.playerLayer setFrame:self.bounds];
}

- (void)dealloc {
    [self destroyPlayer];
}

#pragma mark - Setup -

- (void)setupPlayer {
    
    if (!self.videoURL) {
        return;
    }
    
    [self destroyPlayer];
    
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:self.videoURL];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [self.player setVolume:[self playerVolume]];
    
    [self addObserves];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    
    [self.player play];
    
    UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    btn.backgroundColor = [UIColor clearColor];
    [btn addTarget:self action:@selector(playBtnWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
    
    [self layoutSubviews];
}

- (void)destroyPlayer {
    [self removeObservers];
    self.player = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    
    [self setStateNotifyingDelegate:VideoPlayerStateStopped];
}

#pragma mark - Notifications -
- (void)playerFailed:(NSNotification *)notification {
    [self destroyPlayer];
    
    if ([_delegate respondsToSelector:@selector(videoPlayer:encounteredError:)]) {
        NSError* error = [NSError errorWithDomain:@"VideoPlayer" code:1 userInfo:@{NSLocalizedDescriptionKey : @"An unknown error occurred"}];
        [_delegate videoPlayer:self encounteredError:error];
    }
}

- (void)playerPlayedToEnd:(NSNotification *)notification {
    switch (self.endAction) {
        case VideoPlayerEndActionStop:
            [self destroyPlayer];
            break;
        case VideoPlayerEndActionLoop:
            [[self.player currentItem] seekToTime:kCMTimeZero];
            break;
        default:
            break;
    }
}

#pragma mark - Observes -

- (void)addObserves {
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:NULL];
    [[self.player currentItem] addObserver:self forKeyPath:@"playbackBufferEmpty" options:0 context:NULL];
    [[self.player currentItem] addObserver:self forKeyPath:@"status" options:0 context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerFailed:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:[self.player currentItem]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerPlayedToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.player currentItem]];
}

- (void)removeObservers {
    
    [self.player removeObserver:self forKeyPath:@"rate"];
    
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - KVO -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([object isEqual:self.player]) {
        if ([keyPath isEqualToString:@"rate"]) {
            CGFloat rate = self.player.rate;
            
            if (!_isLoaded) {
                [self setStateNotifyingDelegate:VideoPlayerStateLoading];
            } else if (rate == 1.0) {
                [self setStateNotifyingDelegate:VideoPlayerStatePlaying];
            } else if (rate == 0.0) {
                
                if (_isBufferEmpty) {
                    [self setStateNotifyingDelegate:VideoPlayerStateLoading];
                } else {
                    [self setStateNotifyingDelegate:VideoPlayerStatePaused];
                }
            }
            
        }
    } else if ([object isEqual:[self.player currentItem]]) {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerItemStatus status = self.player.currentItem.status;
            switch (status) {
                case AVPlayerItemStatusFailed:
                    [self destroyPlayer];
                    
                    if ([_delegate respondsToSelector:@selector(videoPlayer:encounteredError:)]) {
                        [_delegate videoPlayer:self encounteredError:self.player.currentItem.error];
                    }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    self.isLoaded = YES;
                    [self setStateNotifyingDelegate:VideoPlayerStatePlaying];
                    break;
                default:
                    break;
            }
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            BOOL isEmpty = self.player.currentItem.isPlaybackBufferEmpty;
            _isBufferEmpty = isEmpty;
        }
    }
    
}

#pragma mark - Setters & Getters -

- (CGFloat)playerVolume {
    if (_isMuted) {
        return 0.0;
    }
    return 1.0;
}

- (void)setIsMuted:(BOOL)isMuted {
    _isMuted = isMuted;
    [self.player setVolume:[self playerVolume]];
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    [self destroyPlayer];
}

#pragma mark - Actions -

- (void)playBtnWasTapped:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (!sender.isSelected) {
        [self startAnimationForBtnImage:@"play.png"];
        [self playVideo];
    } else {
        [self startAnimationForBtnImage:@"pause.png"];
        [self pauseVideo];
    }
}

- (void)startAnimationForBtnImage:(NSString *)imageName {
    
    UIImageView* btnImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    btnImageView.image = [UIImage imageNamed:imageName];
    btnImageView.center = self.center;
    btnImageView.backgroundColor = [UIColor clearColor];
    
    [self addSubview:btnImageView];
    
    CGAffineTransform scale = CGAffineTransformMakeScale(2.0, 2.0);
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         btnImageView.transform = scale;
                         btnImageView.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [btnImageView removeFromSuperview];
                     }];
}

- (void)playVideo {
    switch (self.state) {
        case VideoPlayerStatePaused:
            [self.player play];
            break;
        case VideoPlayerStateStopped:
            [self setupPlayer];
            break;
            
        default:
            break;
    }
}

- (void)pauseVideo {
    
    if (self.state == VideoPlayerStatePaused || self.state == VideoPlayerStateStopped) {
        return;
    }
    [self.player pause];
}

- (void)stopVideo {
    if (self.state == VideoPlayerStateStopped) {
        return;
    }
    [self destroyPlayer];
}


#pragma mark -

-(void)setStateNotifyingDelegate:(VideoPlayerState)state {
    VideoPlayerState previousState = self.state;
    self.state = state;
    
    if (state != previousState) {
        
        if ([[self delegate] respondsToSelector:@selector(videoPlayer:changedState:)])
            [[self delegate] videoPlayer:self changedState:state];
        
    }
}

@end
