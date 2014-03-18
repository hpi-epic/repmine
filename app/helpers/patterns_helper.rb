module PatternsHelper
  def uri_for_res(date)
    return date["data"]["html_url"] || date["data"]["link"] || date["data"]["url"]
  end
  
  def name_for_res(date)
    return date["data"]["title"]
  end
  
  def type_select(type_hierarchy)
    return [
      ["Class1", [["SC1", 1], ["SC2", 2]]],
      ["Class2", 3],
      ["Class3", [["SC3", 4]]]
    ]
    #type_hierarchy.keys.sort.each do |key|
    #  select << [key, ]
    #end
    
  end  
end
