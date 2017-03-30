json.extract! event, :id, :name, :start_time, :end_time, :location, :loc_lat, :loc_lon, :hashtags, :created_at, :updated_at
json.url event_url(event, format: :json)
