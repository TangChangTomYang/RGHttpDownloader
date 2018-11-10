//
//  RGHttpDownloaderFileTool.m
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/10.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import "RGHttpDownloaderFileTool.h"

@implementation RGHttpDownloaderFileTool
+(BOOL)fileExists:(NSString *)filePath{
    if (filePath.length == 0) {
        return NO;
    }
    return  [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+(long long)fileSize:(NSString *)filePath{
    if (![self fileExists:filePath]) {
        return 0;
    }
    
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return  [fileInfo[NSFileSize] longLongValue];
}

+(void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath{
    if (![self fileExists:fromPath]) {
        return ;
    }
    
    [[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:nil];
    
    
}

+(void)removeFile:(NSString *)filePath{
    if (![self fileExists:filePath]) {
        return ;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}
@end
