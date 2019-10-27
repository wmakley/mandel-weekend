//
//  ShaderProgram.m
//  MandelWeekend
//
//  Created by William Makley on 12/5/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import "ShaderProgram.h"
#import "Shader.h"

@implementation ShaderProgram

- (instancetype)init {
    if (self = [super init]) {
        // initialization here
    }
    return self;
}

- (void)addShader:(Shader *)shader {
    if (!_shaders) {
        _shaders = [[NSMutableArray alloc] initWithCapacity:10];
    }
    [_shaders addObject:shader];
}

- (void)addShaderWithFileName:(NSString *)fileName extension:(NSString *)extension shaderType:(GLenum)shaderType {
    Shader *shader = [[Shader alloc] initWithFileName:fileName extension:extension shaderType:shaderType];
    [self addShader:shader];
}

- (void)addVertexShaderWithFileName:(NSString *)fileName {
    Shader *shader = [[Shader alloc] initWithFileName:fileName extension:@"vsh" shaderType:GL_VERTEX_SHADER];
    [self addShader:shader];
}

- (void)addFragmentShaderWithFileName:(NSString *)fileName {
    Shader *shader = [[Shader alloc] initWithFileName:fileName extension:@"fsh" shaderType:GL_FRAGMENT_SHADER];
    [self addShader:shader];
}


- (BOOL)compileAndLink {
    if ( ! [self compile] ) {
        return NO;
    }
    if ( ! [self link] ) {
        return NO;
    }
    return YES;
}

- (BOOL)compile {
    if (_isCompiled) {
        return YES;
    }
    _isCompiled = YES;
    for (Shader *shader in _shaders) {
        if ( ! [shader compile] ) {
            _isCompiled = NO;
            break;
        }
    }
    return _isCompiled;
}

- (BOOL)link {
    if ( ! [self isCompiled] ) {
        NSLog(@"must compile shaders before linking");
        return NO;
    }

    _programID = glCreateProgram();

    for (Shader *shader in _shaders) {
        glAttachShader(_programID, [shader shaderID]);
    }

    glLinkProgram(_programID);
    glValidateProgram(_programID);

    _linkResult = GL_FALSE;
    _infoLogLength = 0;
    _isValid = GL_FALSE;
    glGetProgramiv(_programID, GL_LINK_STATUS, &_linkResult);
    glGetProgramiv(_programID, GL_VALIDATE_STATUS, &_isValid);
    glGetProgramiv(_programID, GL_INFO_LOG_LENGTH, &_infoLogLength);

    if (_infoLogLength > 0) {
        GLchar infoLogCString[_infoLogLength];
        glGetProgramInfoLog(_programID, _infoLogLength, NULL, &infoLogCString[0]);
        NSLog(@"Program linking log: %s", infoLogCString);
    }

    if ( ! [self isValid] ) {
        NSLog(@"linking or validation failed, link = %d, valid = %d", _linkResult, _isValid);
        return NO;
    }

    glGetProgramiv(_programID, GL_ACTIVE_ATTRIBUTES, &_numActiveAttribs);
    glGetProgramiv(_programID, GL_ACTIVE_UNIFORMS, &_numActiveUniforms);

    // TODO: save the uniforms to the dictionary

    return YES;
}

- (BOOL)isValid {
    return _programID != 0 && _linkResult == GL_TRUE && _isValid == GL_TRUE;
}


- (void)useProgram {
    glUseProgram(_programID);
}


- (GLint)getUniformLocation:(const char *)name {
    GLint location = glGetUniformLocation(_programID, name);
    if (location == -1) {
        NSLog(@"Warning: glUniformLocation '%s' is -1. This could mean it doesn't exist or has been optimized out.", name);
    }
    return location;
}


- (void)deleteProgram {
    if (_programID != 0) {
        glDeleteProgram(_programID);
        _programID = 0;
    }
}

- (void)deleteShaders {
    for (Shader *shader in _shaders) {
        [shader deleteShader];
    }
}

- (void)deleteShadersAndProgram {
    [self deleteProgram];
    [self deleteShaders];
}

@end
