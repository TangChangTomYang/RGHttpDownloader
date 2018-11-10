//
//  RGHttpDownloaderDefine.h
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/10.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#ifndef RGHttpDownloaderDefine_h
#define RGHttpDownloaderDefine_h


#endif /* RGHttpDownloaderDefine_h */



#ifdef __OBJC__
typedef NS_ENUM(NSInteger, RGDownloaderState) {
    RGDownloaderState_Pause,
    RGDownloaderState_Downloading,
    RGDownloaderState_Success,
    RGDownloaderState_Failed
};


typedef void(^RGDownloadInfoCallback)(long long totalSize);
typedef void(^RGDownloadProgressCallback)(float progress);
typedef void(^RGDownloadStateChangeCallback)(RGDownloaderState state, NSString *filePath);



#endif
