require 'rails_helper'

RSpec.describe AddImageHelper, type: :helper do
  context 'albums' do
    before do
      @user = User.from_omniauth(build_omniauth('test_user'))
      @event = @user.events.create(name: 'test')
      @album = @event.albums.create(name: 'test')
    end

    it 'should assign images' do
      i = Image.create(user_id: @user.id, event_id: @event.id)

      @album.add_image(i)

      i.reload

      expect(i.album_id).to eq(@album.id)
    end

    it 'should duplicate images already assigned' do
      i = Image.create(user_id: @user.id,
                       event_id: @event.id,
                       album_id: @album.id)

      a = @event.albums.create(name: 'test 2')

      a.add_image(i)

      i.reload

      expect(i.id).to_not eq(a.images.first.id)
      expect(i.album_id).to_not eq(a.id)
      expect(i.album_id).to eq(@album.id)
    end

    it 'should not duplicate an already attached image' do
      i = Image.create(user_id: @user.id,
                       event_id: @event.id,
                       album_id: @album.id)

      @album.add_image(i)

      i.reload

      expect(@album.images).to include(i)
      expect(@album.images.size).to eq(1)
    end
  end

  context 'events' do
    before do
      @user = User.from_omniauth(build_omniauth('test_user'))
      @event = @user.events.create(name: 'test')
    end

    it 'should assign images' do
      i = Image.create(user_id: @user.id)

      @event.add_image(i)

      expect(i.event_id).to eq(@event.id)
    end

    it 'should duplicate images already assigned' do
      i = Image.create(user_id: @user.id,
                       event_id: @event.id)

      e = @user.events.create(name: 'test 2')

      e.add_image(i)

      i.reload

      expect(i.id).to_not eq(e.images.first.id)
      expect(i.event_id).to_not eq(e.id)
      expect(i.event_id).to eq(@event.id)
    end

    it 'should not ducplicate an already attached image' do
      i = Image.create(user_id: @user.id,
                       event_id: @event.id)

      @event.add_image(i)

      i.reload

      expect(@event.images).to include(i)
      expect(@event.images.size).to eq(1)
    end

    it 'should detach from any albums' do
      album = @event.albums.create(name: 'test album')
      i = Image.create(user_id: @user.id,
                       event_id: @event.id,
                       album_id: album.id)

      @event.reload
      album.reload

      expect(@event.images.count).to eq(1)
      expect(album.images.count).to eq(1)

      @event.detach_image(i)

      @event.reload
      album.reload

      expect(@event.images.count).to eq(0)
      expect(album.images.count).to eq(0)
    end
  end

  after do
    Image.destroy_all
    Album.destroy_all
    Event.destroy_all
    User.destroy_all
  end
end
