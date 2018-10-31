Feature:
  Officer prepares presentation

Scenario:
  As an officer
  I need to prepare the lineup presentation
  So that I can administer it to the witness

Given I launch a clean instance of the app
And there is a valid lineup configured
And the device is in portrait orientation

Then I should see "available on device"
But I should not see exactly "0m available on device"

When I expand the lineup cell with case ID "12345-6789"
Then I should see a "PRESENT TO WITNESS" button

When I tap the "PRESENT TO WITNESS" button
And I wait until I don't see "PRESENT TO WITNESS"

Then I should see "Present Case ID: 12345-6789"
And I should not see exactly "0 minutes of video left on device"
And I should see "of video left on device"
And I should see a video preview
And I should see an audio level meter
And I should see a "BEGIN" button
And I should see a "Cancel" button

When I tap the "Cancel" button
And I wait until I don't see "Cancel"
Then I should see "Lineups"

When I tap the "PRESENT TO WITNESS" button
And I wait until I don't see "PRESENT TO WITNESS"

When I tap the "BEGIN" button
Then I wait to see "NEXT →"
And I wait until I don't see "BEGIN"

When I swipe upwards
Then I should see an alert view with the title "Enter Officer Password to End the Presentation"

When I type "ewid" into the alert view's text field
And I tap the alert view button marked "Exit"
Then I should see "Lineups"

Scenario:
  As an officer
  I need to know when a lineup is not ready to be presented
  So I know I need to finish preparing it

Given I launch a clean instance of the app
And there is an invalid lineup configured
And the device is in portrait orientation

When I expand the lineup cell with case ID "12345-6789"
Then I should see a disabled "PRESENT TO WITNESS" button
