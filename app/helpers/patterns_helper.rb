module PatternsHelper
  def uri_for_res(date)
    return date["data"]["html_url"] || date["data"]["link"] || date["data"]["url"]
  end
  
  def name_for_res(date)
    return date["data"]["title"]
  end

end
