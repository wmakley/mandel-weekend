//
//  Shader.h
//  MandelWeekend
//
//  Created by William Makley on 11/24/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Shader : NSObject
{
//    NSString *_path;
//    GLenum _shaderType;
//    GLuint _shaderID;
//    GLint _compilationResult;
//    NSString *_infoLog;
}

- (instancetype)initWithFileName:(NSString*)fileName
                       extension:(NSString *)ext;
//                      shaderType:(GLenum)type;
//
//- (BOOL)compile;
//- (void)deleteShader;
//
//// Return true if the shader exists and has been compiled and not deleted
//- (BOOL)isCompiled;
//
//@property (nonatomic, readonly) GLenum shaderType;
//@property (nonatomic, readonly) GLuint shaderID;
//@property (nonatomic, readonly) NSString *infoLog;
//@property (nonatomic, readonly) NSString *source;

@end
