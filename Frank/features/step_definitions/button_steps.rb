When(/^I tap the "([^\"]*)" button$/) do |button_name|
  quote = get_selector_quote(button_name)
  wait_until(:timeout => 10, :message => "waited to touch button marked exactly #{quote}#{button_name}#{quote}"){
    begin
      touch("button markedExactly:#{quote}#{button_name}#{quote}").last
    rescue
      false
    end
  }
end

Then(/^I should see a disabled "(.*?)" button$/) do |button_name|
  quote = get_selector_quote(button_name)
  if frankly_map("button markedExactly:#{quote}#{button_name}#{quote}", "isEnabled").any?
    fail "Expected \"#{button_name}\" button to be disabled"
  end
end

When(/^I wait for the "(.*?)" button to be enabled$/) do |button_name|
  quote = get_selector_quote(button_name)
  wait_until(:timeout => 10, :message => "waited for button to be enabled") {
    frankly_map("button markedExactly:#{quote}#{button_name}#{quote}", "isEnabled").any?
  }
end
