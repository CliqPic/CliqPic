require 'rails_helper'

RSpec.describe ProcessImageToEventJob, type: :job do
  before do
    @user = User.from_omniauth(build_omniauth('test_user'))
  end

  context 'attaching' do
    context 'single matchers' do
      context 'hashtags' do
        it 'should match when the hashtags are identical' do
          event = @user.events.create(name: 'test event',
                                      hashtags: 'test')
          image = @user.images.create(hashtags: 'test')

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to eq(event.id)
        end

        it 'should match when the event\'s hashtags are a subset of the images hashtags' do
          event = @user.events.create(name: 'test event',
                                      hashtags: 'test')
          image = @user.images.create(hashtags: 'test,foo,bar')

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to eq(event.id)
        end

        it 'should not match when the image does not have all the event\'s hashtags' do
          event = @user.events.create(name: 'test event',
                                      hashtags: 'test,foo')
          image = @user.images.create(hashtags: 'test')

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to be_nil
        end

        it 'should not match if the image has no hashtags' do
          event = @user.events.create(name: 'test event',
                                      hashtags: 'test,foo')
          image = @user.images.create

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to be_nil
        end
      end

      context 'location' do
        # This test isn't well matched to reality
        it 'should match when the locations are identical' do
          event = @user.events.create(name: 'test event',
                                      loc_lat: 1,
                                      loc_lon: 1)
          image = @user.images.create(lat: 1, lon: 1)

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to eq(event.id)
        end      

        it 'should match when the locations are near each other' do
          event = @user.events.create(name: 'test event',
                                      loc_lat: 1,
                                      loc_lon: 1)
          image = @user.images.create(lat: 1.005, lon: 1.005)

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to eq(event.id)
        end

        it 'should not match when the locations are far from each other' do
          # Small differences in latitude/longitude map to large absolute distances
          event = @user.events.create(name: 'test event',
                                      loc_lat: 1,
                                      loc_lon: 1)
          image = @user.images.create(lat: 10, lon: 10)

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to be_nil
        end

        it 'should not match on images with no location' do
          # Small differences in latitude/longitude map to large absolute distances
          event = @user.events.create(name: 'test event',
                                      loc_lat: 1,
                                      loc_lon: 1)
          image = @user.images.create

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to be_nil
        end
      end

      context 'date range' do
        it 'should match on dates within the event\'s range' do
          event = @user.events.create(name: 'test event',
                                      start_time: 15.minutes.ago,
                                      end_time: 5.minutes.ago)
          image = @user.images.create(created_on_instagram_at: 10.minutes.ago)

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to eq(event.id)
        end

        it 'should not match on dates outside the event\'s range' do
          event = @user.events.create(name: 'test event',
                                      start_time: 15.minutes.ago,
                                      end_time: 5.minutes.ago)
          image = @user.images.create(created_on_instagram_at: 20.minutes.ago)

          ProcessImageToEventJob.new.perform(image.id, event.id)

          event.reload
          image.reload

          expect(image.event_id).to be_nil
        end

        # I think it's safe to assume that all images will have some kind of
        # creation timestamp
      end
    end

    context 'multiple matchers' do
      it 'should match when all requirements are met' do
        event = @user.events.create(name: 'test event',
                                    hashtags: 'foo',
                                    start_time: 15.minutes.ago,
                                    end_time: 5.minutes.ago)
        image = @user.images.create(hashtags: 'foo',
                                    created_on_instagram_at: 10.minutes.ago)

        ProcessImageToEventJob.new.perform(image.id, event.id)

        event.reload
        image.reload

        expect(image.event_id).to eq(event.id)
      end

      it 'should not match when not all requirements are met' do
        event = @user.events.create(name: 'test event',
                                    hashtags: 'foo',
                                    start_time: 15.minutes.ago,
                                    end_time: 5.minutes.ago)
        image = @user.images.create(created_on_instagram_at: 10.minutes.ago)

        ProcessImageToEventJob.new.perform(image.id, event.id)

        event.reload
        image.reload

        expect(image.event_id).to be_nil
      end
    end
  end

  context 'detaching' do
    it 'should remove images that no longer meet the requirements' do
      event = @user.events.create(name: 'test event',
                                  hashtags: 'foo,bar')
      image = @user.images.create(event_id: event.id)

      ProcessImageToEventJob.new.perform(image.id, event.id)

      event.reload
      image.reload

      expect(image.event_id).to be_nil
    end
  end

  after do
    Image.destroy_all
    Album.destroy_all
    Event.destroy_all
    User.destroy_all
  end
end
