json.array!(@units) do |unit|
  json.extract! unit, :id, :name, :unit_desc, :short_name
  json.url unit_url(unit, format: :json)
end
