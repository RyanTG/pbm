json.regions @regions.each do |json, region|
  json.region do
    json.id region.id
    json.name region.name
    json.formalName region.full_name
    json.subdir region.name
    json.lat region.lat
    json.lon region.lon
    json.nSearchNo region.n_search_no
    json.motd region.motd
  end
end
