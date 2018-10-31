Feature:
  Officer manages lineups

  Scenario:
    As an officer
    I need to create a lineup
    So that I can add suspect and filler photos for showing to a witness

    Given I launch a clean instance of the app
    And the device is in portrait orientation

    Then I should see an interface locked to portrait
    And I should see a navigation bar titled "Lineups"
    And I should see a "Add" button

    When I tap the "Add" button
    And I wait until I don't see a navigation bar titled "Lineups"

    Then I should see an interface locked to portrait
    And I should see "Case ID"
    And I should see "Suspect Name"
    And I should not see "Delete"
    And I should see "SUSPECT PHOTO REQUIRED FOR PRESENTATION"
    And I should see "AT LEAST 5 FILLERS REQUIRED FOR PRESENTATION"

    When I fill in text fields as follows:
      | field        | text     |
      | Case ID      | 1234     |
      | Suspect Name | John Doe |
    And I tap the "Done" button
    And I wait until I don't see "New Lineup"
    Then I should see "1234"

  Scenario:
    As an officer
    I need to edit a lineup
    So that I can change its details

    Given I've created a lineup with the case ID "5678"
    When I expand the lineup cell with case ID "5678"
    And I tap the "EDIT" button
    And I wait until I don't see "EDIT"
    Then I should see "Case ID"

    When I tap the "Edit" button
    And I fill in text fields as follows:
      | field   | text |
      | Case ID | abcd |
    And I tap the "Done" button
    And I wait until I don't see "Cancel"
    And I tap the "Done" button
    And I wait until I don't see "Edit"
    Then I should see "abcd"
    And I should not see "5678"

  Scenario:
    As an officer
    I need to delete a lineup
    So that I can cleanup my lineup collection

    Given I've created a lineup with the case ID "2345"
    When I expand the lineup cell with case ID "2345"
    And I tap the "EDIT" button
    And I wait until I don't see "EDIT"
    Then I should see "Case ID"

    When I tap the "Delete" button
    Then I should see an alert view with the title "Are you sure you want to delete this lineup?"
    When I tap the alert view button marked "Delete"
    And I wait until I don't see a navigation bar titled "2345"
    Then I should see a navigation bar titled "Lineups"
    And I should not see "2345"

  Scenario:
    As an officer
    I want lineups to be present across app launches
    So that I don't need to recreate them each time

    Given I've created a lineup with the case ID "9789"
    When I quit the simulator
    And I wait for 1 second
    And I launch the app using iOS 7.0 and the ipad simulator
    And the device is in portrait orientation

    Then I should see a navigation bar titled "Lineups"
    And I should see "9789"

  Scenario:
    As an officer
    I want to select filler photos
    So that I can prepare a lineup

    Given I've created a lineup with the case ID "12345-fillers"
    Given I have photos in the photo library
    And I expand the lineup cell with case ID "12345-fillers"
    And I tap the "EDIT" button
    And I wait until I don't see "EDIT"

    Then I should see "AT LEAST 5 FILLERS REQUIRED FOR PRESENTATION"

    When I tap the "Edit" button
    And I wait to see "Add Photo"
    And I tap the "Add Photo" cell for the filler photos
    And I wait until I don't see "Case ID"

    Then I should see "All Imported"
    And I should see "Camera Roll"
    And I should see "Last Import"

    And I should see an interface locked to portrait

    When I tap "Camera Roll"
    Then I should see a photo to be picked

    When I tap the first collection view cell
    Then I should see a "Select Photo" button
    And I should see a checkmark

    When I tap the 2nd collection view cell
    And I tap the 3rd collection view cell
    And I tap the 4th collection view cell
    And I tap the 5th collection view cell
    And I wait to see "Select 5 Photos"

    When I tap the "Select 5 Photos" button
    And I wait until I don't see "Select 5 Photos"
    Then I should see "Add Photo"
    And I should see a lineup photo
    But I should not see "AT LEAST 5 FILLERS REQUIRED FOR PRESENTATION"

  Scenario:
    As an officer
    I want to select the suspect photo
    So that I can prepare a lineup

    Given I've created a lineup with the case ID "12345-fillers"
    Given I have photos in the photo library
    And I expand the lineup cell with case ID "12345-fillers"
    And I tap the "EDIT" button
    And I wait until I don't see "EDIT"

    Then I should see "SUSPECT PHOTO REQUIRED FOR PRESENTATION"

    When I tap the "Edit" button
    And I wait to see "Add Photo"
    And I tap the "Add Photo" cell for the suspect photo
    And I wait until I don't see "Case ID"

    Then I should see "All Imported"
    And I should see "Camera Roll"
    And I should see "Last Import"

    When I tap "Camera Roll"
    Then I should see a photo to be picked

    When I tap the first collection view cell
    Then I wait to see "Select Photo"
    And I should see a checkmark

    When I tap the "Select Photo" button
    And I wait until I don't see "Select Photo"
    Then I should see a suspect photo
    And I should not see "Add Photo" next to the suspect photo
    But I should not see "SUSPECT PHOTO REQUIRED FOR PRESENTATION"

  Scenario:
    As an officer
    I want to select the suspect photo from a database
    Because it offers all the photos

    Given I launch a clean instance of the app
    When I tap the "Add" button
    And I wait until I don't see a navigation bar titled "Lineups"
    Then I should see a "CHOOSE FROM DB" button

    When I tap "CHOOSE FROM DB"
    And I wait until I don't see "CHOOSE FROM DB"
    Then I should see "Suspect Search"
    And I should see "CASE ID"
    And I should see a text field marked "First Name"
    And I should see a text field marked "Last Name"
    And I should see a "SEARCH" button

    When I fill in text fields as follows:
      | field      | text  |
      | First Name | Leon  |
      | Last Name  | Lewis |

    When I tap the "SEARCH" button
    And I wait to see "result"
    Then I should see a suspect card with the following information:
      | data      |
      | Leon      |
      | Lewis     |
      | 1/18/1975 |
      | 463672    |

    When I tap the first suspect search result
    And I wait until I don't see "result"
    Then I should see a navigation bar titled "ID: 463672, Leon Lewis"
    Then I should see "INFO"
    And I should see a suspect card with the following information:
      | data       |
      | Leon       |
      | Lewis      |
      | 1/18/1975  |
      | ID: 463672 |

    And I should see "PHOTOS"
    And I should see "Choose a photo for the lineup"
    And I should see a selected portrayal with the date "8/8/2012"
    And I should see an unselected portrayal with the date "12/5/2013"

    When I tap the portrayal with the date "12/5/2013"
    And I wait until I don't see "Choose a photo for the lineup"
    Then I should see "SELECT SUSPECT PHOTO"
    And I should see "CANCEL"

    When I tap the "CANCEL" button
    And I wait until I don't see "SELECT SUSPECT PHOTO"
    Then I should see a selected portrayal with the date "8/8/2012"
    And I should see an unselected portrayal with the date "12/5/2013"

    When I tap the portrayal with the date "12/5/2013"
    And I wait until I don't see "Choose a photo for the lineup"
    Then I should see "SELECT SUSPECT PHOTO"
    And I should see "CANCEL"

    When I tap the "SELECT SUSPECT PHOTO" button
    And I wait until I don't see "SELECT SUSPECT PHOTO"
    Then I should see a selected portrayal with the date "12/5/2013"
    And I should see an unselected portrayal with the date "8/8/2012"

    When I tap the "Done" button
    And I wait until I don't see a navigation bar titled "ID: 463672, Leon Lewis"

    Then I should see a navigation bar titled "New Lineup"
    And I should see a suspect card with the following information:
      | data      |
      | Leon      |
      | Lewis     |
      | 1/18/1975 |
      | 463672    |

    When I tap the suspect card
    And I wait until I don't see a navigation bar titled "New Lineup"

    Then I should see a navigation bar titled "ID: 463672, Leon Lewis"
    And I should see a selected portrayal with the date "12/5/2013"

    When I tap the portrayal with the date "9/14/2007"
    And I tap the "SELECT SUSPECT PHOTO" button
    Then I should see a selected portrayal with the date "9/14/2007"

    When I tap the "Done" button
    And I wait until I don't see a navigation bar titled "ID: 463672, Leon Lewis"

    Then I should see a navigation bar titled "New Lineup"

    When I tap the "Done" button
    And I wait until I don't see a navigation bar titled "New Lineup"
    Then I should see a navigation bar titled "Lineups"
    And I tap the "EDIT" button
    And I wait until I don't see a navigation bar titled "Lineups"

    And I should see a suspect card with the following information:
      | data      |
      | Leon      |
      | Lewis     |
      | 1/18/1975 |
      | 463672    |

    When I tap the "Edit" button
    Then I should see "Delete Suspect"

    When I tap the "Delete Suspect" button
    Then I should not see a suspect card
    But I should see "Full Name"
    And I should see "CHOOSE FROM DB"

  Scenario:
    As an officer
    I want to search for suspects by their ID
    Because it will immediately single out a result

    Given I launch a clean instance of the app
    When I tap the "Add" button
    And I wait until I don't see a navigation bar titled "Lineups"
    Then I should see a "CHOOSE FROM DB" button

    When I tap "CHOOSE FROM DB"
    And I wait until I don't see "CHOOSE FROM DB"
    Then I should see "Suspect Search"
    And I should see "CASE ID"
    And I should see a text field marked "ID"
    And I should see a "SEARCH" button

    When I fill in text fields as follows:
      | field | text  |
      | ID    | 79668 |

    When I tap the "SEARCH" button
    And I wait to see "result"
    Then I should see a suspect card with the following information:
      | data     |
      | Daryl    |
      | Thomas   |
      | 8/7/1983 |
      | 79668    |

  Scenario:
    As an officer
    I want to input the witness' description of the perpetrator
    So I can prepare to select filler photos

    Given I launch a clean instance of the app
    When I tap the "Add" button
    And I wait until I don't see a navigation bar titled "Lineups"
    And I should see a "ADD DESCRIPTION" button
    And I focus on the text field marked "Case ID" and type "837523"

    When I tap "ADD DESCRIPTION"
    And I wait until I don't see "ADD DESCRIPTION"
    Then I should see a navigation bar titled "Witness Description of Perpetrator"
    And I should see exactly "Witness Description:"
    And I should see "Case ID"
    And I should see "837523"
    And I should see "Sex"
    And I should see "Race"
    And I should see "Age"
    And I should see "Hair"
    And I should see "Eyes"
    And I should see "Height"
    And I should see "Weight"
    And I should see "Notes"

    When I tap "Add Additional Notes"
    And I wait until I don't see "Add Additional Notes"

    Then I should see a navigation bar titled "Additional Notes for Witness Description of Perpetrator"
    And I should see "Case ID"
    And I should see "837523"
    And I should see "Witness Description"

    When I focus on the text view marked "Additional Notes" and type "has a badass tattoo"
    And I navigate back
    And I wait until I don't see "Additional Notes for Witness Description of Perpetrator"
    Then I should see "Witness said: “has a badass tattoo”"

    When I navigate back
    And I wait until I don't see "Witness Description of Perpetrator"
    Then I should see "Witness said: “has a badass tattoo”"
