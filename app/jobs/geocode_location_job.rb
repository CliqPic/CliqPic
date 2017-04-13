class GeocodeLocationJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find event_id

    provider = Geokit::Geocoders.const_get(ENV['GEOKIT_PROVIDER'])

    geo = provider.geocode(event.location)

    return event.queue_image_processor if geo.ll == ','

    event.loc_lat = geo.lat
    event.loc_lon = geo.lng

    event.save
  end
end
