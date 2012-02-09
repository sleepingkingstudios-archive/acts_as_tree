# spec/support/have_method_matcher.rb

RSpec::Matchers.define :have_method do |expected|
  match do |actual|
    actual.methods.include? expected
  end # match

  failure_message_for_should do |actual|
    "expected that #{actual} would have method #{expected.inspect}"
  end # failure message for should

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have method #{expected.inspect}"
  end # failure message for should not

  description do
    "have method #{expected}"
  end # description
end # define :have_method
