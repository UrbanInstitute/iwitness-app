Given /^I have photos in the photo library$/ do
  app_exec "addPhotosToPhotoLibrary"
end

Then(/^I should see a photo to be picked$/) do
  wait_until(:timeout => 10, :message => "Waited to see PhotoPickerCells, but didn't see any") {
    element_exists "view:'PhotoPickerCell'"
  }
end

Then(/^I should see a (?:lineup|suspect) photo$/) do
  check_element_exists "view:'LineupPhotoCell'"
end

Then(/^I should see a checkmark$/) do
  check_element_exists "view view:'UIView' marked:'checkmark'"
end
