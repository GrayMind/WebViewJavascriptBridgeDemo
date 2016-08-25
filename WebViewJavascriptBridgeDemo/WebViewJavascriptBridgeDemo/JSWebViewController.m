//
//  JSWebViewController.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/7/1.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "JSWebViewController.h"

#import <WebViewJavascriptBridge.h>
#import <MMSheetView.h>
#import "NSURLProtocolCustom.h"


#import <CommonCrypto/CommonDigest.h>
#import <JavaScriptCore/JavaScriptCore.h>


#import "SiLinJSBridge.h"

@interface JSWebViewController ()<UIWebViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic ,strong) UIWebView *webView;

@property WebViewJavascriptBridge* bridge;

@property(nonatomic ,strong) JSContext *context;

@end

@implementation JSWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"reload" style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"call" style:UIBarButtonItemStylePlain target:self action:@selector(callJSMethod)];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    self.webView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64);
    self.webView.scrollView.bounces = NO;
    [self.view addSubview:self.webView];
    
    [NSURLProtocol registerClass:[NSURLProtocolCustom class]];
    
    
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.104:3000/mypa.html"]];
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://csmobile.alipay.com/mypa/chat.htm?scene=app_mypa_robot"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.103:3000/index.html"]];
    [self.webView loadRequest:request];
    
}

-(void)callJSMethod
{
    JSValue *value = self.context[@"area"];
    [value callWithArguments:@[@4]];
}


-(void)reload
{
    [self.webView reload];
}


-(void)photo
{
    
    [MMPopupWindow sharedWindow].touchWildToHide = YES;
    MMSheetViewConfig *sheetConfig = [MMSheetViewConfig globalConfig];
    sheetConfig.defaultTextCancel = @"取消";
    
    MMPopupItemHandler block = ^(NSInteger index){
        if (index == 0)
        {
            // 拍照
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            controller.delegate = self;
            [self presentViewController:controller animated:YES completion:nil];
        }
        else if (index == 1)
        {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            controller.delegate = self;
            [self presentViewController:controller animated:YES completion:nil];
        }
        
    };
    
    MMPopupCompletionBlock completeBlock = ^(MMPopupView *popupView, BOOL finish){
        NSLog(@"animation complete");
    };
    
    NSArray *items =
    @[MMItemMake(@"相册", MMItemTypeNormal, block),
      MMItemMake(@"拍照", MMItemTypeNormal, block)];
    
    [[[MMSheetView alloc] initWithTitle:@"照片选择"
                                  items:items] showWithBlock:completeBlock];
    
}

-(NSString *)imageMD5:(UIImage *)image
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    CC_MD5([imageData bytes], (CC_LONG)[imageData length], result);
    NSString *imageHash = [NSString stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    
    return imageHash;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
    
    // 以 html title 设置 导航栏 title
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    // Undocumented access to UIWebView's JSContext
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
   
    
    
    SiLinJSBridge *call = [[SiLinJSBridge alloc] init];
    //将JSNativeMethod封装到JavaScript函数SiLinJSBridge中
    self.context[@"SiLinJSBridge"] = call;
    call.jsContext = self.context;
    call.viewController = self;
    
    // 打印异常
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"%@", exceptionValue);
    };
    
//    // 以 JSExport 协议关联 native 的方法
//    self.context[@"app"] = self;
//    
//    // 以 block 形式关联 JavaScript function
//    self.context[@"log"] = ^(NSString *str) {
//        NSLog(@"%@", str);
//    };
//    //多参数
//    self.context[@"mutiParams"] = ^(NSString *a,NSString *b,NSString *c) {
//        NSLog(@"%@ %@ %@",a,b,c);
//    };
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"%@",request.URL);
    return YES;
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    UIImageOrientation imageOrientation = portraitImg.imageOrientation;
    
    if(imageOrientation != UIImageOrientationUp)
    {
        // 原始图片可以根据照相时的角度来显示，但UIImage无法判定，于是出现获取的图片会向左转９０度的现象。
        // 以下为调整图片角度的部分
        UIGraphicsBeginImageContext(portraitImg.size);
        [portraitImg drawInRect:CGRectMake(0, 0, portraitImg.size.width, portraitImg.size.height)];
        portraitImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // 调整图片角度完毕
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *imageMD5 = [self imageMD5:portraitImg];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    // 拼接图片名为"currentImage.png"的路径
    NSString *imageFilePath = [path stringByAppendingPathComponent:imageMD5];
    //其中参数0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
    [UIImageJPEGRepresentation(portraitImg, 0.5) writeToFile:imageFilePath  atomically:YES];
    
//    slimage://imagemd5
//    NSString *data = [NSString stringWithFormat:@"slimage://%@",imageMD5];
//    [_bridge callHandler:@"savephoto" data:data responseCallback:^(id response) {
//        NSLog(@"savephoto responded: %@", response);
//    }];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
