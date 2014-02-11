class HanaConnection
  
  def connection
    return ActiveRecord::Base.establish_connection(RepMine::Application.config.database_configuration["hana"]).connection
  end
  
  TYPE_MAPPING = {
    RDF::XSD.string.to_s => 0,
    RDF::XSD.integer.to_s => 2,
    RDF::XSD.dateTime.to_s => 2,
    RDF::XSD.boolean.to_s => 5    
  }
  
  WORKSPACE = "uri:dstoreWS"
  TAXONOMY = "uri:dstoreTAX"
  
  ATTRIBUTE_BLACKLIST = [
    "http://hpiweb.de/ontologies/collaboration/github/commits/files/patch"
  ]
  
  # TODO: use the real ontology...
  def build_taxonomy!()
    mapping_info = Mapping.all.collect{|mapping| taxonomy_information(mapping)}
    mapping_info << taxonomy_stmt("anonymous", 5)
    tbox = "DEFINE { #{mapping_info.compact.join(", \n")}\n} IN TAXONOMY #{TAXONOMY};"
    execute_wipe(wipe_start + tbox)
  end
  
  def taxonomy_information(mapping  )
    if mapping.is_a?(NodeMapping)
      return nil
    else
      return taxonomy_stmt(mapping.resource.to_s, techtype(mapping))
    end  
  end
  
  def taxonomy_stmt(uri, techtype)
    str = "TERM {\n"
    str += "\turi:com.sap.ais.tax.core.uri = ''#{uri}'',\n"
    str += "\turi:com.sap.ais.tax.core.techtype = #{techtype}\n}"
    return str
  end
  
  def save_items(items)
    item_stmts = items.collect{|node| item_stmt_for_node(node)}
    wipe = wipe_start + "INSERT { \n"
    wipe += item_stmts.join(", \n")
    wipe += "\n\};"
    res = execute_wipe(wipe)
  end
  
  def wipe_start()
    return "USE WORKSPACE #{HanaConnection::WORKSPACE};\n"
  end
  
  def item_stmt_for_node(node)
    stmt = "ITEM {\n"
    stmt += "\turi:com.sap.ais.tax.core.uri = ''#{clean_url(node.primary_keys.first)}'',\n" unless node.primary_keys.first.nil?
    stmt += "\turi:com.sap.ais.tax.core.type = ''#{node.resource_type}'',\n"
    stmt += node.attribute_hash.collect{|name, value|
      ev = escape_value(value)
      if ev.nil? || ATTRIBUTE_BLACKLIST.include?(name)
        nil 
      else 
        "\turi:#{name} = #{ev}"
      end
    }.compact.join(", \n") 
    stmt += "\n}"
    return stmt
  end
  
  def techtype(mapping)
    if mapping.is_a?(RelationMapping)
      return 11
    else
      TYPE_MAPPING[mapping.element_type] || 9  
    end
  end
  
  def escape_value(value, for_wipe = true)
    # TODO: find out how to store long strings. probably an alter table statement..
    if value.is_a?(String)
      str = "'" + clean_string(value) + "'" 
      return for_wipe ? "'#{str}'" : str 
    # TODO: create unnamed objects for arrays of strings, integers, and the like
    elsif value.is_a?(Array)
      return nil
    else
      return value
    end    
  end
  
  def clean_string(str)
    return str if !str.is_a?(String)
    return str.gsub("\r\n", " ").gsub("\r", " ").gsub("\n", " ").gsub("'", "\"").gsub(/(<.*?>)/, "").gsub("%", "").gsub("\t", " ").gsub("\\", "")[0..600]
  end
       
  def clear_workspace!
    execute_wipe("DROP WORKSPACE #{WORKSPACE};")
    execute_wipe("CREATE WORKSPACE #{WORKSPACE};")
  end
  
  def clean_url(url)
    return url.gsub("-", "").gsub("'", "\"")
  end
  
  def merge!
    connection.execute("MERGE DELTA of INFOITEMS")
    connection.execute("MERGE DELTA of ASSOCIATIONS")
  end
  
  def lookup_uris(uris)
    select_us = "SELECT \"com.sap.ais.tax.core.uri\" FROM INFOITEMS WHERE \"com.sap.ais.tax.core.uri\" IN ("
    select_us += uris.collect{|uri| "'#{clean_url(uri)}'"}.join(",") + ")"
    return connection.select_all(select_us)
  end
  
  def lookup_node_by_attributes(node_attribs)
    select = "SELECT \"com.sap.ais.tax.core.uri\" FROM INFOITEMS WHERE "
    select += node_attribs.collect{|key, val|
      clean_val = escape_value(val, false)
      clean_val.nil? ? nil : "\"#{key}\" = #{clean_val}"
    }.compact.join(" AND ")
    return connection.select(select)
  end
  
  def get_all_anonymous_nodes(table_fields = [], limit = 200, offset = 200)
    select = "SELECT "
    select += if table_fields.empty?
      "*"
    else
      table_fields << "com.sap.ais.tax.core.uri"
      table_fields << "anonymous" unless table_fields.include?("anonymous")
      table_fields.collect{|tf| "\"#{tf}\""}.join(", ")
    end
    
    select += " FROM INFOITEMS WHERE \"anonymous\" = 1 LIMIT #{limit} OFFSET #{offset}"
    return connection.select(select)
  end
  
  def get_anonymous_node_count()
    select = "SELECT COUNT(*) AS \"number_of_nodes\" FROM INFOITEMS WHERE \"anonymous\" = 1"
    return connection.select(select).first["number_of_nodes"]
  end
  
  def create_relation_between_nodes(relation, source, targets)
    relation_stmts(relation, source, targets)
    execute_wipe(wipe_start + relation_stmts)
  end
  
  def relation_statements(relation, source, targets)
    relation_stmts = "UPDATE {uri:#{source.db_id}}\n"
    relation_stmts += targets.collect{|target|
      "SET { ASSOCIATION { uri:com.sap.ais.tax.core.type = ''#{relation}'' } TO uri:#{target.db_id} }"
    }.join(", \n")
    return relation_stmts += ";\n"
  end
    
  def execute_wipe(wipe_stmt)
    #logger.debug("Executing: " + clean_statement)
    return connection.execute("CALL WIPE('#{wipe_stmt}')")    
  end
  
end