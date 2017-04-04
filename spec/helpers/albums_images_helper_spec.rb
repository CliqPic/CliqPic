require 'rails_helper'

RSpec.describe AlbumsImageHelper, type: :helper do
  before do
    @user = User.from_omniauth(OpenStruct.new(uid: 'test_user'))
    @event = @user.events.create(name: 'test')
    @album = @event.albums.create(name: 'test')
  end

  it 'should assign images to an album' do
    i = Image.create(user_id: @user.id, event_id: @event.id)

    @album.send(:add_image, i)

    i.reload

    expect(i.album_id).to eq(@album.id)
  end

  it 'should duplicate images already assigned to an album' do
    i = Image.create(user_id: @user.id,
                     event_id: @event.id,
                     album_id: @album.id)

    a = @event.albums.create(name: 'test 2')

    a.send(:add_image, i)

    i.reload

    expect(i.id).to_not eq(a.images.first.id)
    expect(i.album_id).to_not eq(a.id)
    expect(i.album_id).to eq(@album.id)
  end

  it 'should not duplicate an image already on the album' do
    i = Image.create(user_id: @user.id,
                     event_id: @event.id,
                     album_id: @album.id)

    @album.send(:add_image, i)

    i.reload

    expect(@album.images).to include(i)
    expect(@album.images.size).to eq(1)
  end

  after do
    Image.destroy_all
    Album.destroy_all
    Event.destroy_all
    User.destroy_all
  end
end
