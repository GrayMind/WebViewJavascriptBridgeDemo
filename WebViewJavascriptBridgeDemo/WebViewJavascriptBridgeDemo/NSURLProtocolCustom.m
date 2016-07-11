//
//  NSURLProtocolCustom.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/7/11.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "NSURLProtocolCustom.h"

@implementation NSURLProtocolCustom

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // 这里是html 渲染时候入口，来处理自定义标签 如 "xadsdk",若return YES 则会执行接下来的 -startLoading方法
    if ([request.URL.scheme caseInsensitiveCompare:@"slimage"] == NSOrderedSame)
    {
        return YES;
    }
    return NO;
}

+(NSURLRequest*)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

-(void)startLoading
{
    
    NSString *imageMD5 = super.request.URL.host;
    
    // 处理自定义标签 ，并实现内嵌本地资源
    // 当url的scheme是xadsdk开头的，那么加载本地的图片文件并替换,本地的图片在document目录下的test.png
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *path=[docDir stringByAppendingPathComponent:imageMD5];
    
    //根据路径获取MIMEType   （以下函数方法需要添加.h文件的引用，）
    // Get the UTI from the file's extension:
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[path pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    
    // The UTI can be converted to a mime type:
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL)
        CFRelease(type);
    
    // 这里需要用到MIMEType
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:super.request.URL
                                                        MIMEType:mimeType
                                           expectedContentLength:-1
                                                textEncodingName:nil];
    //加载本地资源
    NSData *data = [NSData dataWithContentsOfFile:path];
    //硬编码 开始嵌入本地资源到web中
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
    
}

-(void)stopLoading
{
    NSLog(@"stopLoading, something went wrong!");
}
@end


