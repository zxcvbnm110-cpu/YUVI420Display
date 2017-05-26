//
//  YUVView.h
//  MAC_YUV
//
//  Created by Ruiwen Feng on 2017/5/26.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface YUVView : NSOpenGLView

- (void)displayYUV_I420:(char*)buf width:(GLuint)width height:(GLuint)height;

@end
