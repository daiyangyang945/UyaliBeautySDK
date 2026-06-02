//
//  RenderDestination.swift
//  DTCamera
//
//  Created by Dan Jiang on 2019/10/18.
//  Copyright © 2019 Dan Thought Studio. All rights reserved.
//

import UIKit

class RenderDestination {
    
    private var renderBuffer: GLuint = 0
    private var frameBuffer: GLuint = 0

    func createFrameBuffer() {
        glDisable(GLenum(GL_DEPTH_TEST))

        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
    }
    
    func setViewport(width: Int, height: Int) {
        glViewport(0, 0, GLsizei(width), GLsizei(height))
        
        glClearColor(0.85, 0.85, 0.85, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }

    func deleteFrameBuffer() {
        if frameBuffer != 0 {
            glDeleteFramebuffers(1, &frameBuffer)
            frameBuffer = 0
        }
    }
    
    func createRenderBuffer(context: EAGLContext, drawable: EAGLDrawable?) {
        glGenRenderbuffers(1, &renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        
        if !context.renderbufferStorage(Int(GL_RENDERBUFFER), from: drawable) {
            print("Could not bind a drawable object’s storage to a render buffer object")
            exit(1)
        }
    }
    
    func deleteRenderBuffer() {
        if renderBuffer != 0 {
            glDeleteRenderbuffers(1, &renderBuffer)
            renderBuffer = 0
        }
    }
    
    func attachTexture(name: GLuint) {
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER),
                               GLenum(GL_COLOR_ATTACHMENT0),
                               GLenum(GL_TEXTURE_2D),
                               name,
                               0)
    }
    
    func attachRenderBuffer() {
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER),
                                  GLenum(GL_COLOR_ATTACHMENT0),
                                  GLenum(GL_RENDERBUFFER),
                                  renderBuffer)
    }
    
    func checkFramebufferStatus() {
        if glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE {
            print("Could not generate frame buffer")
            exit(1)
        }
    }
    
}
