//
//  VideoPlayer.h
//  CustomVideoPlayer
//
//  Created by Georgij on 16.07.16.
//  Copyright © 2016 Georgii Emeljanow. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, VideoPlayerState) {
    VideoPlayerStateStopped,
    VideoPlayerStateLoading,
    VideoPlayerStatePlaying,
    VideoPlayerStatePaused
};

typedef NS_ENUM(NSUInteger, VideoPlayerEndAction) {
    VideoPlayerEndActionStop,
    VideoPlayerEndActionLoop
};

@protocol VideoPlayerDelegate;

@interface VideoPlayer : UIView

@property (weak, nonatomic) id<VideoPlayerDelegate> delegate;
@property (strong, nonatomic) NSURL* videoURL;
@property (assign, nonatomic) VideoPlayerEndAction endAction;
@property (assign, nonatomic) VideoPlayerState state;
@property (assign, nonatomic) BOOL isMuted;

- (VideoPlayer *)instance;

- (void)playVideo;
- (void)pauseVideo;
- (void)stopVideo;

@end

@protocol VideoPlayerDelegate <NSObject>

- (void)videoPlayer:(VideoPlayer *)videoPlayer changedState:(VideoPlayerState)state;
- (void)videoPlayer:(VideoPlayer *)videoPlayer encounteredError:(NSError *)error;

@end