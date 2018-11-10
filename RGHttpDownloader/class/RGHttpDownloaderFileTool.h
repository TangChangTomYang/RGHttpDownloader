//
//  RGHttpDownloaderFileTool.h
//  RGHttpDownloader
//
//  Created by yangrui on 2018/11/10.
//  Copyright © 2018年 yangrui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RGHttpDownloaderFileTool : NSObject

+(BOOL)fileExists:(NSString *)filePath;
+(long long)fileSize:(NSString *)filePath;
+(void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath;
+(void)removeFile:(NSString *)filePath;
@end
