When /^I tap "([^\"]*)"$/ do |mark|
  quote = get_selector_quote(mark)
  selector = "view marked:#{quote}#{mark}#{quote} first"

  wait_until(:message => "waited to touch #{quote}#{mark}#{quote} successfully, but couldn't") {
    touch(selector).last
  }
end

When(/^I tap the "(.*?)" accessory view$/) do |button_name|
  quote = get_selector_quote(button_name)
  wait_until(:message => "waited to touch accessory view marked exactly #{quote}#{button_name}#{quote}"){
    begin
      touch("view:'UITableViewCellEditControl' marked:#{quote}#{button_name}#{quote}").last
    rescue
      false
    end
  }
end

When /^I swipe (left|right|up|down)wards$/ do |direction|
  frankly_map( "view", 'swipeInDirection:', direction )
end
