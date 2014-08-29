// makes a node draggable and creates the onclick and 
var addNodeToGraph = function(node){
  var node_id = node.attr("data-node-id");
  var node_html_id = node.attr("id");
  
  // make the node draggable
  jsPlumb.draggable(node_html_id);
  var endpoints = addNodeEndpoints(node_html_id);
  
  // bind the doubleclick to the attribute filter opening button
  endpoints[endpoints.length - 1].bind("dblclick", function(endpoint) {
    // only perform actions, when there is no filter present
    if(endpoint.connections.length == 0) {
      addAttributeFilter(node_id, createNodeAttributeFilter(endpoint, node_id));
    }
  });
  
  // insert an onchange handler for the node's type selector
  node.find("#node_rdf_type").change(function(event){
    updateConnectionsAndAttributes($(this).closest("div"));
  })
};

// adds only the endpoints to a given node without making it draggable or registering callbacks
var addNodeEndpoints = function(node_html_id){
  var endpoints = []
  endpoints.push(jsPlumb.addEndpoint(node_html_id, { anchor:[ "Perimeter", { shape:"Circle"}], deleteEndpointsOnDetach:true }, connectionEndpoint()));
  endpoints.push(jsPlumb.addEndpoint(node_html_id, attributeEndpoint()));
  return endpoints;
};

// creates the relations and attribute constraint thingies
var loadExistingConnections = function(connect_them, load_attributes, make_static){
  requests = []
  $(connect_them).each(function(index, el){
	  var free_source = freeRelationEndpointOn("node_" + el.source);
	  var free_target = freeRelationEndpointOn("node_" + el.target);
	  var connection = jsPlumb.connect({source: free_source, target: free_target, deleteEndpointsOnDetach:true});
	  requests.push(createConnection(connection, true, el.url));
	});
	
	for (var node_id in load_attributes){
    var endpoint = jsPlumb.getEndpoints("node_" + node_id)[1];
    var more_link = createNodeAttributeFilter(endpoint, node_id, make_static);
    for (var i in load_attributes[node_id]){      
      requests.push(addAttributeFilter(node_id, more_link, load_attributes[node_id][i]));
    }
  }
  return requests;
};

// handler for the 'save' button. basically submits all forms
var savePattern = function(){
  var requests = saveNodes();
  // all forms that edit_*_constraints (you get the hint) are submitted
  $("form[class*=edit_][class*=_constraint]").each(function(index){
    requests.push(submitAndHighlight($(this)));
  });
  $.when.apply($, requests).done(function(){
    submitAndHighlight($("form[class=edit_pattern]")); 
  });
};

// sets position variables for each node and submits the form
var saveNodes = function(){
  var requests = [];
  $("form[class=edit_node]").each(function(index){
    var position = $(this).parent().position()
    $(this).find("input[id=node_x]").val(position.left);
    $(this).find("input[id=node_y]").val(position.top);
    requests.push(submitAndHighlight($(this)));
  });
  return requests
};

var removeAttributeConstraint = function(url, div_id){
  $.ajax({
    url: url,
    method: 'DELETE',
    success: function(data, textStatus, jqXHR){
      $("#" + div_id).remove();
    }
  })
};

var openComplexDialog = function(url, modal_tree, modal){
  $.ajax({
    url: url, 
    success: function(data, textStatus, jqXHR){
      modal_tree.html(data);
      modal.modal('show');
    }
  });
};

// submits the form and highlights possible errors
var submitAndHighlight = function(form){
  return $.ajax({
    url : form.attr("action"),
    type: "POST",
    data : form.serialize(),
    success: function(data, textStatus, jqXHR){
      if(data.message){alert(data.message)};
    },
    error: function(jqXHR, textStatus, errorThrown){
      alert(jqXHR);
    }
  });
};

// updates all connections of a node upon change of the node class
var updateConnectionsAndAttributes = function(node){
  var node_id = node.attr("id")
  $(jsPlumb.getConnections("relations")).each(function(index, connection){
    if(connection.sourceId == node_id || connection.targetId == node_id){    
      var overlay = $(connection.getOverlay("customOverlay").getElement());
      var update_url = overlay.find("form").attr("action");
      var params = { source_type: rdfTypeForHTMLNode(connection.sourceId), target_type: rdfTypeForHTMLNode(connection.targetId)};
      $.get(update_url, params, function(data) {overlay.html(data);});
    }
  })
};

// creates a connection between two endpoints
var createConnection = function(connection, reinstall_endpoints, url) {
  // reinstall the endpoints
  if(reinstall_endpoints){
    jsPlumb.addEndpoint(connection.source, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());
    jsPlumb.addEndpoint(connection.target, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());        
  }
  
  var overlay = $(connection.getOverlay("customOverlay").getElement())

  // get the available relations from the server oder simply load the existing one
  if(url){
    return $.ajax({url: url, success: function(data){
      overlay.html(data)}
    });  
  } else {
    return createNewConnection(connection, overlay)
  }
};

var createNewConnection = function(connection, overlay){
  return $.ajax({
    url: new_relation_constraint_path,
    type: "POST",
    data: {
      source_id: $(connection.source).attr("data-node-id"), 
      target_id: $(connection.target).attr("data-node-id"),
      source_type: rdfTypeForHTMLNode(connection.sourceId), 
      target_type: rdfTypeForHTMLNode(connection.targetId),
    },
    success: function(data) {
      overlay.html(data);
    }
  });  
};

// handler for detaching connections
jsPlumb.bind("connectionDetached", function(info, originalEvent){
  if(info.connection.scope == "relations"){
    var delete_me_link = $(info.connection.getOverlays()[0].canvas).find("form[class='edit_relation_constraint']").attr("action");
    if(delete_me_link != undefined){
      $.ajax({url: delete_me_link, method: "DELETE"});
    };
  } else {
    $(info.connection.target).find("form").each(function(i, form){
      $.ajax({url: $(form).attr("action"), method: "DELETE"});      
    })
  }
});

// creates the box-nodes for attribute filtering
var createNodeAttributeFilter = function(endpoint, node_id, make_static) {
  // build the div
  var node_html_id = "node_" + node_id + "_attributes";
  var node_class = "attribute_constraints";
  if(make_static == true){
    node_class += " static";
  }
  var attributeFilter = "<div id='" + node_html_id  + "' class='" + node_class + "' style='left: ";
  attributeFilter += (endpoint.canvas.offsetLeft + 3) + "px; top: " + (endpoint.canvas.offsetTop - 120) + "px;'></div>";
  
  // make the div draggable and connect it to the node
  $("#drawing_canvas").append(attributeFilter);  
  
  var ae = jsPlumb.addEndpoint(node_html_id, { anchor:[ "BottomLeft"] }, attributeEndpoint());
  jsPlumb.connect({source: endpoint, target: ae, deleteEndpointsOnDetach:true});  
  
  // create the '+ add filter' link at the bottom of the div
  var more_link;
  
  if(make_static != true){
    jsPlumb.draggable(node_html_id);    
    more_link = jQuery('<a/>',{
      id: "append_attribute_filter_" + node_id,
      href: "#",
      text: "+ add filter"
    });  
    more_link.click(function(){addAttributeFilter(node_id, more_link)});    
  } else {
    more_link = jQuery("<span></span>");
  };
  
  more_link.appendTo($("#" + node_html_id));  
  return more_link;
};

// call the backend and retrieve the next attribute filter line
var addAttributeFilter = function(node_id, bottom, url) {
  if(url){
    return $.ajax({url: url, success: function(data) {$(data).insertBefore(bottom)}})
  } else {
    return $.ajax({
      url: new_attribute_constraint_path,
      type: "POST",
      data: {node_id: node_id, rdf_type: rdfTypeForNode(node_id)},
      success: function(data) {
        $(data).insertBefore(bottom);
      }
    });    
  }
};

// removes a node from the graph
var deleteNode = function(node){
  if(confirm("Really delete the node and all of its connections?") == false) return;
  
  var delete_url = node.find("form").attr("action");
  var node_id = node.attr("id");

  // remove all relations
  var connections = jsPlumb.getConnections({scope:["relations", "attributes"]});
  $(connections["relations"]).each(function(i, connection){
    if(connection.sourceId == node_id || connection.targetId == node_id){      
      jsPlumb.detach(connection);
    }
  });

  $(connections["attributes"]).each(function(i, connection){
    if(connection.sourceId == node_id){
      var target = $(connection.target);
      jsPlumb.detach(connection);      
      target.remove();
    }
  });
  
  $.ajax({url: delete_url, method: "DELETE", success: function(data){
    $(jsPlumb.getEndpoints(node_id)).each(function(i, endpoint){jsPlumb.deleteEndpoint(endpoint)});
    node.remove();
  }});
};

// returns the rdf type value for a node
var rdfTypeForNode = function(node_id) {
  return $("#node_" + node_id).find("select").val();
};

var rdfTypeForHTMLNode = function(node_html_id){
  return $("#" + node_html_id).find("select").val();
};

// highlights a type selector upon click
var highlightSelector = function(element) {
  $("li.type_expression").each(function(i, ts){
    $(ts).removeClass("highlighted");
  });
  element.addClass("highlighted");
};

// adds a type expression above, below, or on the same level as the selected_element (determined by url)
// for simplicity, we simply redraw the entire tree instead of fiddling with the DOM
var addTypeExpression = function(url,selected_element, list, operator){
  var requests = [];  
  if(selected_element.length == 1){
    var target_url = url.replace("XXX", selected_element.attr("data-id"));
    // save each type expression in this list
    $.when.apply($, saveAllTypeExpressions(list)).done(function(){
      $.ajax({url: target_url, data: {operator: operator}, type: "POST", success: function(data){
        $(list).html(data);}
      });
    });
  } else {
    alert("You have to select an element before altering the tree!");
  }
};

var saveAllTypeExpressions = function(list){
  var requests = []
  list.find(".edit_type_expression").each(function(i,form){
    requests.push(submitAndHighlight($(form)));
  });
  return requests;
};

var saveTypeExpressions = function(list, fancy_string_url, node_rdf_type_selector, modal){
  $.when.apply($, saveAllTypeExpressions(list)).done(function(){
    $.ajax({url: fancy_string_url, success: function(data){
      var new_option = $(data);
      var old_option = node_rdf_type_selector.find("option[id=" + new_option.attr("id") + "]");
      if(old_option.length == 0){
        node_rdf_type_selector.append(data);
      } else {
        old_option.html(new_option);
      }
      modal.modal("hide");
      }
    })
  });
};

var freeRelationEndpointOn = function(node_html_id){
  var endpoints = jsPlumb.getEndpoints(node_html_id);
  var free_endpoint;
  $(endpoints).each(function(i,e){
    if(e.scope == "relations"){free_endpoint = e}
  });
  return free_endpoint  
};

// encapsulates the enpoint options for the orange connection thingies
var connectionEndpoint = function() {
  return {
		endpoint:["Dot", {radius:4} ],
		paintStyle:{ fillStyle:"#ffa500", opacity:0.5 },
		isSource: true,
    deleteEndpointsOnDetach:true,				
		scope: "relations",
		connectorStyle:{ strokeStyle:"#ffa500", lineWidth:3 },
		connectorOverlays:[
      ["Custom", {
        create: function(component) {
          return $("<div class='relation'><select></select></div>");
        },
        location:0.5,
        id:"customOverlay"
      }],		
		  ["Arrow",{ width:10, location:1, length:20, id:"arrow" }]
		],
		connector : "Straight",
		isTarget:true,
    dropOptions : {
  		tolerance:"touch",
  		hoverClass:"dropHover",
  		activeClass:"dragActive"
  	}
	};
};

// same for the attribute endpoints
var attributeEndpoint = function() {
  return {
		endpoint:["Rectangle", {width:6, height:6} ],
		anchor: ["Top"],
		paintStyle:{ fillStyle:"#0087CF", opacity:0.5 },
		scope: "attributes",
		connectorStyle:{ strokeStyle:"#0087CF", lineWidth:3 },		
		connector : "Straight"
	};
};