//
//  SiLinJSBridge.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/8/22.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "SiLinJSBridge.h"

@interface SiLinJSBridge ()

@property(nonatomic ,strong) JSValue *imageCallback;

@end


@implementation SiLinJSBridge


-(void)callImage
{
    NSLog(@"callImage");
}

-(void)chooseImageWithType:(JSValue *)type callback:(JSValue *)callback
{
    NSInteger t = [type toInt32];
    NSLog(@"%ld",(long)t);
    self.imageCallback = callback;
    
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
            [self.viewController presentViewController:controller animated:YES completion:nil];
        }
        else if (index == 1)
        {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            controller.delegate = self;
            [self.viewController presentViewController:controller animated:YES completion:nil];
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
    NSString *data = [NSString stringWithFormat:@"slimage://%@",imageMD5];
    
    
    //
    [self.imageCallback invokeMethod:@"chooseImageSuccess" withArguments:@[data]];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
