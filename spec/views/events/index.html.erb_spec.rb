require 'rails_helper'

RSpec.describe "events/index", type: :view do
  before(:each) do
    assign(:events, [
      Event.create!(
        :name => "MyText",
        :location => "MyText",
        :loc_lat => 2.5,
        :loc_lon => 3.5,
        :hashtags => "MyText"
      ),
      Event.create!(
        :name => "MyText",
        :location => "MyText",
        :loc_lat => 2.5,
        :loc_lon => 3.5,
        :hashtags => "MyText"
      )
    ])
  end

  it "renders a list of events" do
    render
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 2.5.to_s, :count => 2
    assert_select "tr>td", :text => 3.5.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
