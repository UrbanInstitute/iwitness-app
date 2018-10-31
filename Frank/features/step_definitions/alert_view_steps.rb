When(/^I tap the alert view button marked "(.*?)"$/) do |button|
  if frankly_map("view:'UITextField'", "resignFirstResponder").last
    wait_until(:timeout => 10, :message => "Waited to tap alert content view but couldn't'") do
      begin
        touch("view:'_UIModalItemAlertContentView'").last
      rescue
        false
      end
    end
    touch "view:'_UIModalItemAlertContentView'"
    sleep 0.5
  end

  wait_until(:timeout => 10, :message => "Waited to tap alert view button but couldn't'") do
    begin
      touch("view:'_UIModalItemTableViewCell' marked:'#{button}'").last
    rescue
      false
    end
  end
  wait_until(:timeout => 10, :message => "Waited for alert view to dismiss, but it didn't") do
    !element_exists("view:'_UIModalItemTableViewCell'")
  end
end

Then /^I should see an alert view with the title "([^\"]*)"$/ do |expected_mark|
  wait_until(:timeout => 10, :message => "Waited to see alert view but didn't") do
    frankly_map( "view:'_UIModalItemRepresentationView' label", 'text').include? expected_mark
  end
end

When(/^I type "(.*?)" into the alert view's text field$/) do |text_to_type|
  text_fields_modified = frankly_map( "view:'UIAlertSheetTextField'", "setText:", text_to_type )
  raise "could not find an alert view text field" if text_fields_modified.empty?
end
