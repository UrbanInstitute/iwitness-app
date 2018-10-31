Then(/^I should see a video preview$/) do
  check_element_exists("view view:'VideoPreviewView' marked:'VideoPreview'")
end

Then(/^I should see an audio level meter$/) do
  check_element_exists("view view:'AudioLevelIndicatorView' marked:'AudioLevelIndicator'")
end

Then(/^I should wait to see a movie player$/) do
  wait_until(:timeout => 10, :message => "waited to see a movie player"){
    element_exists("view:'MPMovieView'")
  }
end

Then(/^I should see the instruction video playing$/) do
  wait_until(:timeout => 10, :message => "waited to see a movie player"){
    element_exists("view:'PlayerView'")
  }
end

Then(/^I should see subtitles reading "([^\"]*)"$/) do |subtitle_text|
  quote = get_selector_quote(subtitle_text)
  wait_until(:message => "waited to see subtitles reading #{quote}#{subtitle_text}#{quote}"){
    view_with_mark_exists(subtitle_text)
  }
end
