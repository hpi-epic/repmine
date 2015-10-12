sentiment_service = Service.where(:url => "http://localhost:5000/sentiment").first_or_create
sentiment_service.service_parameters.where({
  :name => "text",
  :datatype_cd => ServiceParameter.datatypes[:string],
  :is_collection => false
}).first_or_create