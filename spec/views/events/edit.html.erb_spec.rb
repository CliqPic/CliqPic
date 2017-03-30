require 'rails_helper'

RSpec.describe "events/edit", type: :view do
  before(:each) do
    @event = assign(:event, Event.create!(
      :name => "MyText",
      :location => "MyText",
      :loc_lat => 1.5,
      :loc_lon => 1.5,
      :hashtags => "MyText"
    ))
  end

  it "renders the edit event form" do
    render

    assert_select "form[action=?][method=?]", event_path(@event), "post" do

      assert_select "textarea#event_name[name=?]", "event[name]"

      assert_select "textarea#event_location[name=?]", "event[location]"

      assert_select "input#event_loc_lat[name=?]", "event[loc_lat]"

      assert_select "input#event_loc_lon[name=?]", "event[loc_lon]"

      assert_select "textarea#event_hashtags[name=?]", "event[hashtags]"
    end
  end
end
