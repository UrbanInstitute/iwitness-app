PROJECT_NAME = "Eyewitness"
EXECUTABLE_NAME = "Eyewitness"
CONFIGURATION = "Release"
TESTFLIGHT_API_TOKEN = "9ce63da8ef6592f4ace862033aef3005_MTYzODQ5OTIwMTQtMDItMTEgMTQ6MjQ6MzUuNTIyNDEy"
TESTFLIGHT_TEAM_TOKEN = "a8ebbca195700f2c5a65645944a936c9_MzM3MTIwMjAxNC0wMi0xMSAxNDoyNToxNi41Mjc0NzM"
TESTFLIGHT_DISTRIBUTION_LIST = "Internal LJAF Eyewitnesses"

SPECS_TARGET_NAME = "Specs"
TRACKER_ID = "1005986"

SIMULATOR_SDK_VERSION = ENV['SIMULATOR_SDK_VERSION'] || "7.1"
SDK_VERSION = "7.1"
PROJECT_ROOT = File.dirname(__FILE__)
BUILD_DIR = File.join(PROJECT_ROOT, "build")

FRANK_ENTITLEMENTS_PATH = "Specs/Supporting\\ Files/entitlements.plist"

def build_configuration
  CONFIGURATION
end

def system_or_exit(cmd, stdout = nil)
  puts "Executing #{cmd}"
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise "******** Build failed ********"
end

def output_file(target)
  output_dir = if ENV['IS_CI_BOX']
    ENV['CC_BUILD_ARTIFACTS']
  else
    Dir.mkdir(BUILD_DIR) unless File.exists?(BUILD_DIR)
    BUILD_DIR
  end

  output_file = File.join(output_dir, "#{target}.output")
  puts "Output: #{output_file}"
  output_file
end

def shorten_media_assets_for_frank
  system_or_exit(%Q[for a in $(find Frank/frankified_build/Frankified.app -name instructions.mp4) ; do cp Frank/features/support/not_too_short_instructions.mp4 "$a" ; done])
  system_or_exit(%Q[cp Frank/features/support/not_too_short_instructions_es.mp4 Frank/frankified_build/Frankified.app/es.lproj/instructions.mp4])
  Dir.glob('Frank/frankified_build/Frankified.app/en.lproj/*.m4a') do |audio_file|
    system_or_exit(%Q[cp Frank/features/support/shorter_audio_prompt.m4a #{audio_file}])
  end
end

task :default => [:trim_whitespace, :specs, :frank]
task :ci => [:specs, :frank_for_ci]
task :cruise => [:clean, :specs, :frank]

desc "Trim whitespace"
task :trim_whitespace do
  system_or_exit %Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $NF}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc "Clean all targets"
task :clean do
  system_or_exit "rm -rf #{BUILD_DIR}/*", output_file("clean")
end

task :build_for_device do
  if `git status --short`.length != 0
    raise "******** Cannot push with uncommitted changes ********"
  end

  system_or_exit("agvtool next-version -all")
  build_number = `agvtool what-version -terse`.chomp

  system_or_exit("git commit -am'Updated build number to #{build_number}'")
  system_or_exit(%Q[xcodebuild -project #{PROJECT_NAME}.xcodeproj -scheme #{PROJECT_NAME} -configuration #{build_configuration} -sdk iphoneos -derivedDataPath #{BUILD_DIR} ARCHS=armv7 build SYMROOT=#{BUILD_DIR}], output_file("build_for_device"))
  system_or_exit("git push origin master")
end

task :archive => :build_for_device do
  system_or_exit(%Q[xcrun -sdk iphoneos PackageApplication #{BUILD_DIR}/#{build_configuration}-iphoneos/#{EXECUTABLE_NAME}.app -o #{BUILD_DIR}/#{build_configuration}-iphoneos/#{EXECUTABLE_NAME}.ipa])
end

task :archive_dsym_file do
  system_or_exit(%Q[zip -r #{BUILD_DIR}/#{build_configuration}-iphoneos/#{EXECUTABLE_NAME}.app.dSYM.zip #{BUILD_DIR}/#{build_configuration}-iphoneos/#{EXECUTABLE_NAME}.app.dSYM], output_file("build_all"))
end

desc "Run specs"
task :specs do
  system_or_exit(%Q[xcodebuild -project #{PROJECT_NAME}.xcodeproj -scheme #{EXECUTABLE_NAME} -arch i386 -sdk iphonesimulator -configuration #{build_configuration} -destination "name=iPad,OS=#{SIMULATOR_SDK_VERSION}" test GCC_SYMBOLS_PRIVATE_EXTERN=NO SYMROOT=#{BUILD_DIR}], output_file("specs"))
end

desc "Build frankified app with correct entitlements"
task :frank_build do
  system_or_exit(%Q[bundle && bundle exec frank build CODE_SIGN_ENTITLEMENTS='#{FRANK_ENTITLEMENTS_PATH}'])
  shorten_media_assets_for_frank
end

desc "Run frank features"
task :frank => :frank_build do
  system_or_exit(%Q[bundle exec cucumber Frank/features SIMULATOR_SDK_VERSION=#{SIMULATOR_SDK_VERSION}])
end

desc "Run frank features for CI environment"
task :frank_for_ci do
  system_or_exit(%Q[bundle && bundle exec frank build CODE_SIGN_ENTITLEMENTS='#{FRANK_ENTITLEMENTS_PATH}' PROVISIONING_PROFILE="#{ENV["PROVISIONING_PROFILE"]}"])
  shorten_media_assets_for_frank
  system_or_exit(%Q[cd Frank; bundle exec cucumber features])
end

require 'tmpdir'
namespace :testflight do
  task :deploy => [:clean, :archive, :archive_dsym_file] do

    file      = "#{BUILD_DIR}/#{build_configuration}-iphoneos/#{EXECUTABLE_NAME}.ipa"
    notes     = "Please refer to Tracker (https://www.pivotaltracker.com/projects/#{TRACKER_ID}) for further information about this build"
    dysmzip   = "#{BUILD_DIR}/#{build_configuration}-iphoneos/#{EXECUTABLE_NAME}.app.dSYM.zip"

    system_or_exit(%Q[curl http://testflightapp.com/api/builds.json -F file=@#{file} -F dsym=@#{dysmzip} -F api_token=#{TESTFLIGHT_API_TOKEN} -F team_token="#{TESTFLIGHT_TEAM_TOKEN}" -F notes="#{notes}" -F notify=True -F distribution_lists="#{TESTFLIGHT_DISTRIBUTION_LIST}"])
  end
end

