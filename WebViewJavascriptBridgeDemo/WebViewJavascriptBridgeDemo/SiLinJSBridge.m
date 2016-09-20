//
//  SiLinJSBridge.m
//  WebViewJavascriptBridgeDemo
//
//  Created by CY on 16/8/22.
//  Copyright © 2016年 CY. All rights reserved.
//

#import "SiLinJSBridge.h"

#import <AFNetworking.h>
#import <MWPhotoBrowser.h>

@interface SiLinJSBridge ()<MWPhotoBrowserDelegate>

@property(nonatomic ,strong) JSValue *imageCallback;

@property(nonatomic ,assign) CGFloat keyboardH;

@property(nonatomic ,strong) NSMutableArray *photoArray;

@end


@implementation SiLinJSBridge


#pragma mark - life cycle
-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _keyboardH = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    }
    
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SiLinJSObjectProtocol

-(CGFloat)keyboardHeight
{
    if (_keyboardH != 0) {
        return _keyboardH;
    }
    return 305;
}

/**
 *  选择图片
 *
 *  @param type     0：拍照； 1：相册
 *  @param callback 选择/上传图片回调
 */
-(void)chooseImageWithType:(JSValue *)type callback:(JSValue *)callback
{
    NSInteger t = [type toInt32];
    
    if(!self.imageCallback)
    {
        self.imageCallback = callback;
    }
    
    if (t == 0)
    {
        // 拍照
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        controller.delegate = self;
        [self.viewController presentViewController:controller animated:YES completion:nil];
    }
    else if(t == 1)
    {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        controller.delegate = self;
        [self.viewController presentViewController:controller animated:YES completion:nil];
    }
}

-(void)previewImage:(JSValue *)imageUrl
{
    NSString *image = [imageUrl toString];
    NSURL *url = [NSURL URLWithString:image];
    if ([image hasPrefix:@"slimage://"])
    {
        image = [image stringByReplacingOccurrencesOfString:@"slimage://" withString:@""];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        // 拼接图片路径
        NSString *imageFilePath = [path stringByAppendingPathComponent:image];
        
        url = [NSURL fileURLWithPath:imageFilePath];
    }
    
    self.photoArray = [NSMutableArray array];
    // Add photos
    [self.photoArray addObject:[MWPhoto photoWithURL:url]];
    NSLog(@"previewImage %@", [imageUrl toString]);
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    browser.autoPlayOnAppear = NO; // Auto-play first video
    
    // Customise selection images to change colours if required
    browser.customImageSelectedIconName = @"ImageSelected.png";
    browser.customImageSelectedSmallIconName = @"ImageSelectedSmall.png";
    
    // Optionally set the current visible photo before displaying
    [browser setCurrentPhotoIndex:1];
    
    // Present
    [self.navigationController pushViewController:browser animated:YES];

}


#pragma mark - privace method

// 获取图片 MD5
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

// 上传图片
-(void)uploadImage:(UIImage *)image MD5Url:(NSString *)imgUrl
{
    NSString *url = @"http://121.42.201.123:20091/chime/api/v1/upload";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setValue:@"iOS.1234567890" forHTTPHeaderField:@"X-Client-Id"];
    [manager.requestSerializer setValue:@"dongya" forHTTPHeaderField:@"X-App-Id"];
    [manager.requestSerializer setValue:@"f5e424137912485a15d1447a50669ce6" forHTTPHeaderField:@"X-Token"];

    NSData *imgData = UIImageJPEGRepresentation(image, 0.05);
    
    [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:imgData name:@"pic" fileName:@"image.jpg" mimeType:@"image/png"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
//        CGFloat fractionCompleted = uploadProgress.fractionCompleted;
        NSLog(@"%f", 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
//        NSLog(@"%f", uploadProgress.fractionCompleted);
        NSNumber *prog = [NSNumber numberWithDouble:1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount];
        [self.imageCallback invokeMethod:@"uploadImageProgress" withArguments:@[imgUrl, prog]];
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success :%@", imgUrl);
        [self.imageCallback invokeMethod:@"uploadImageSuccess" withArguments:@[imgUrl]];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"failure :%@", imgUrl);
       
        NSString *errorStr = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSString *errorMessage = @"";
        
        if (![errorStr isEqual: [NSNull null]] && errorStr.length > 0)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:NSJSONReadingMutableLeaves error:nil];
            errorMessage = dic[@"message"];
        }
        NSLog(@"%@", error);
        NSLog(@"%@", errorMessage);
    }];

}



-(void)keyboardWillShow:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect userInfoKey = [aValue CGRectValue];
    _keyboardH = userInfoKey.size.height;
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
    // 拼接图片路径
    NSString *imageFilePath = [path stringByAppendingPathComponent:imageMD5];
    //其中参数0.5表示压缩比例，1表示不压缩，数值越小压缩比例越大
    [UIImageJPEGRepresentation(portraitImg, 0.5) writeToFile:imageFilePath  atomically:YES];
    
    // slimage://imagemd5
    NSString *data = [NSString stringWithFormat:@"slimage://%@",imageMD5];
    //
    [self.imageCallback invokeMethod:@"chooseImageSuccess" withArguments:@[data]];
    [self uploadImage:portraitImg MD5Url:data];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photoArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photoArray.count) {
        return [self.photoArray objectAtIndex:index];
    }
    return nil;
}


@end
