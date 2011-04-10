Feature: add a high score for a machine
  In order to add high scores to machines
  As a guest
  I want to be able to add high scores to machines

  @javascript
  Scenario: Don't show add new score unless you are logged in
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should not see "Add Scores At This Location"

  @javascript
  Scenario: Add a new high score to a machine
    Given I am a logged in user
    And there is a location machine xref
    And today is 02/05/2011
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I click on the add scores link for "Test Location Name"
    And I fill in a score of "1234" and rank "GC"
    And I wait for 1 seconds
    And I press "add_score"
    And I wait for 1 seconds
    Then "Test Location Name"'s "Test Machine Name" should have a score with score "1234" and rank "1"
    And I should see "Rank: GC Initials: cap Score 1234 Date 02-05-2011"
