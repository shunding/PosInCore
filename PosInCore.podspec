Pod::Spec.new do |s|
  s.license = 'MIT'
  s.name = 'PosInCore'
  s.summary  = 'Core reusable funcionality'
  s.authors  = { 'Alexandr Goncharov' => 'ag@bekitzur.com', 'Alex Drozhak' => 'alex.drozhak@me.com' }
  s.version = '1.0'
  s.platform = :ios
  s.ios.deployment_target = '9.0'
  s.source_files =  'PosInCore/*.swift' , 'PosInCore/TableView/*.swift'
  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'ObjectMapper', '~>  2.0'
  s.dependency 'BrightFutures', '~> 5.0'
  s.requires_arc = true
  s.homepage='http://positionin.com'
  s.source={ :git => 'https://github.com/solunalabs/position-in-ios.git'}
end
