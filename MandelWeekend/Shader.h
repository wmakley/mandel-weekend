//
//  Shader.h
//  MandelWeekend
//
//  Created by William Makley on 11/24/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGL/gl3.h>

@interface Shader : NSObject
{
    NSString *_path;
    GLenum _shaderType;
    GLuint _shaderID;
    GLint _compilationResult;
    NSString *_infoLog;
}

- (instancetype)initWithFileName:(NSString*)fileName extension:(NSString *)ext shaderType:(GLenum)type;

- (BOOL)compile;
- (void)deleteShader;

@property (nonatomic, readonly) GLuint shaderID;
@property (nonatomic, readonly) NSString *infoLog;
@property (nonatomic, readonly) NSString *source;

@end
