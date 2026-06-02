//
//  OpenGLPreviewView.swift
//  DTCamera
//
//  Created by Dan Jiang on 2019/9/12.
//  Copyright © 2019 Dan Thought Studio. All rights reserved.
//

import UIKit
import GLKit

class OpenGLPreviewView: UIView {
    
    private var context: EAGLContext?

    // Input
    private var inputWidth: Int = 0
    private var inputHeight: Int = 0
    private var inputTexture: PixelBufferTexture!

    // Shader
    private var squareVertices: [GLfloat] = [
        -1, -1, // bottom left
        1, -1, // bottom right
        -1, 1, // top left
        1, 1, // top right
    ]
    private var textureVertices: [Float] = [ // vertical flip
        0, 1, // top left
        1, 1, // top right
        0, 0, // bottom left
        1, 0, // bottom right
    ]
    private var program: ShaderProgram!
    private var positionSlot = GLuint()
    private var texturePositionSlot = GLuint()
    private var textureUniform = GLint()
    private var colorUniform = GLuint()

    // Output
    private var outputWidth: Int = 0
    private var outputHeight: Int = 0
    private var renderDestination: RenderDestination!

    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }

    private var eaglLayer: CAEAGLLayer? {
        return layer as? CAEAGLLayer
    }
    
    deinit {
        reset()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentScaleFactor = UIScreen.main.scale
        
        guard let eaglLayer = eaglLayer else { return }
        eaglLayer.isOpaque = true
        eaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false,
                                        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]

        guard let context = EAGLContext(api: .openGLES2) else {
            print("Could not initialize OpenGL context")
            exit(1)
        }
        self.context = context
    }
    
    func display(pixelBuffer: CVPixelBuffer) {
        let oldContext = EAGLContext.current()
        if context != oldContext {
            if !EAGLContext.setCurrent(context) {
                print("Could not set current OpenGL context with new context")
                exit(1)
            }
        }
        
        inputWidth = CVPixelBufferGetWidth(pixelBuffer)
        inputHeight = CVPixelBufferGetHeight(pixelBuffer)

        if inputTexture == nil {
            setupInput()
        }
        if renderDestination == nil {
            compileShaders()
            setupOutput()
        }
                
        program.use()
        
        inputTexture.createTexture(from: pixelBuffer)
        inputTexture.bind(textureNo: GLenum(GL_TEXTURE0))
        glUniform1i(textureUniform, 0)
        
        glEnableVertexAttribArray(positionSlot)
        glVertexAttribPointer(positionSlot,
                              2,
                              GLenum(GL_FLOAT),
                              GLboolean(UInt8(GL_FALSE)),
                              GLsizei(0),
                              &squareVertices)
        
        glEnableVertexAttribArray(texturePositionSlot)
        glVertexAttribPointer(texturePositionSlot,
                              2,
                              GLenum(GL_FLOAT),
                              GLboolean(UInt8(GL_FALSE)),
                              GLsizei(0),
                              &textureVertices)
        
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)

        context?.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
        inputTexture.unbind()
        inputTexture.deleteTexture()
        
        if oldContext != context {
            if !EAGLContext.setCurrent(oldContext) {
                print("Could not set current OpenGL context with old context")
                exit(1)
            }
        }
    }
    
    func resetInputAndOutputDimensions() {
        inputTexture = nil
        setOutputDimensions()
    }
    
    private func setupInput() {
        guard let context = context else { return }
        inputTexture = PixelBufferTexture(width: inputWidth, height: inputHeight,
                                          retainedBufferCountHint: 0)
        inputTexture.createTextureCache(in: context)
    }
    
    private func compileShaders() {
        program = ShaderProgram(vertexShaderName: "DirectPassVertex", fragmentShaderName: "DirectPassFragment")
        positionSlot = program.attributeLocation(for: "a_position")
        texturePositionSlot = program.attributeLocation(for: "a_texcoord")
        textureUniform = program.uniformLocation(for: "u_texture")
    }
    
    private func setupOutput() {
        guard let context = context, let eaglLayer = eaglLayer else { return }
        renderDestination = RenderDestination()
        renderDestination.createRenderBuffer(context: context, drawable: eaglLayer)
        renderDestination.createFrameBuffer()
        setOutputDimensions()
        renderDestination.attachRenderBuffer()
        renderDestination.checkFramebufferStatus()
    }
    
    private func setOutputDimensions() {
        var width = GLint()
        var height = GLint()
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &width)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &height)
        outputWidth = Int(width)
        outputHeight = Int(height)
        renderDestination.setViewport(width: outputWidth, height: outputHeight)
    }
    
    private func reset() {
        let oldContext = EAGLContext.current()
        if context != oldContext {
            if !EAGLContext.setCurrent(context) {
                print("Could not set current OpenGL context with new context")
                exit(1)
            }
        }
        renderDestination?.deleteFrameBuffer()
        renderDestination?.deleteRenderBuffer()
        program?.delete()
        inputTexture?.deleteTextureCache()
        if oldContext != context {
            if !EAGLContext.setCurrent(oldContext) {
                print("Could not set current OpenGL context with old context")
                exit(1)
            }
        }
        EAGLContext.setCurrent(nil)
        context = nil
    }
    
}
