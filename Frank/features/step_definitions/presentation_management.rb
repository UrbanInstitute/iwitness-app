Given(/^I've created a sample presentation$/) do
  app_exec "createSamplePresentationAndRestart"
end

When(/^I go to the Presentations list$/) do
  step "I tap \"PRESENTATIONS\""
end

Then(/^I should see a list of Presentations performed on this device$/) do
  wait_until(:message => "Waited for presentations to be listed, but didn't see them") {
    element_exists("view:'UITableView' view:'PresentationCell'")
  }
end

Then(/^I should see a Presentation's date and 24-hour time of presentation$/) do
  step "I should see \"January 12, 2014 15:35\""
end

Then(/^I should see a Presentation's Case ID$/) do
  step "I should see \"12345-6789\""
end

Then(/^I should see a Presentation$/) do
  step "I should see a Presentation's date and 24-hour time of presentation"
  step "I should see a Presentation's Case ID"
end

Then (/^I should wait to not see the Presentation$/) do
  sleep 1
  step "I should not see \"January 12, 2014 15:35\""
  step "I should not see \"12345-6789\""
end

When(/^I tap the "Delete" confirmation button$/) do
  sleep 1
  touch("view:'UITableViewCellDeleteConfirmationButton' marked:'Delete'")
end
