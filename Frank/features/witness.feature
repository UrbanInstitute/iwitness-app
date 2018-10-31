Feature:
  As an eyewitness
  I need to view the lineup presentation
  So that I can identify the perp

  Scenario:
    Witness changes presentation language

    Given I launch a clean instance of the app
    And the device is in portrait orientation
    And there is a valid lineup configured
    And I expand the lineup cell with case ID "12345-6789"
    And I tap "PRESENT TO WITNESS"
    And I wait until I don't see "PRESENT TO WITNESS"
    And I tap "BEGIN"
    And I wait until I don't see "BEGIN"
    And I tap "NEXT →"
    And I wait until I don't see "SPEAK NOW"
    Then I should see a "ENGLISH" button

    When I tap "ENGLISH"
    Then I should see a popover table view with the following items:
      | English           |
      | español - Spanish |

    When I tap "español - Spanish"
    And I wait for the popover to be dismissed
    And I wait to not see "ENGLISH"
    Then I should see a "ESPAÑOL - SPANISH" button
    And I should see "NEXT →"
    But I should not see "ENGLISH"

    When I tap "NEXT →"
    And I wait to not see "NEXT →"
    Then I should see "Por favor diga su nombre para el registro y luego pulse el botón “Siguiente →” abajo."

    When I tap "SIGUIENTE →"
    Then I should see subtitles reading "El gato español"

  Scenario:
    Witness starts presentation

    Given I launch a clean instance of the app
    And the device is in portrait orientation
    And there is a valid lineup configured
    And I expand the lineup cell with case ID "12345-6789"
    And I tap "PRESENT TO WITNESS"
    And I wait until I don't see "PRESENT TO WITNESS"
    Then I should see a "BEGIN" button
    And I should see "Officer Identification"
    And I should see an interface locked to portrait

    When I tap "BEGIN"
    And I wait until I don't see "BEGIN"
    Then I should see a "NEXT →" button
    And I should see "SPEAK NOW"
    And I should see an audio level meter
    And I should see "Please state your name, the date, and the location."

    When I tap "NEXT →"
    And I wait until I don't see "SPEAK NOW"
    Then I should see a "NEXT →" button
    And I should see "RECORDING"
    And I should see an audio level meter
    And I should see "Select a language and frame the witness within the oval. When the witness is ready, tap “Next →” and move out of sight of the screen."
    And I should see a "ENGLISH" button

    When I tap "NEXT →"
    And I wait until I don't see "RECORDING"
    Then I should see a "NEXT →" button
    And I should see "SPEAK NOW"
    And I should see an audio level meter
    And I should see "Please state your name for the record"

    When I tap "NEXT →"
    And I wait until I don't see "NEXT →"
    Then I should see the instruction video playing
    And I should see a disabled "I UNDERSTAND" button
    And I should see subtitles reading "Dangling cat is dangling"

    When I wait for the "I UNDERSTAND" button to be enabled
    And I tap the "I UNDERSTAND" button
    And I wait until I don't see "Do you understand these instructions?"
    Then I should see "Please state whether you recognize this person."
    And I should not see the status bar
    And I should see a mugshot photo
    And I should see exactly "1"
    And I should see a disabled witness response selector with the following options:
      | YES      |
      | NO       |
      | NOT SURE |

    When I wait for the witness response selector to be enabled
    And I select the "NO" response
    Then I wait to see "You stated you do not recognize this person; tap “Next →” to move to the next photo."
    And I should see an audio level meter
    And I should see a "NEXT →" button

    When I wait for the "NEXT →" button to be enabled
    And I tap the "NEXT →" button
    Then I wait until I don't see "You stated you do not recognize this person; tap “Next →” to move to the next photo."
    And I should not see "NEXT →"

    Then I should see "Please state whether you recognize this person."
    And I should see a mugshot photo
    And I should see exactly "2"

  Scenario:
    Witness completes presentation

    Given I've started a presentation as a witness

    When I have responded to every photo
    Then I should see "Presentation Complete."
    And I should see "Officer Password"
    And I should see a "PROCEED" button

    When I tap the "PROCEED" button
    Then I should see "* Incorrect"

    When I type "ewid" into the text field marked "Officer Password"
    And I tap the "PROCEED" button

    Then I should see "REPLAY"
    And I should see "FINISH"

    When I tap the "FINISH" button
    Then I wait to see "Lineups"

  Scenario:
    Witness affirms they would like to replay presentation

    Given I've started a presentation as a witness

    When I have responded to every photo
    Then I should see "Presentation Complete."
    And I should see "Officer Password"
    And I should see a "PROCEED" button

    When I type "ewid" into the text field marked "Officer Password"
    And I tap the "PROCEED" button

    Then I should see "REPLAY"
    And I should see "FINISH"

    When I tap the "REPLAY" button
    And I wait to not see "REPLAY"
    Then I should see a mugshot photo
    And I should see exactly "1"

    When I have responded to every photo
    Then I should see "Presentation Complete."

  Scenario:
    Witness claims they don't know the person

    Given I've started a presentation as a witness

    When I wait for the witness response selector to be enabled
    And I select the "NO" response
    Then I wait to see "You stated you do not recognize this person; tap “Next →” to move to the next photo."
    And I should see an audio level meter
    And I should see a "NEXT →" button
    And I should see "RECORDING"
    But I should not see "SPEAK NOW"

    When I tap the "NEXT →" button
    And I wait until I don't see "You stated you do not recognize this person; tap “Next →” to move to the next photo."
    Then I should not see "NEXT →"

  Scenario:
    Witness claims they are unsure that they know the person

    Given I've started a presentation as a witness

    When I wait for the witness response selector to be enabled
    And I select the "NOT SURE" response
    Then I wait to see "Please explain."
    And I should see an audio level meter
    And I should see a disabled "NEXT →" button
    And I should see "SPEAK NOW"
    But I should not see "RECORDING"

    When I wait for the "NEXT →" button to be enabled
    And I tap the "NEXT →" button
    And I wait to see "You stated you are not sure if you recognize this person; tap “Next →” to move to the next photo."
    Then I should see a disabled "NEXT →" button
    And I should see "RECORDING"
    But I should not see "SPEAK NOW"

    When I wait for the "NEXT →" button to be enabled
    And I tap the "NEXT →" button
    And I wait until I don't see "You stated you are not sure if you recognize this person; tap “Next →” to move to the next photo."
    Then I should not see "NEXT →"

  Scenario:
    Witness claims they know the person

    Given I've started a presentation as a witness

    When I wait for the witness response selector to be enabled
    And I select the "YES" response
    Then I wait to see "Please state where you recognize this person from."
    And I should see an audio level meter
    And I should see a disabled "NEXT →" button

    When I wait for the "NEXT →" button to be enabled
    And I tap the "NEXT →" button
    Then I wait to see "Please state how certain you are of this identification."
    And I should see an audio level meter
    And I should see a disabled "NEXT →" button
    And I should see "SPEAK NOW"
    But I should not see "RECORDING"

    When I wait for the "NEXT →" button to be enabled
    And I tap the "NEXT →" button
    Then I wait to see "The presentation will continue until you have reviewed all photos."
    And I should see a disabled "NEXT →" button
    And I should see "RECORDING"
    But I should not see "SPEAK NOW"

    When I wait for the "NEXT →" button to be enabled
    And I tap the "NEXT →" button
    And I wait until I don't see "The presentation will continue until you have reviewed all photos."
    And I should not see "NEXT →"

