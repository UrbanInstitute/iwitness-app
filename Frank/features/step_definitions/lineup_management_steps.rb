Given(/^I've created a lineup with the case ID "([^\"]*)"$/) do |case_id|
  step "I launch a clean instance of the app"
  step "the device is in portrait orientation"
  step "I tap the \"Add\" button"
  step "I wait until I don't see a navigation bar titled \"Lineups\""
  step "I type \"#{case_id}\" into the text field marked \"Case ID\""
  step "I type \"John Doe\" into the text field marked \"Suspect Name\""
  step "I tap the \"Done\" button"
  step "I wait until I don't see \"New Lineup\""
  step "I collapse the lineup cell with case ID \"#{case_id}\""
  wait_until(:message => "waited for EDIT button to go away, but it didnt") {
    value = frankly_map("button marked:\"EDIT\"", "alpha").last
    value == 0
  }
end

When(/^I (expand|collapse) the lineup cell with case ID "([^\"]*)"$/) do |expand_type, case_id|
  step "I tap \"#{case_id}\""
  sleep 0.5
end

Given(/^there is a valid lineup configured$/) do
  app_exec("createValidLineupAndRestart")
end

Given(/^there is an invalid lineup configured$/) do
  app_exec("createInvalidLineupAndRestart")
end

When(/^I tap the "Add Photo" cell for the (suspect photo|filler photos)$/) do |qualifier|
  selector = "view:'UICollectionView' marked:'#{qualifier} container' view:'AddPhotoCell'"
  sleep 1
  touch(selector)
end

Then(/^I should not see "Add Photo" next to the suspect photo$/) do
  check_element_does_not_exist "view:'UICollectionView' marked:'filler photos container' view marked:'Add Photo' hidden"
end

When(/^I tap the first suspect search result$/) do
  touch("view:'PersonResultCell' index:0")
end

When(/^I tap the suspect card$/) do
  wait_for_nothing_to_be_animating
  touch("view:'SuspectCardView'")
end

When(/^I tap the (\d+)(?:st|nd|rd|th)? portrayal$/) do |ordinal|
  ordinal = ordinal.to_i - 1
  touch("view:'SuspectPortrayalCell' index:#{ordinal}")
end

