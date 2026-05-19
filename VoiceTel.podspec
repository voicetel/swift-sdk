Pod::Spec.new do |s|
  s.name             = 'VoiceTel'
  s.version          = '2.2.10'
  s.summary          = 'The official Swift SDK for the VoiceTel REST API (v2.2.10).'
  s.description      = <<-DESC
    The official Swift client for the VoiceTel REST API: provision numbers,
    place orders, validate e911, send messages, and manage your account.
    Built on URLSession + Swift Concurrency. Zero external dependencies.
  DESC

  s.homepage         = 'https://github.com/voicetel/swift-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'VoiceTel' => 'support@voicetel.com' }
  s.source           = { :git => 'https://github.com/voicetel/swift-sdk.git', :tag => "#{s.version}" }
  s.documentation_url = 'https://voicetel.com/docs/api/v2.2/'

  s.swift_version    = '5.9'
  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'
  s.tvos.deployment_target    = '15.0'
  s.watchos.deployment_target = '8.0'

  s.source_files = 'Sources/VoiceTel/**/*.swift'
  s.frameworks   = 'Foundation'
end
