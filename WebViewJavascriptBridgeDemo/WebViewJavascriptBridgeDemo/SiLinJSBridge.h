//
//  SiLinJSBridge.h
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/8/22.
//  Copyright © 2016年 CY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>
#import <MMSheetView.h>
#import "NSURLProtocolCustom.h"
#import <CommonCrypto/CommonDigest.h>

//首先创建一个实现了JSExport协议的协议
@protocol SiLinJSObjectProtocol <JSExport>

-(void)chooseImageWithType:(JSValue *)type callback:(JSValue *)callback;

-(void)previewImage:(JSValue *)imageUrl;

-(CGFloat)keyboardHeight;

@end


@interface SiLinJSBridge : NSObject < SiLinJSObjectProtocol, UINavigationControllerDelegate, UIImagePickerControllerDelegate >

@property (nonatomic, weak) JSContext *jsContext;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) UINavigationController *navigationController;


@end
