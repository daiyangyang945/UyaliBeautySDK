Pod::Spec.new do |s|
  s.name = 'UyaliBeautySDK'
  s.version = '1.0.0'
  s.summary = 'Mobile beauty SDK for real-time camera and image beautification.'
  s.description = <<-DESC
    UyaliBeautySDK is a mobile beauty SDK with beauty, face reshape,
    body reshape and makeup features for camera and image workflows.
    The current CocoaPods package supports iOS.

    UyaliBeautySDK 是移动端美颜 SDK，支持相机预览和图片处理中的美颜、美型、美体和美妆效果。当前 CocoaPods 包支持 iOS。
  DESC
  s.homepage = 'https://github.com/daiyangyang945/UyaliBeautySDK'
  s.license = { :type => 'Custom', :text => 'See the repository README for usage terms.' }
  s.author = { 'UyaliBeauty' => 'UyaliBeauty' }
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
  s.source = { :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git', :branch => 'main' }

  # Integrate the XCFramework directly.
  # 直接集成 XCFramework。
  s.vendored_frameworks = 'UyaliBeautySDK.xcframework'
  s.requires_arc = true
end
