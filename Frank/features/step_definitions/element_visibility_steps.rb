Then /^I wait until I don't see "([^\"]*)"$/ do |expected_mark|
  quote = get_selector_quote(expected_mark)
  wait_until( :timeout => 5, :message => "waited to not see view marked #{quote}#{expected_mark}#{quote}"){
    !view_with_mark_exists( expected_mark )
  }
end

When(/^I wait until I don't see a navigation bar titled "(.*?)"$/) do |expected_mark|
  quote = get_selector_quote(expected_mark)
  wait_until( :timeout => 5, :message => "waited to not see a navigation bar titled #{quote}#{expected_mark}#{quote}" ) {
    !element_exists( "navigationItemView marked:#{quote}#{expected_mark}#{quote}" )
  }
end

Then /^I should not see exactly "([^\"]*)"$/ do |expected_mark|
  quote = get_selector_quote(expected_mark)
  check_element_does_not_exist_or_is_not_visible("view markedExactly:#{quote}#{expected_mark}#{quote}")
end

Then /^I should not see the status bar$/ do
  unless app_exec("isStatusBarHidden").last
    fail "I expected to not see the status bar but it was not hidden."
  end
end

Then /^I should see exactly "([^\"]*)"$/ do |expected_mark|
  quote = get_selector_quote(expected_mark)
  check_element_exists("view markedExactly:#{quote}#{expected_mark}#{quote}")
end

Then /^I should see a suspect card with the following information:$/ do |table|
  check_element_exists "view:'SuspectCardView'"
  table.hashes.each do |row|
    step %Q|I should see "#{row['data']}"|
  end
end

Then(/^I should see a selected portrayal with the date "(.*?)"$/) do |date|
    if frankly_map("view:'SuspectPortrayalCell' marked:'#{date}'", "isSelected").none?
      fail "I expected to see a selected portrayal"
    end
end

Then(/^I should see an unselected portrayal with the date "(.*?)"$/) do |date|
    if frankly_map("view:'SuspectPortrayalCell' marked:'#{date}'", "isSelected").none? { |isSelected| isSelected == false }
      fail "I expected to see an unselected portrayal"
    end
end

Then(/^I should see the (\d+)(?:st|nd|rd|th)? portrayal selected$/) do |ordinal|
  ordinal = ordinal.to_i - 1
  if frankly_map("view:'SuspectPortrayalCell' index:#{ordinal}", "isSelected").none?
    fail "I expected to see cell number #{ordinal} selected"
  end
end

Then(/^I should not see a suspect card$/) do
  check_element_does_not_exist_or_is_not_visible("view:'SuspectCardView'")
end
