require 'rails_helper'

RSpec.describe "albums/new", type: :view do
  before(:each) do
    assign(:album, Album.new(
      :name => "MyText",
      :event => nil
    ))
  end

  it "renders new album form" do
    render

    assert_select "form[action=?][method=?]", albums_path, "post" do

      assert_select "textarea#album_name[name=?]", "album[name]"

      assert_select "input#album_event_id[name=?]", "album[event_id]"
    end
  end
end
