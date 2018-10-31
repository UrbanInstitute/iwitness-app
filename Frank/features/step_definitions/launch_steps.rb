def app_path
  ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH)
end

Given /^I kill zombies dead$/ do
  system("ps aux | grep launchd_sim | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null")
end

Given /^I launch the app$/ do
  # latest sdk and iphone by default
  launch_app app_path, 7.0, ipad
end

Given /^I launch the app using iOS (\d\.\d)$/ do |sdk|
  # You can grab a list of the installed SDK with sim_launcher
  # > run sim_launcher from the command line
  # > open a browser to http://localhost:8881/showsdks
  # > use one of the sdk you see in parenthesis (e.g. 4.2)
  launch_app app_path, sdk
end

Given /^I launch the app using iOS (\d\.\d) and the (iphone|ipad) simulator$/ do |sdk, version|
  launch_app app_path, sdk, version
end

Given /^I launch a clean instance of the app$/ do
  step "I kill zombies dead"
  step "I reset the simulator"
  step "I launch the app using iOS #{ENV['SIMULATOR_SDK_VERSION']||"7.1"} and the ipad simulator"
end

Then(/^I should see an interface locked to portrait$/) do
  step "I rotate to the \"right\""

  orientation = app_exec("interfaceOrientationOfTopViewController").last
   if orientation != 1
     fail "The interface orientation is not portrait (actual: #{orientation})"
   end

  step "I rotate to the \"left\""
end
