require 'rails_helper'

RSpec.describe "albums/edit", type: :view do
  before(:each) do
    @album = assign(:album, Album.create!(
      :name => "MyText",
      :event => nil
    ))
  end

  it "renders the edit album form" do
    render

    assert_select "form[action=?][method=?]", album_path(@album), "post" do

      assert_select "textarea#album_name[name=?]", "album[name]"

      assert_select "input#album_event_id[name=?]", "album[event_id]"
    end
  end
end
