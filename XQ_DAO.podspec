Pod::Spec.new do |s|
  s.name         = "XQ_DAO"
  s.version      = "1.5-light"
  s.summary      = "XQ_DAO base on FMDB"

  s.description  = <<-DESC
                      XQ_DAO base on FMDB, you have no need to use sql for FMDB.
                   DESC

  s.homepage     = "https://github.com/hssdx/XQ_DAO"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "hssdx" => "hssdx@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/hssdx/XQ_DAO.git", :tag => s.version }

  s.source_files  = "XQ_DAO/XQ_DAO.h", "src/*.{h,m}", "src/**/*.{h,m}"

  s.public_header_files = "XQ_DAO/XQ_DAO.h", "src/*.{h}", "src/**/*.{h}"

  s.framework = "CoreFoundation"
  s.requires_arc = true

  # s.dependency "XQKit"
  s.dependency "FMDB"

end
