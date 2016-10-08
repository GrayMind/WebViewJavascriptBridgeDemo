//
//  SLConfigModel.h
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/10/8.
//  Copyright © 2016年 CY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLConfigModel : NSObject


+(instancetype)shareInstant;


-(NSString *)fetchUrl;

-(void)changeUrl:(NSString *)url;

@end
