class GeocodeLocationJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find event_id

    provider = Geokit::Geocoders.const_get(ENV['GEOKIT_PROVIDER'])

    geo = provider.geocode(event.location)

    return event.queue_image_processor if geo.ll == ','

    event.loc_lat = geo.lat
    event.loc_lon = geo.lng

    lon_lat_actually_changed = event.picture_inclusion_data_changed?
    event.queue_image_processor if !lon_lat_actually_changed
    event.save
    # If you adjust your address but returns same lot/lat
    # then image processor doesnt get queued ons ave,
    # and then event never leaves the "queueing" mode
    # We want any address change to trigger a rescrape.
  end
end
