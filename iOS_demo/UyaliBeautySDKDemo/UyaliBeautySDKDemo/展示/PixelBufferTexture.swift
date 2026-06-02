//
//  PixelBufferTexture.swift
//  DTCamera
//
//  Created by Dan Jiang on 2019/10/18.
//  Copyright © 2019 Dan Thought Studio. All rights reserved.
//

import UIKit

class PixelBufferTexture {
    
    private let width: Int
    private let height: Int
    private let retainedBufferCountHint: Int

    private var texture: CVOpenGLESTexture!
    private var textureCache: CVOpenGLESTextureCache!
    private var bufferPool: CVPixelBufferPool!
    private var bufferPoolAuxAttributes: NSDictionary!
    
    var textureName: GLuint {
        return CVOpenGLESTextureGetName(texture)
    }

    init(width: Int, height: Int, retainedBufferCountHint: Int) {
        self.width = width
        self.height = height
        self.retainedBufferCountHint = retainedBufferCountHint
    }
    
    func createTexture() -> CVPixelBuffer {
        let pixelBuffer = createPixelBuffer()
        createTexture(from: pixelBuffer)
        return pixelBuffer
    }
    
    func createTexture(from pixelBuffer: CVPixelBuffer) {
        let resultCode = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                      textureCache,
                                                                      pixelBuffer,
                                                                      nil,
                                                                      GLenum(GL_TEXTURE_2D),
                                                                      GL_RGBA,
                                                                      GLsizei(width),
                                                                      GLsizei(height),
                                                                      GLenum(GL_BGRA),
                                                                      GLenum(GL_UNSIGNED_BYTE),
                                                                      0,
                                                                      &texture)
        if resultCode != kCVReturnSuccess {
            print("Could not create texture from image \(resultCode)")
            exit(1)
        }
    }
    
    func deleteTexture() {
        texture = nil
    }

    func bind(textureNo: GLenum) {
        glActiveTexture(textureNo)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureName)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
    }
    
    func unbind() {
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }
        
    func createPixelBuffer() -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer!
        var resultCode = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault,
                                                                             bufferPool,
                                                                             bufferPoolAuxAttributes,
                                                                             &pixelBuffer)
        if resultCode == kCVReturnWouldExceedAllocationThreshold {
            CVOpenGLESTextureCacheFlush(textureCache, 0)
            resultCode = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault,
                                                                             bufferPool,
                                                                             bufferPoolAuxAttributes,
                                                                             &pixelBuffer)
        }
        if resultCode != kCVReturnSuccess {
            if resultCode == kCVReturnWouldExceedAllocationThreshold {
                print("Pool is out of buffers, dropping frame \(resultCode)")
            } else {
                print("Could not create pixel buffer in pool \(resultCode)")
            }
            exit(1)
        }
        return pixelBuffer
    }

    func createTextureCache(in context: EAGLContext) {
        let resultCode = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
        if resultCode != kCVReturnSuccess {
            print("Could not create texture cache \(resultCode)")
            exit(1)
        }
    }
    
    func deleteTextureCache() {
        textureCache = nil
    }
    
    func createBufferPool() {
        let pixelBufferPoolOptions: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: retainedBufferCountHint]
        let pixelBufferOptions: NSDictionary = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                                                kCVPixelBufferWidthKey: width,
                                                kCVPixelBufferHeightKey: height,
                                                kCVPixelFormatOpenGLESCompatibility: true,
                                                kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()]
        let resultCode = CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                                 pixelBufferPoolOptions,
                                                 pixelBufferOptions,
                                                 &bufferPool)
        if resultCode != kCVReturnSuccess {
            print("Could not create pixel buffer pool \(resultCode)")
            exit(1)
        }
        bufferPoolAuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey: retainedBufferCountHint]
        preallocatePixelBuffers(in: bufferPool, with: bufferPoolAuxAttributes)
    }
    
    func deleteBufferPool() {
        bufferPool = nil
        bufferPoolAuxAttributes = nil
    }
    
    private func preallocatePixelBuffers(in pool: CVPixelBufferPool, with auxAttributes: NSDictionary) {
        var pixelBuffers: [CVPixelBuffer] = []
        while true {
            var pixelBuffer: CVPixelBuffer!
            let resultCode = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault,
                                                                                 pool,
                                                                                 auxAttributes,
                                                                                 &pixelBuffer)
            if resultCode == kCVReturnWouldExceedAllocationThreshold {
                break
            }
            pixelBuffers.append(pixelBuffer)
        }
        pixelBuffers.removeAll()
    }
    
}
