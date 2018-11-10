//
//  RGHttpDownloader.h
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/9.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RGHttpDownloaderDefine.h"




@interface RGHttpDownloader : NSObject

/**
 当前文件的下载状态
 */
@property(nonatomic, assign, readonly)RGDownloaderState downloaderState;
/**
 当前文件的下载进度
 */
@property (nonatomic, assign,readonly) float downloaderProgress;
/**
 当前文件开始下载的信息, 主要包含文件的总大小 回调, 开始下载时会回调一次
 */
-(void)setDownloadInfoCallback:(RGDownloadInfoCallback)downloadInfoCallback;
/**
 当前文件的下载进度回调, 会多次回调
 */
-(void)setProgressCallback:(RGDownloadProgressCallback)progressCallback;
/**
 当前文件下载状态变化的回调, 可能调多次, 只有成功时才会有 目标文件的 路劲
 */
-(void)setStateChangeCallback:(RGDownloadStateChangeCallback)stateChangeCallback;



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

/**
 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作
 @param url 资源路径
 */
- (void)downLoaderWithUrl:(NSURL *)url;
- (void)resumeCurrentTask;
/**
 暂停任务
 注意:
 - 如果调用了几次继续
 - 调用几次暂停, 才可以暂停
 - 解决方案: 引入状态
 */
- (void)pauseCurrentTask;
/**
 取消任务
 */
- (void)cacelCurrentTask;

/**
 取消任务, 并清理资源
 */
- (void)cacelAndClean;
@end
