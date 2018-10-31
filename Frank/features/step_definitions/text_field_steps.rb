# The following steps seem to no longer be built in to Frank

Then /^I should see a text field marked "(.*?)"$/  do |field_mark|
  check_element_exists "textField marked:'#{field_mark}'"
end

When /^I type "([^\"]*)" into the text field marked "([^\"]*)"$/ do |text_to_type, field_mark|
  text_fields_modified = frankly_map( "textField marked:'#{field_mark}'", "setText:", text_to_type )
  raise "could not find text fields with mark '#{field_mark}'" if text_fields_modified.empty?
  #TODO raise warning if text_fields_modified.count > 1
end

When /^I focus on the text (field|view) marked "([^\"]*)" and type "([^\"]*)"$/ do |element, field_mark, text_to_type|
  touch("view:'UIText#{element.capitalize}' marked:'#{field_mark}'")
  sleep 0.25
  type_into_keyboard text_to_type, :append_return => false
end

When /^I fill in text fields as follows:$/ do |table|
  table.hashes.each do |row|
    step %Q|I type "#{row['text']}" into the text field marked "#{row['field']}"|
  end
end


