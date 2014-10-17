# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'
require 'bundler'
Bundler.require

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'CasualConc'
  app.info_plist['NSMainNibFile'] = 'MainMenu'
  app.version = '20141017'
  app.short_version = '2.0'

  app.archs['MacOSX'] = ['x86_64']

  app.frameworks = ['Quartz']
  
  app.info_plist['CFBundleIdentifier'] = 'jp.yi.CasualConcRM'
  
  app.copyright = "Copyright (c) 2014 Yasuhiro Imao. All Right Reserved."
  app.icon = 'CasualConc.icns'
  
  app.pods do
    pod 'FMDB'
  end
end
