//
//  ShaderProgram.h
//  MandelWeekend
//
//  Created by William Makley on 12/5/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Shader;

@interface ShaderProgram : NSObject
{
    NSMutableArray *_shaders;
    BOOL _compiled;

//    GLuint _programID;
//    GLint _linkResult;
//    GLint _infoLogLength;
//    GLint _isValid;
//    GLint _numActiveAttribs;
//    GLint _numActiveUniforms;
//
//    NSMutableDictionary *_uniformLocations;
}

// Initializing
- (instancetype)init;

//// Adding shaders
//- (void)addShader:(Shader *)shader;
//- (void)addShaderWithFileName:(NSString *)fileName extension:(NSString *)extension shaderType:(GLenum)shaderType;
//- (void)addVertexShaderWithFileName:(NSString *)fileName;
//- (void)addFragmentShaderWithFileName:(NSString *)fileName;
//
//// Compiling and linking
//- (BOOL)compile;
//- (BOOL)link;
//- (BOOL)compileAndLink;
//@property (nonatomic, readonly) BOOL isCompiled;
//- (BOOL)isValid;
//
//// Using the program
//@property (nonatomic, readonly) GLuint programID;
//- (void)useProgram;
//
//// Setting uniforms
//- (GLint)getUniformLocation:(const char *)name;
//
//// Cleaning up
//- (void)deleteProgram;
//- (void)deleteShaders;
//- (void)deleteShadersAndProgram;

@end
