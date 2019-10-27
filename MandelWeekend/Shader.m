//
//  Shader.m
//  MandelWeekend
//
//  Created by William Makley on 11/24/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import "Shader.h"

@implementation Shader

- (instancetype)initWithFileName:(NSString*)fileName
                       extension:(NSString *)extension
//                      shaderType:(GLenum)shaderType
{
    if (self = [super init]) {
//        _shaderID = 0;
//        _path = [[NSBundle mainBundle] pathForResource:fileName
//                                                ofType:extension];
//        _shaderType = shaderType;
//        _compilationResult = GL_FALSE;
    }
    return self;
}
//
//- (BOOL)compile {
//    NSError *error;
//    _source = [NSString stringWithContentsOfFile:_path
//                                        encoding:NSUTF8StringEncoding
//                                           error:&error];
//    if (error) {
//        NSLog(@"Failed to load shader source: %@", error);
//        return NO;
//    }
//    
//    _shaderID = glCreateShader(_shaderType);
////    NSLog(@"Shader ID: %u", _shaderID);
//    GLchar const *srcCString = (GLchar const *)[_source UTF8String];
//    glShaderSource(_shaderID, 1, &srcCString, NULL);
//    glCompileShader(_shaderID);
//    
//    glGetShaderiv(_shaderID, GL_COMPILE_STATUS, &_compilationResult);
////    NSLog(@"Shader compilation result: %d", _compilationResult);
//
//    GLint infoLogLength;
//    glGetShaderiv(_shaderID, GL_INFO_LOG_LENGTH, &infoLogLength);
//    if (infoLogLength > 0) {
//        GLchar infoLog[infoLogLength];
//        glGetShaderInfoLog(_shaderID, infoLogLength, NULL, &infoLog[0]);
//        _infoLog = [NSString stringWithUTF8String:&infoLog[0]];
//        NSLog(@"Shader Info Log: %@", _infoLog);
//    }
//
//    return [self isCompiled];
//}
//
//- (BOOL)isCompiled {
//    return _shaderID != 0 && _compilationResult == GL_TRUE;
//}
//
//- (void)deleteShader {
//    if (_shaderID != 0) {
//        glDeleteShader(_shaderID);
//        _shaderID = 0;
//    }
//}
//
//- (void)dealloc {
//    [self deleteShader];
//}

@end
