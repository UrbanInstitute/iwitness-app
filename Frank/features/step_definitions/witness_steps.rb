# encoding: utf-8

Then(/^I should see a mugshot photo$/) do
  check_element_exists("view view:'UIImageView' marked:'MugshotPhoto'")
end

Given(/^I've started a presentation as a witness$/) do
  step "I launch a clean instance of the app"
  step "the device is in portrait orientation"
  step "there is a valid lineup configured"
  step "I expand the lineup cell with case ID \"12345-6789\""
  step "I tap the \"PRESENT TO WITNESS\" button"
  step "I wait until I don't see \"PRESENT TO WITNESS\""
  step "I tap the \"BEGIN\" button"
  step "I wait until I don't see \"BEGIN\""
  step "I tap the \"NEXT →\" button"
  step "I wait until I don't see \"SPEAK NOW\""
  step "I tap the \"NEXT →\" button"
  step "I wait until I don't see \"RECORDING\""
  step "I wait for the \"NEXT →\" button to be enabled"
  step "I tap \"NEXT →\""
  step "I wait until I don't see \"NEXT →\""
  step "I wait for the \"I UNDERSTAND\" button to be enabled"
  step "I tap the \"I UNDERSTAND\" button"
  step "I wait until I don't see \"Do you understand these instructions?\""
end

When(/^I have responded to every photo$/) do
  while element_exists("view view:'UIImageView' marked:'MugshotPhoto'") do
    is_transitioning = false
    wait_until(:timeout => 10, :message => "waited for witness response selector to be enabled") do
      frankly_map("view:'WitnessResponseSelector'", "isEnabled").any?
    end
    wait_until(:timeout => 30, :message => "waited to touch witness response 'NO', but wasn't able to'") do
      begin
      touch("view:'WitnessResponseSelector' view:'WitnessResponseButton' markedExactly:'NO'").last
      rescue
        is_transitioning = element_exists("view:'UINavigationTransitionView'")
      end
    end
    break if is_transitioning
    wait_until(:timeout => 30, :message => "waited to see the NEXT → button") do
      element_exists("button markedExactly:'NEXT →'")
    end
    wait_until(:timeout => 10, :message => "waited for button to be enabled") do
      frankly_map("button markedExactly:'NEXT →'", "isEnabled").any?
    end
    wait_until(:timeout => 30, :message => "waited to touch 'NEXT →' button, but wasn't able to'") do
      touch("button markedExactly:'NEXT →'").last
    end
    step "I wait until I don't see \"NEXT →\""
  end
  wait_until(:message => "Waited for mugshot photo to disappear, but it's still there") do
    !element_exists("view view:'UIImageView' marked:'MugshotPhoto'")
  end
end

Then(/^I should see a (disabled|) witness response selector with the following options:$/) do |disabled, table|
  if disabled == "disabled"
    if frankly_map("view:'WitnessResponseSelector'", "isEnabled").any?
      fail "Expected WitnessResponseSelector to be disabled!"
    end
  end
  table.raw.flatten.each do |option_label|
    check_element_exists("view:'WitnessResponseSelector' view:'WitnessResponseButton' marked:'#{option_label}'")
  end
end

When(/^I wait for the witness response selector to be enabled$/) do
  wait_until(:timeout => 10, :message => "waited for witness response selector to be enabled") do
    frankly_map("view:'WitnessResponseSelector'", "isEnabled").any?
  end
end

Then(/^I should see a popover table view with the following items:$/) do |table|
  wait_until(:timeout => 10, :message => "Waited for popover to appear, but it didn't!'") do
    element_exists("view:'_UIPopoverView'")
  end
  table.raw.each do |row|
    expected_mark = row.first
    quote = get_selector_quote(expected_mark)
    check_element_exists "view:'_UIPopoverView' view:'UITableViewCell' view:'UILabel' marked:#{quote}#{expected_mark}#{quote}"
  end
end

When(/^I wait for the popover to be dismissed$/) do
  wait_until(:timeout => 10, :message => "waited for popover to be dismissed, but it wasn't!") do
    !element_exists("view:'_UIPopoverView'")
  end
end

When(/^I select the "([^\"]*)" response$/) do |response|
  quote = get_selector_quote(response)
  touch("view:'WitnessResponseSelector' view:'WitnessResponseButton' markedExactly:#{quote}#{response}#{quote}")
end
