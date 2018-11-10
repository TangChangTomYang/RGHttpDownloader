//
//  RGHttpDownLoaderManager.m
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/10.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "RGHttpDownLoaderManager.h"
#import "RGHttpDownloader.h"
#import <CommonCrypto/CommonDigest.h> // MD5 摘要算法

@interface RGHttpDownLoaderManager ()<NSCopying, NSMutableCopying>


@property(nonatomic, strong)NSMutableDictionary *downLoderInfo;
@end

@implementation RGHttpDownLoaderManager

#pragma mark- 单例
static RGHttpDownLoaderManager *_downloaderMgr = nil;
+(instancetype)shareMgr{
    
    if(!_downloaderMgr){
        _downloaderMgr = [[self alloc] init];
    }
    return _downloaderMgr;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_downloaderMgr) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _downloaderMgr = [super allocWithZone:zone];
        });
    }
    return _downloaderMgr;
}

- (id)copyWithZone:(NSZone *)zone {
    return _downloaderMgr;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _downloaderMgr;
}


#pragma mark- 对外接口
- (void)downLoader:(NSURL *)url
downLoadInfoCalllback:(RGDownloadInfoCallback)downLoadInfoCalllback
 progressCalllback:(RGDownloadProgressCallback)progressCalllback
stateChangeCallback:(RGDownloadStateChangeCallback)stateChangeCallback {
    
    //1. url
    NSString *urlMd5 = [RGHttpDownLoaderManager Md5: url.absoluteString];
    
    //2. 根据URLMD5 , 查找对应的下载器
    RGHttpDownloader *downloader = self.downLoderInfo[urlMd5];
    if(downloader == nil){
        downloader = [[RGHttpDownloader alloc] init];
        self.downLoderInfo[urlMd5] = downloader;
    }
    
    __weak typeof(self) weakSelf = self;
    [downloader downLoader:url
     downLoadInfoCalllback:downLoadInfoCalllback
         progressCalllback:progressCalllback
       stateChangeCallback:^(RGDownloaderState state, NSString *filePath) {
           
           // 如果是成功就需要删除下载器
           if (state == RGDownloaderState_Success) {
               weakSelf.downLoderInfo[urlMd5] = nil;
           }
           
           if (stateChangeCallback) {
               stateChangeCallback(state, filePath);
           }
       }];
     
}


- (void)pauseWithURL:(NSURL *)url{
    //1. url
    NSString *urlMd5 = [RGHttpDownLoaderManager Md5: url.absoluteString];
    
    //2. 根据URLMD5 , 查找对应的下载器
    RGHttpDownloader *downloader = self.downLoderInfo[urlMd5];
    if(downloader){
        [downloader pauseCurrentTask];
    }
    
}
- (void)resumeWithURL:(NSURL *)url{
    //1. url
    NSString *urlMd5 = [RGHttpDownLoaderManager Md5: url.absoluteString];
    
    //2. 根据URLMD5 , 查找对应的下载器
    RGHttpDownloader *downloader = self.downLoderInfo[urlMd5];
    if(downloader){
        [downloader resumeCurrentTask];
    }
}
- (void)cancelWithURL:(NSURL *)url{
    //1. url
    NSString *urlMd5 = [RGHttpDownLoaderManager Md5: url.absoluteString];
    
    //2. 根据URLMD5 , 查找对应的下载器
    RGHttpDownloader *downloader = self.downLoderInfo[urlMd5];
    if(downloader){
        [downloader cacelCurrentTask];
    }
}


- (void)pauseAll{
    
    [self.downLoderInfo.allValues performSelector:@selector(pauseCurrentTask) withObject:nil];
}
- (void)resumeAll{
       [self.downLoderInfo.allValues performSelector:@selector(resumeCurrentTask) withObject:nil];
}


#pragma mark- 懒加载

-(NSMutableDictionary *)downLoderInfo{
    if(!_downLoderInfo  ){
        _downLoderInfo = [NSMutableDictionary dictionary];
    }
    return _downLoderInfo;
}




#pragma mark- 私有方法
+(NSString *)Md5:(NSString *)str{
    const char *bytes = str.UTF8String;
    
    unsigned char md[CC_MD5_DIGEST_LENGTH]; // 定义一个字符数组
    
    // 把C语言的字符串  -->  MD5 C字符串
    CC_MD5(bytes, (CC_LONG)strlen(bytes), md);
    
    //32
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0 ; i < CC_MD5_DIGEST_LENGTH; i++){
        [result appendFormat:@"%02x",md[i]];
    }
    return result;
    
}
@end
