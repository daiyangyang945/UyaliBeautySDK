//
//  DYYView.m
//  OpenGLES-Study
//
//  Created by S weet on 2023/1/6.
//

#import "DYYView.h"
#import <OpenGLES/ES2/gl.h>
#import <AVKit/AVKit.h>

@interface DYYView ()

//正对于OpenGL ES图层渲染--父类CALayer
@property (nonatomic, strong)CAEAGLLayer *myEaglLayer;

@property (nonatomic, strong)EAGLContext *context;

//帧缓冲区
@property (nonatomic, assign)GLuint myColorRenderBuffer;
@property (nonatomic, assign)GLuint myColorFrameBuffer;

@property (nonatomic, assign)GLuint myProgram;

@end

@implementation DYYView

/*
不采用GLKit--GLBaseEffect，使用编译链接自定义的着色器.GLSL语言
 思路：
 1、创建涂层
 2、创建上下文
 3、清空缓存区
 4、设置RenderBuffer
 5、设置FrameBuffer
 6、开始绘制
*/
- (void)layoutSubviews {
    //创建/设置图层
    [self setupLayer];
    //创建/设置图形上下文
    [self setupContext];
    //清空缓冲区
    [self deleteFrameAndRenderBuffer];
    //设置RenderBuffer
    [self setupRenderBuffer];
    //设置FrameBuffer
    [self setupFrameBuffer];
    //渲染
//    [self renderLayer];
}

//1、创建/设置图层
- (void)setupLayer {
    self.myEaglLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    //CALayer默认透明，必须将其设置为不透明
    self.myEaglLayer.opaque = YES;
    //颜色+深度..参数
    /*
     属性：kEAGLDrawablePropertyRetainedBacking 表示绘图表面显示后，是否保留其内容。这个key的值，是一个通过NSNumber包装的bool值。如果是false，则显示内容后不能依赖于相同的内容，ture表示显示后内容不变。一般只有在需要内容保存不变的情况下，才建议设置使用,因为会导致性能降低、内存使用量增减。一般设置为flase.
     
     kEAGLDrawablePropertyColorFormat
              可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
              kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
              kEAGLColorFormatRGB565：16位RGB的颜色，
              kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     */
    self.myEaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
}

+(Class)layerClass {
    return [CAEAGLLayer class];
}

//2.创建/设置图形上下文
- (void)setupContext {
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (context == nil) {
        NSLog(@"Failed to create Context");
        exit(0);
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set current Context Failed");
        exit(0);
    }
    _context = context;
}

//3.清空缓冲区
- (void)deleteFrameAndRenderBuffer {
    /*
     FrameBuffer-->帧缓冲区
     RenderBuffer-->渲染缓冲区
     */
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

//4.设置RenderBuffer
- (void)setupRenderBuffer {
    GLuint buffer;//定义缓存区标记
    glGenRenderbuffers(1, &buffer);//根据标记分配空间
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEaglLayer];
    _myColorRenderBuffer = buffer;
    
}

//5.设置FrameBuffer
- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    glBindFramebuffer(GL_FRAMEBUFFER, buffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _myColorRenderBuffer);
    _myColorFrameBuffer = buffer;
    
}

//6.绘制
- (void)display:(GLuint)texture {
    //顶点/片元着色器
    
    //设置清屏颜色
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //设置窗口大小
    CGFloat scale = [UIScreen mainScreen].scale;
    glViewport(self.frame.origin.x*scale, self.frame.origin.y*scale, self.frame.size.width*scale, self.frame.size.height*scale);
    
    //读取顶点/片元着色器程序
    NSString *vertexFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragmentFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];
    
    //加载shader(实现编译/链接shader)
    self.myProgram = [self loadShaders:vertexFile withFragment:fragmentFile];
    
    //链接program
    glLinkProgram(self.myProgram);
    //在链接过程中有可能发生错误，获取错误信息
    GLint linkStatus;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[1024];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        //将C语言字符串转换为OC字符串
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }
    NSLog(@"Program Link success");
    
    //使用Program
    glUseProgram(self.myProgram);
    
    NSString *imageURL = [[NSBundle mainBundle]pathForResource:@"opengles" ofType:@"jpeg"];
    UIImage *img = [UIImage imageWithContentsOfFile:imageURL];
    
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect(img.size, self.bounds);
    CGFloat widthRatio = realRect.size.width/self.bounds.size.width;
    CGFloat heightRatio = realRect.size.height/self.bounds.size.height;
    
    //图片坐标[-1,1]
    GLfloat attrArr[] = {
        //x,y,z s,t
        widthRatio,-heightRatio, 0.0,  1.0,1.0,//右下
        widthRatio, heightRatio, 0.0,  1.0,0.0,//右上
       -widthRatio, heightRatio, 0.0,  0.0,0.0,//左上
        widthRatio,-heightRatio, 0.0,  1.0,1.0,//右下
       -widthRatio, heightRatio, 0.0,  0.0,0.0,//左上
       -widthRatio,-heightRatio, 0.0,  0.0,1.0 //左下
    };
    
    //处理顶点数据
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    //处理纹理数据
    GLuint texCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    glEnableVertexAttribArray(texCoor);
    glVertexAttribPointer(texCoor, 2, GL_FLOAT, false, sizeof(GLfloat)*5, (GLfloat *)NULL + 3);
    
    //加载纹理
    [self setupTexture:imageURL];
    
    //旋转
//    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
//    GLfloat mMatrix[16] = {
//        1.0, 0.0, 0.0, 0.0,
//        0.0, 1.0, 0.0, 0.0,
//        0.0, 0.0, 1.0, 0.0,
//        0.0, 0.0, 0.0, 1.0
//    };
//    if (imgWidth/imgHeight > width/height) {
//        GLfloat ratio = imgHeight/height;
//        [self loadOrthoMatrix:(GLfloat *)&mMatrix left:-1 right:1 bottom:-ratio top:ratio near:-1 far:-1];
//    } else {
//        GLfloat ratio = imgWidth/width;
//        [self loadOrthoMatrix:(GLfloat *)&mMatrix left:-ratio right:ratio bottom:-1 top:1 near:-1 far:-1];
//    }
//    glUniformMatrix4fv(rotate, 1, GL_FALSE, &mMatrix[0]);
//    float radians = 10 * 3.1415926/180.f;
//    float s = sinf(radians);
//    float c = cosf(radians);
//    //围绕Z轴
//    GLfloat zRotation[16] = {
//        c,-s,0,0,
//        s,c,0,0,
//        0,0,1,0,
//        0,0,0,1
//    };
//    glUniformMatrix4fv(rotate, 1, GL_FALSE, &zRotation[0]);
//    orthoM
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Texture
- (GLuint)setupTexture:(NSString *)fileName {
    //获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image:%@",fileName);
        exit(0);
    }
    
    //读取图片的宽高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //获取图片的存储的字节数 = 宽*高*4(RGBA)
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    
    //创建上下文
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    //绘制图片
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    CGContextRelease(spriteContext);
    
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //设置纹理的属性
    //放大过滤/缩小过滤
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //载入纹理
    float fw = width,fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    glBindBuffer(GL_TEXTURE_2D, 0);
    free(spriteData);
    return 0;
}

#pragma mark - shader
//加载shader
- (GLuint)loadShaders:(NSString *)vertex withFragment:(NSString *)fragment {
    //定义临时变量
    GLuint vertShader,fragShader;
    GLint program = glCreateProgram();
    
    //编译顶点/片元着色器
    [self complieShader:&vertShader type:GL_VERTEX_SHADER file:vertex];
    [self complieShader:&fragShader type:GL_FRAGMENT_SHADER file:fragment];
    
    //创建
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    
    //获取路径 将OC字符串转换为C语言字符串
    return program;
}

- (void)complieShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取文件路径
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //创建shader
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上。
        //参数1：shader,要编译的着色器对象 *shader
        //参数2：numOfStrings,传递的源码字符串数量 1个
        //参数3：strings,着色器程序的源码（真正的着色器程序源码）
        //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
}

#pragma mark - 正交投影
- (void)loadOrthoMatrix:(GLfloat *)matrix left:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top near:(GLfloat)near far:(GLfloat)far;
{
    GLfloat r_l = right - left;
    GLfloat t_b = top - bottom;
    GLfloat f_n = far - near;
    GLfloat tx = - (right + left) / (right - left);
    GLfloat ty = - (top + bottom) / (top - bottom);
    GLfloat tz = - (far + near) / (far - near);
    
    float scale = 2.0f;
//    if (_anchorTopLeft)
//    {
//        scale = 4.0f;
//        tx=-1.0f;
//        ty=-1.0f;
//    }
    
    matrix[0] = scale / r_l;
    matrix[1] = 0.0f;
    matrix[2] = 0.0f;
    matrix[3] = tx;
    
    matrix[4] = 0.0f;
    matrix[5] = scale / t_b;
    matrix[6] = 0.0f;
    matrix[7] = ty;
    
    matrix[8] = 0.0f;
    matrix[9] = 0.0f;
    matrix[10] = scale / f_n;
    matrix[11] = tz;
    
    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = 0.0f;
    matrix[15] = 1.0f;
}

@end
