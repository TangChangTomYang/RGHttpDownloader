//
//  RGHttpDownLoaderManager.h
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/10.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RGHttpDownloaderDefine.h"

@interface RGHttpDownLoaderManager : NSObject


+(instancetype)shareMgr;

/**
 参数1:url 下载文件的路径
 参数2:downLoadInfoCalllback,当前文件开始下载的信息, 主要包含文件的总大小 回调, 开始下载时会回调一次
 参数3:progressCalllback, 当前文件的下载进度回调, 会多次回调
 参数4:stateChangeCallback,当前文件下载状态变化的回调, 可能调多次, 只有成功时才会有 目标文件的 路劲
 */
- (void)downLoader:(NSURL *)url
downLoadInfoCalllback:(RGDownloadInfoCallback)downLoadInfoCalllback
 progressCalllback:(RGDownloadProgressCallback)progressCalllback
stateChangeCallback:(RGDownloadStateChangeCallback)stateChangeCallback ;


- (void)pauseWithURL:(NSURL *)url;
- (void)resumeWithURL:(NSURL *)url;
- (void)cancelWithURL:(NSURL *)url;


- (void)pauseAll;
- (void)resumeAll;

@end
