require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Chat, "index action" do
  before(:each) do
    dispatch_to(Chat, :index)
  end
end