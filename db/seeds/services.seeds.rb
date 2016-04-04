sentiment_service = Service.where(url: "http://localhost:5000/sentiment", name: "Sentiment Analysis").first_or_create
sentiment_service.input_parameters.where({
  :name => "text",
  :datatype_cd => ServiceParameter.datatypes[:string]
}).first_or_create
sentiment_service.output_parameters.where({
  :name => "sentiment",
  :datatype_cd => ServiceParameter.datatypes[:integer]
}).first_or_create

location_service = Service.where(url: "http://localhost:6000/geolocate", name: "Geolocation").first_or_create
location_service.input_parameters.where({
  :name => "search_string",
  :datatype_cd => ServiceParameter.datatypes[:string]
}).first_or_create
location_service.output_parameters.where({
  :name => "latitude",
  :datatype_cd => ServiceParameter.datatypes[:float]
}).first_or_create
location_service.output_parameters.where({
  :name => "longitude",
  :datatype_cd => ServiceParameter.datatypes[:float]
}).first_or_create