Feature:
  Officer manages presentations on device

  Scenario:
    As an Officer
    I need to see the list of presentations given
    So that I can understand when lineup presentations were made

    Given I launch a clean instance of the app
    And I've created a sample presentation
    When I go to the Presentations list
    Then I should see a list of Presentations performed on this device
    And I should see a Presentation's date and 24-hour time of presentation
    And I should see a Presentation's Case ID
    And I should see a "VIEW PRESENTATION" button
    And I should see an interface locked to portrait

    And I should see "available on device"
    But I should not see exactly "0m available on device"

  Scenario:
    As an Officer
    I need to delete presentations
    So that I can free up device space when needed

    Given I launch a clean instance of the app
    And I've created a sample presentation
    When I go to the Presentations list
    Then I should see a list of Presentations performed on this device
    And I should see a Presentation
    When I tap the "Edit" button
    And I tap the "Delete" accessory view
    And I tap the "Delete" confirmation button
    And I wait to see "Are you sure you want to delete this presentation?"
    When I tap the alert view button marked "Delete"
    Then I should wait to not see the Presentation

  Scenario:
    As an Officer
    I need to view a presentation
    So that I can know what the witness said

    Given I launch a clean instance of the app
    And I've created a sample presentation
    And I go to the Presentations list
    When I tap the "VIEW PRESENTATION" button
    Then I should wait to see a movie player

    When I wait until I don't see "Pause"
    Then I should wait to see a movie player
    And I should not see "Presentations"

    When I tap the "Done" button
    And I wait until I don't see "Done"
    Then I should see "Presentations"
