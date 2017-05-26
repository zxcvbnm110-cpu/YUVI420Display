//
//  YUVView.m
//  MAC_YUV
//
//  Created by Ruiwen Feng on 2017/5/26.
//  Copyright © 2017年 Ruiwen Feng. All rights reserved.
//

#import "YUVView.h"
#import <OpenGL/gl3.h>

@interface YUVView ()
{
    CVDisplayLinkRef displayLink;
    GLuint m_progrom;
    GLuint m_VAO;
    GLuint _texture_YUV[3];    //纹理数组。 分别用来存放Y,U,V
}
@end

@implementation YUVView


- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSOpenGLPixelFormatAttribute attrs[] =
        {
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAOpenGLProfile,
            NSOpenGLProfileVersion3_2Core,
        };
        
        NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
        [self setPixelFormat:pf];
        [self setOpenGLContext:context];
    }
    return self;
}


- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
{
    @autoreleasepool {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self drawView];
        });
    }
    return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    CVReturn result = [(__bridge YUVView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}


- (void)prepareOpenGL {
    
    [super prepareOpenGL];
    
    //设置opengl
    
    [[self openGLContext] makeCurrentContext];
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    [self setupOpenGL];

    
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
    
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    CVDisplayLinkStart(displayLink);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
}

- (void)windowWillClose:(NSNotification*)notification
{
    CVDisplayLinkStop(displayLink);
}


- (void)setupOpenGL {
    NSString* vertexPath = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    NSString* fragmentPath = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    [self textureSetup];
    [self compileVertexSource:vertexPath withFragmentSource:fragmentPath];
    [self setupVAO];
}

- (void)textureSetup {
    
    //YUV三个位置。
    int Y = 0,U = 1,V = 2;
    
    if (_texture_YUV)//如果存在先删除。
    {
        glDeleteTextures(3, _texture_YUV);
    }
    
    //创建纹理
    glGenTextures(3, _texture_YUV);
    
    if (!_texture_YUV[Y] || !_texture_YUV[U] || !_texture_YUV[V])
    {
        NSLog(@"glGenTextures faild.");
        return;
    }
    
    //分别对Y,U,V进行设置。
    
    //Y
    //glActiveTexture:选择可以由纹理函数进行修改的当前纹理单位
    //并绑定
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture_YUV[Y]);
    //纹理过滤
    //GL_LINEAR 线性取平均值纹素，GL_NEAREST 取最近点的纹素
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);//放大过滤。
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);//缩小过滤
    //纹理包装
    //包装模式有：GL_REPEAT重复，GL_CLAMP_TO_EDGE采样纹理边缘，GL_MIRRORED_REPEAT镜像重复纹理。
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);//纹理超过S轴
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);//纹理超过T轴
    
    //U
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture_YUV[U]);
    //纹理过滤
    //GL_LINEAR 线性取平均值纹素，GL_NEAREST 取最近点的纹素
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);//放大过滤。
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);//缩小过滤
    //纹理包装
    //包装模式有：GL_REPEAT重复，GL_CLAMP_TO_EDGE采样纹理边缘，GL_MIRRORED_REPEAT镜像重复纹理。
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);//纹理超过S轴
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);//纹理超过T轴
    
    //V
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _texture_YUV[V]);
    //纹理过滤
    //GL_LINEAR 线性取平均值纹素，GL_NEAREST 取最近点的纹素
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);//放大过滤。
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);//缩小过滤
    //纹理包装
    //包装模式有：GL_REPEAT重复，GL_CLAMP_TO_EDGE采样纹理边缘，GL_MIRRORED_REPEAT镜像重复纹理。
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);//纹理超过S轴
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);//纹理超过T轴
}

- (void)setupVAO {
    
    //前三位存postion，后三位存texCoord
    GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f, 1.0f, 1.0f,
        1.0f,  1.0f, 0.0f, 0.0f, 0.0f,
        -1.0f,  1.0f, 0.0f, 1.0f, 0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 0.0f, 1.0f,
        1.0f,  1.0f, 0.0f, 0.0f, 0.0f
    };
    GLuint VBO;
    glGenVertexArrays(1, &m_VAO);
    glGenBuffers(1, &VBO);
    glBindVertexArray(m_VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    GLuint position = glGetAttribLocation(m_progrom, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (GLvoid*)0);
    glEnableVertexAttribArray(position);
    GLuint texCoord = glGetAttribLocation(m_progrom, "texCoord");
    glVertexAttribPointer(texCoord, 2, GL_FLOAT,GL_FALSE, 5 * sizeof(GLfloat), (GLvoid*)(3 * sizeof(GLfloat)));
    glEnableVertexAttribArray(texCoord);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    
}


- (void)compileVertexSource:(NSString*)vertexPath
         withFragmentSource:(NSString*)fragmentPath
{
    GLint logLength, status;
    
    float  glLanguageVersion;
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
    
    
    m_progrom = glCreateProgram();
    
    NSString* vertexContent = [NSString stringWithContentsOfFile:vertexPath encoding:NSUTF8StringEncoding error:nil];
    const GLchar* vertexSource = (GLchar *)[vertexContent UTF8String];
    
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1,&vertexSource, NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0)
    {
        GLchar *log = (GLchar*) malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        NSLog(@"Vtx Shader compile log:%s\n", log);
        free(log);
    }
    
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to compile vtx shader:\n%s\n", vertexSource);
        return ;
    }
    
    glAttachShader(m_progrom, vertexShader);
    glDeleteShader(vertexShader);
    
    
    NSString* fragmentcontent = [NSString stringWithContentsOfFile:fragmentPath encoding:NSUTF8StringEncoding error:nil];
    const GLchar* fragmentSource = (GLchar *)[fragmentcontent UTF8String];
    
    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1,&fragmentSource, NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(fragShader, logLength, &logLength, log);
        NSLog(@"Frag Shader compile log:\n%s\n", log);
        free(log);
    }
    
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to compile frag shader:\n%s\n", fragmentSource);
        return ;
    }
    
    
    glAttachShader(m_progrom, fragShader);
    glDeleteShader(fragShader);
    
    
    glLinkProgram(m_progrom);
    glGetProgramiv(m_progrom, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(m_progrom, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s\n", log);
        free(log);
    }
    
    glGetProgramiv(m_progrom, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to link program");
        return ;
    }
    
    glValidateProgram(m_progrom);
    
    glGetProgramiv(m_progrom, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Program cannot run with current OpenGL State");
    }
    
    glGetProgramiv(m_progrom, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(m_progrom, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s\n", log);
        free(log);
    }
    
    glUseProgram(m_progrom);
    
    
    //    //从片元着色器中获取到Y,U,V变量。
    GLuint textureUniformY = glGetUniformLocation(m_progrom, "SamplerY");
    GLuint textureUniformU = glGetUniformLocation(m_progrom, "SamplerU");
    GLuint textureUniformV = glGetUniformLocation(m_progrom, "SamplerV");
    //    //分别设置为0，1，2.
    glUniform1i(textureUniformY, 0);
    glUniform1i(textureUniformU, 1);
    glUniform1i(textureUniformV, 2);
    
}

- (void)displayYUV_I420:(char*)buf width:(GLuint)width height:(GLuint)height {
    glBindTexture(GL_TEXTURE_2D, _texture_YUV[0]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED,width,height, 0,
                 GL_RED, GL_UNSIGNED_BYTE, buf);
    glBindTexture(GL_TEXTURE_2D, _texture_YUV[1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED , width/2 , height/2 , 0,
                 GL_RED, GL_UNSIGNED_BYTE,buf+width*height);
    glBindTexture(GL_TEXTURE_2D,  _texture_YUV[2]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, width/2, height/2, 0,
                 GL_RED, GL_UNSIGNED_BYTE, buf+(width*height)*5/4);
}

- (void)render {
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(m_progrom);
    glBindVertexArray(m_VAO);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindVertexArray(0);
}

- (void) drawView
{
    [[self openGLContext] makeCurrentContext];
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [self render];
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


- (void)resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
    glViewport(0,0, width, height);
}

- (void)reshape
{
    [super reshape];
    CGLLockContext([[self openGLContext] CGLContextObj]);
    NSRect viewRectPoints = [self bounds];
    NSRect viewRectPixels = viewRectPoints;
    [self resizeWithWidth:viewRectPixels.size.width
                     AndHeight:viewRectPixels.size.height];
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)renewGState
{
    [[self window] disableScreenUpdatesUntilFlush];
    [super renewGState];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawView];
}

- (void)dealloc
{
    glDeleteTextures(3,_texture_YUV);
    [self destroyVAO:m_VAO];
    glDeleteProgram(m_progrom);
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
}


-(void)destroyVAO:(GLuint) vaoName
{
    GLuint index;
    GLuint bufName;
    glBindVertexArray(vaoName);
    for(index = 0; index < 16; index++)
    {
        glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
        if(bufName)
        {
            glDeleteBuffers(1, &bufName);
        }
    }
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
    if(bufName)
    {
        glDeleteBuffers(1, &bufName);
    }
    glDeleteVertexArrays(1, &vaoName);
    
}

@end
