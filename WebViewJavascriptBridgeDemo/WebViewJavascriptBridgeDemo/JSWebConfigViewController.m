//
//  JSWebConfigViewController.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/10/8.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "JSWebConfigViewController.h"

#import "SLConfigModel.h"

@interface JSWebConfigViewController ()

@property(nonatomic ,strong) UITextField *urlField;
@property(nonatomic ,strong) UIButton *submitBtn;

@end

@implementation JSWebConfigViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"修改url";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.urlField = [[UITextField alloc] init];
    self.urlField.frame = CGRectMake(10, 80, [UIScreen mainScreen].bounds.size.width - 20, 50);
    self.urlField.layer.borderColor = [UIColor blueColor].CGColor;
    self.urlField.layer.borderWidth = 1;
    
    self.submitBtn = [[UIButton alloc] init];
    [self.submitBtn setTitle:@"ok" forState:UIControlStateNormal];
    [self.submitBtn addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside];
    self.submitBtn.frame = CGRectMake(50, 160, [UIScreen mainScreen].bounds.size.width - 100, 50);
    [self.submitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.view addSubview:self.urlField];
    [self.view addSubview:self.submitBtn];
    
}

-(void)submit
{
    NSString *theURL = [self.urlField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (theURL.length == 0)
    {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"http://%@:3000/index.html", theURL];
    [[SLConfigModel shareInstant] changeUrl:url];
    
    
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"完成" message:url delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alter show];
}


@end
