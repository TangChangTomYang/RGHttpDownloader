//
//  RGHttpDownloader.m
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/9.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "RGHttpDownloader.h"
#import "RGHttpDownloaderFileTool.h"


// 把一些常用路径, 抽取成一个宏
#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTempPath NSTemporaryDirectory()

@interface RGHttpDownloader ()<NSURLSessionDataDelegate>
{
    // 记录文件临时下载的大小
    long long _tempSize;
    // 记录文件总大小
    long long _totalSize;
    
}


/***/
@property(nonatomic, strong)NSURLSession  *session;
/**下载完成路径*/
@property(nonatomic, strong)NSString *downLoadedPath;
/**下载临时路径*/
@property(nonatomic, strong)NSString  *downloadingPath;
/**文件输出流*/
@property(nonatomic, strong)NSOutputStream *outputStream;
/**当前下载任务 -- 用来控制下载 暂停 继续*/
@property(nonatomic, strong)NSURLSessionDataTask *dataTask;



@property(nonatomic, assign)RGDownloaderState state;
@property (nonatomic, assign) float progress;

@property(nonatomic, copy)RGDownloadInfoCallback downloadInfoCallback ;
@property(nonatomic, copy)RGDownloadProgressCallback progressCallback ;
@property(nonatomic, copy)RGDownloadStateChangeCallback stateChangeCallback ;
@end

@implementation RGHttpDownloader
#pragma mark- setter  对外接口
-(RGDownloaderState)downloaderState{
    return self.state;
}
-(float)downloaderProgress{
    return self.progress;
}

-(void)setDownloadInfoCallback:(RGDownloadInfoCallback)downloadInfoCallback{
    _downloadInfoCallback = downloadInfoCallback;
}

-(void)setProgressCallback:(RGDownloadProgressCallback)progressCallback{
    _progressCallback = progressCallback;
}

-(void)setStateChangeCallback:(RGDownloadStateChangeCallback)stateChangeCallback{
    _stateChangeCallback = stateChangeCallback;
}



- (void)downLoader:(NSURL *)url
downLoadInfoCalllback:(RGDownloadInfoCallback)downLoadInfoCalllback
 progressCalllback:(RGDownloadProgressCallback)progressCalllback
stateChangeCallback:(RGDownloadStateChangeCallback)stateChangeCallback {
    
    self.downloadInfoCallback = downLoadInfoCalllback;
    self.progressCallback = progressCalllback;
    self.stateChangeCallback = stateChangeCallback;
    [self downLoaderWithUrl:url];
}


/**
 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作
 @param url 资源路径
 */
- (void)downLoaderWithUrl:(NSURL *)url{
    
    // 当前任务肯定存在
    if([url isEqual:self.dataTask.originalRequest.URL]){
       
        // 判断当前的状态如果是暂停就继续
        if(self.state == RGDownloaderState_Pause){
           
            [self resumeCurrentTask ];
            return;
        }
    }
    
    
    // 任务不存在, 任务存在,但是任务的URL地址不同
    [self cacelCurrentTask];
    
    
    // 获取文件名称, 指明路劲, 开启一个新的下载任务
    NSString *fileName = url.lastPathComponent;
    self.downloadingPath = [kTempPath stringByAppendingString:fileName];
    self.downLoadedPath = [kCachePath stringByAppendingString:fileName];
    
    // 判断, url 对应的资源是否已经下载完毕(下载完成的目录里面是否存在)
    // 告诉外界下载完成, 并且传递相关方信息(本地文件的路劲, 文件的大小)
    if([RGHttpDownloaderFileTool fileExists:self.downLoadedPath]){
        // 告诉外界 已经下载完成
        self.state = RGDownloaderState_Success;
        return;
    }
    
    // 检测临时文件是否存在
    // 不存在, 从0 字节开始下载资源
    if(![RGHttpDownloaderFileTool fileExists:self.downloadingPath]){
        
        // 从0字节开始下载资源
        [self downloadWithUrl:url offset:0];
        return;
    }
    
    
    _tempSize = [RGHttpDownloaderFileTool fileSize:self.downloadingPath];
    [self downloadWithUrl:url offset:_tempSize];
    
}





/**
 暂停任务
 注意:
 - 如果调用了几次继续
 - 调用几次暂停, 才可以暂停
 - 解决方案: 引入状态
 */
- (void)pauseCurrentTask{
    if(self.state == RGDownloaderState_Downloading){
        self.state = RGDownloaderState_Pause;
        [self.dataTask suspend];
    }
}




/**
 继续任务
 - 如果调用了几次暂停, 就要调用几次继续, 才可以继续
 - 解决方案: 引入状态
 */
-(void)resumeCurrentTask{
    if(self.dataTask && self.state == RGDownloaderState_Pause){
       [self.dataTask resume];
        self.state = RGDownloaderState_Downloading;
    }
}

/**
 取消当前任务
 */
-(void)cacelCurrentTask{
    self.state = RGDownloaderState_Pause;
    [self.session invalidateAndCancel];
    self.session = nil;
}

/**
 取消任务, 并清理资源
 */
- (void)cacelAndClean{
    [self cacelCurrentTask];
    [RGHttpDownloaderFileTool removeFile:self.downloadingPath];
}

#pragma mark- NSURLSessionDataDelegate
/**  https  自签名证书就会调用这个方法来确认 是否信任并安装证书
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    if([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]){
       
        NSURLCredential * credential = [NSURLCredential  credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
    else{
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace,nil);
    }
}


/**
 第一次接受到响应的时候调用(响应头, 并没有具体的资源内容)
 通过这个方法, 里面, 系统提供的回调代码块, 可以控制, 是继续请求, 还是取消本次请求
 
 @param session 会话
 @param dataTask 任务
 @param response 响应头信息
 @param completionHandler 系统回调代码块, 通过它可以控制是否继续接收数据
 */
-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(nonnull NSHTTPURLResponse *)response
completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    // 默认情况下请求的文件的真实大小就等于 内容的大小(Content-Length)
    _totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    // 如果在请求时在请求头中设置了请求文件的范围(即 设置了请求的 :@"range"), 那么文件的真实总大小需要在这个Content-Range中,来获取
    if (contentRangeStr.length > 0) {
        _totalSize = [[[contentRangeStr componentsSeparatedByString:@"/"] lastObject] longLongValue];
    }
    
    //传递给外面,文件的总大小
    if(self.downloadInfoCallback){
        self.downloadInfoCallback(_totalSize);
    }
    
    // 对比本地文件大小和文件总大小
    // 检查是否已经下载完毕
    if(_tempSize == _totalSize){
        // 移动到下载完成文件夹
        [RGHttpDownloaderFileTool moveFile:self.downloadingPath toPath:self.downLoadedPath];
        // 取消本地请求
        completionHandler(NSURLSessionResponseCancel);
        
        self.state = RGDownloaderState_Success;
        return;
    }
    
    // 检查是否下载错误
    if (_tempSize > _totalSize) {
        //1. 删除临时文件
        [RGHttpDownloaderFileTool removeFile:self.downloadingPath];
        //2. 取消请求
        completionHandler(NSURLSessionResponseCancel);
        
        //3. 从 0 开始下载
        [self downLoaderWithUrl:response.URL];
        return;
    }
    
    
    self.state = RGDownloaderState_Downloading;
    // 继续下载
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downloadingPath append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);
    
}


/**
 当用户确定, 继续接受数据的时候调用
 
 @param session 会话
 @param dataTask 任务
 @param data 接受到的一段数据
 */
-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data{
    
    _tempSize += data.length;
    self.progress = (1.0 * _tempSize) /_totalSize;
    
    // 将数据写入文件
    [self.outputStream write:data.bytes maxLength:data.length];
    
}


/**
 请求完成时候调用
 请求完成的时候调用( != 请求成功/失败)
 @param session 会话
 @param task 任务
 @param error 错误
 */
-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    
    if (error == nil) {
        // 不一定成功
        // 数据肯定时请求完成了的
        // 判断, 本地缓存 == 文件总大小
        // 判断文件完整性 MD5
        [RGHttpDownloaderFileTool moveFile:self.downloadingPath toPath:self.downLoadedPath];
        self.state = RGDownloaderState_Success;
    }
    else{
        //        NSLog(@"有问题--%zd--%@", error.code, error.localizedDescription);
        // 取消,  断网
        // 999 != 999
        if (-999 == error.code) {
            self.state = RGDownloaderState_Pause;
        }else {
            self.state = RGDownloaderState_Failed;
        }
    }
    
    [self.outputStream close];
    
}




#pragma mark- 私有方法
/** 根据开始字节开始下载资源
 */
-(void)downloadWithUrl:(NSURL *)url offset:(long long)offset{
    // 这个方法可以避免本地缓存造成的网络 请求数据问题
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:0];
    // 通过控制range, 控制请求资源字节区间
    [requestM setValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"range"];
    self.dataTask = [self.session dataTaskWithRequest:requestM];
    [self resumeCurrentTask];
}



#pragma mark- 懒加载
-(NSURLSession *)session{
    if(!_session){
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}


#pragma mark- 事件/ 数据传递

-(void)setState:(RGDownloaderState)state{
    
    if(_state == state){
        return;
    }
    _state = state;
    
    if (self.stateChangeCallback) {
        if (state == RGDownloaderState_Success) {
            self.stateChangeCallback(state, self.downLoadedPath);
            return;
        }
       self.stateChangeCallback(state, nil);
        
    }
     
}


-(void)setProgress:(float)progress{
    _progress = progress;
    if (self.progressCallback) {
        self.progressCallback(progress);
    }
}















@end
