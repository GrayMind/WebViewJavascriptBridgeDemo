//
//  SLConfigModel.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/10/8.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "SLConfigModel.h"

@interface SLConfigModel ()

@property(nonatomic, copy) NSString *url;

@end

@implementation SLConfigModel

static id instant = nil;

+(instancetype)shareInstant
{
    if (instant == nil) {
        instant = [[SLConfigModel alloc] init];
    }
    return instant;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _url = @"http://192.168.1.112:3000/index.html";
    }
    return self;
}


-(NSString *)fetchUrl
{
    return self.url;
}

-(void)changeUrl:(NSString *)url
{
    self.url = url;
}


@end
