//
//  JSWebViewController.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/7/1.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "JSWebViewController.h"
#import "JSWebConfigViewController.h"

#import <WebViewJavascriptBridge.h>
#import <MMSheetView.h>
#import "NSURLProtocolCustom.h"


#import <CommonCrypto/CommonDigest.h>
#import <JavaScriptCore/JavaScriptCore.h>


#import "SLConfigModel.h"
#import "SiLinJSBridge.h"

#import "SLWebTitleView.h"

@interface JSWebViewController ()< UIWebViewDelegate >

@property(nonatomic ,strong) UIWebView *webView;

@property WebViewJavascriptBridge* bridge;

@property(nonatomic ,strong) JSContext *context;

@property(nonatomic ,assign) long long lastChangeTime;


@property(nonatomic ,strong) SLWebTitleView *titleView;

@end

@implementation JSWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"reload" style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"url" style:UIBarButtonItemStylePlain target:self action:@selector(configUrl)];
    
    
    self.titleView = [[SLWebTitleView alloc] init];
    self.titleView.frame = CGRectMake(0, 0, 35, 20);
    self.navigationItem.titleView = self.titleView;
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    self.webView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64);
    self.webView.scrollView.bounces = NO;
    [self.view addSubview:self.webView];
    
    [NSURLProtocol registerClass:[NSURLProtocolCustom class]];
    
    
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.104:3000/mypa.html"]];
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://csmobile.alipay.com/mypa/chat.htm?scene=app_mypa_robot"]];
    
    NSString *url = [[SLConfigModel shareInstant] fetchUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
    
    self.lastChangeTime = 0;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardDidShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.titleView.showLoading = NO;
//    });
}

#pragma mark -

-(void)configUrl
{
    JSWebConfigViewController *vc = [[JSWebConfigViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)reload
{
    
//    self.titleView.showLoading = !self.titleView.showLoading;
//    return;
    
    NSString *url = [[SLConfigModel shareInstant] fetchUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
    
//    [self.webView reload];
}

#pragma mark -
-(void)keyboardShow:(NSNotification *)noti
{
//    NSLog(@"keyboardShow:\n %@", noti);
    if (self.webView.frame.size.height == self.view.bounds.size.height- 64 - 302) {
        return;
    }
    
    self.webView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height- 64 - 302);

}
-(void)keyboardHidden:(NSNotification *)noti
{
//    NSLog(@"keyboardHidden:\n %@", noti);
    self.webView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height- 64);
}
-(void)keyboardFrameChange:(NSNotification *)noti
{
//    NSLog(@"keyboardFrameChange:\n %@", noti);
    NSDictionary *userInfo = noti.userInfo;
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect endUserInfoKey = [aValue CGRectValue];
    CGFloat y = endUserInfoKey.origin.y;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.webView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height- 64 - (self.view.bounds.size.height - y ));
    }];
    
}


-(long long)getDateTimeToMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    NSLog(@"转换的时间戳=%f",interval);
    long long totalMilliseconds = interval * 1000 ;
    NSLog(@"totalMilliseconds=%llu",totalMilliseconds);
    return totalMilliseconds;
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
    
    // 以 html title 设置 导航栏 title
//    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.titleView.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    
    // Undocumented access to UIWebView's JSContext
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
       
    SiLinJSBridge *call = [[SiLinJSBridge alloc] init];
    //将JSNativeMethod封装到JavaScript函数SiLinJSBridge中
    self.context[@"SiLinJSBridge"] = call;
    call.jsContext = self.context;
    call.viewController = self;
    call.navigationController = self.navigationController;
    call.titleView = self.titleView;
    // 打印异常
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
//        context.exception = exceptionValue;
        NSLog(@"%@", exceptionValue);
    };
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"%@",request.URL);
    return YES;
}




@end
