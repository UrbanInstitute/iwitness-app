When /^I tap the first collection view cell$/ do
  touch("view:\"UICollectionViewCell\" first")
end

When /^I tap the collection view cell marked "([^\"]*)"$/ do |mark|
  quote = get_selector_quote(mark)
  touch("collectionViewCell marked:#{quote}#{mark}#{quote}")
end

When /^I tap the (\d*)(?:st|nd|rd|th)? collection view cell$/ do |ordinal|
  ordinal = ordinal.to_i - 1
  touch("view:'UICollectionViewCell' index:#{ordinal}")
end

When(/^I tap the portrayal with the date "(.*?)"$/) do |date|
  touch("view:'SuspectPortrayalCell' marked:'#{date}'")
end

