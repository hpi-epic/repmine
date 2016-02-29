// makes a node draggable and creates the onclick and
var addNodeToGraph = function(node){
  var node_id = node.attr("data-id");
  var node_html_id = node.attr("id");

  // make the node draggable
  jsPlumb.draggable(node_html_id);
  var endpoints = addNodeEndpoints(node_html_id);

  // bind the doubleclick to the attribute filter opening button
  endpoints[endpoints.length - 1].bind("dblclick", function(endpoint) {
    addAttributeFilter(node_id);
  });

  // insert an onchange handler for the node's type selector
  node.find("#node_rdf_type").change(function(event){
    updateConnectionsAndAttributes($(this).closest("div"));
  });
};

// handler for pressing the 'create node' button
$("#new_pattern_node").on("ajax:success", function(e, data, status, xhr){
  var node = $(xhr.responseText);
  node.appendTo($("#drawing_canvas"));
  addNodeToGraph(node);
  $(".node select").select2({width: '90%'});
});

$("#show_query").on("ajax:success", function(e, data, status, xhr){
  var modal = $("#query_modal");
  modal.html(xhr.responseText);
  modal.modal('show');
});

var loadNodesAndConnections = function(){
	$(".node").not(".static").each(function(index,node_div){
	  addNodeToGraph($(node_div));
	});

	loadExistingConnections(connect_these_nodes, load_their_attribute_constraints);

	jsPlumb.bind("connection", function(info, originalEvent) {
	  if(info.connection.scope == "relations") {
		  buildDraggedConnection(info.connection, true);
	  }
	});
}

// adds only the endpoints to a given node without making it draggable or registering callbacks
var addNodeEndpoints = function(node_html_id){
  var endpoints = []
  endpoints.push(jsPlumb.addEndpoint(node_html_id, connectionEndpoint()));
  endpoints.push(jsPlumb.addEndpoint(node_html_id, attributeEndpoint()));
  return endpoints;
};

// creates the relations and attribute constraint thingies
var loadExistingConnections = function(connect_them, load_attributes, make_static){
  requests = []
  $(connect_them).each(function(index, el){
	  requests.push(createConnection(el.source, el.target, true, el.url));
	});

	for (var node_id in load_attributes){
    var endpoint = jsPlumb.getEndpoints("node_" + node_id)[1];
    for (var i in load_attributes[node_id]){
      requests.push(addAttributeFilter(node_id, load_attributes[node_id][i]));
    }
  }
  return requests;
};

// handler for the 'save' button. basically submits all forms
var savePattern = function(){
  var requests = saveForm("form.edit_node").concat(saveForm("form[class*=edit_][class*=_constraint]"));
  $.when.apply($, requests).done(function(){
    submitAndHighlight($("form.edit_pattern"));
  });
};

// takes a form, submits it, and stores all the requests so we can wait for ... it
var saveForm = function(form_finder){
  var requests = [];
  $(form_finder).not(".static").each(function(index){
    requests.push(submitAndHighlight($(this)));
  });
  return requests;
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
  updatePositionInformation(form);
  return $.ajax({
    url : form.attr("action"),
    type: "POST",
    data : form.serialize(),
    success: function(data, textStatus, jqXHR){
      showGrowlNotification(jqXHR);
    },
    error: function(jqXHR, textStatus, errorThrown){
      showGrowlNotification(jqXHR);
    }
  });
};

var updatePositionInformation = function(form){
  var position = $(form).parent().position();
	if($(form).find("input[id$=_x]").length > 0){
	  $(form).find("input[id$=_x]").val(position.left);
	  $(form).find("input[id$=_y]").val(position.top);
	}
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

var toggleNodeGroup = function(button, node_id){
  button.toggleClass("wicked");
  $("#" + node_id).toggleClass("double-border");
  var field = $("form[id='edit_" + node_id + "'] input[id='node_is_group']");
  field.val(field.val() === "true" ? "false" : "true");
};

var buildDraggedConnection = function(connection, rebuild_endpoints){
  var source_id = $(connection.source).attr("data-id");
  var target_id = $(connection.target).attr("data-id");
  jsPlumb.detach(connection, {fireEvent:false});
  createConnection(source_id, target_id, rebuild_endpoints);
};

// creates a connection between two endpoints
var createConnection = function(source_id, target_id, reinstall_endpoints, url) {
  // get the available relations from the server oder simply load the existing one
  if(url){
    return $.ajax({url: url, success: function(data){
      buildConnection(source_id, target_id, reinstall_endpoints, $(data));
    }});
  } else {
    return $.ajax({
      url: new_relation_constraint_path,
      type: "POST",
      data: {
        source_id: source_id,
        target_id: target_id,
        source_type: rdfTypeForHTMLNode("node_" + source_id),
        target_type: rdfTypeForHTMLNode("node_" + target_id)
      },
      success: function(data) {
        buildConnection(source_id, target_id, reinstall_endpoints, $(data));
      }
    })
  }
};

var buildConnection = function(source_id, target_id, reinstall_endpoints, overlay){
  var free_source = freeRelationEndpointOn("node_" + source_id);
  var free_target = freeRelationEndpointOn("node_" + target_id);
  var connection = jsPlumb.connect({
    source: free_source,
    target: free_target,
    deleteEndpointsOnDetach:true,
		overlays:[
      ["Custom", {
        create: function(component) {return overlay;},
        location: 0.4,
        id:"customOverlay"
      }],
		  ["Arrow",{ width:8, location:1, length:15, id:"arrow" }]
		],
    fireEvent:false
  });

  // reinstall the endpoints
  if(reinstall_endpoints){
    jsPlumb.addEndpoint(connection.source, connectionEndpoint());
    jsPlumb.addEndpoint(connection.target, connectionEndpoint());
  }
}

// handler for detaching connections
jsPlumb.bind("connectionDetached", function(info, originalEvent){
  if(info.connection.scope == "relations"){
    var delete_me_link = $(info.connection.getOverlays()[0].canvas).find("form.edit_relation_constraint").attr("action");
    if(delete_me_link != undefined){
      $.ajax({url: delete_me_link, method: "DELETE"});
    };
  }
});

var insertAttributeConstraint = function(node_id, data){
  var ac = $(data)
  if(0 === ac.attr("style").length){
    var node_position = $("#node_" + node_id).position()
    ac.css({left: node_position.left - 100, top: node_position.top - 150})
  }
  $("#drawing_canvas").append(ac);
  jsPlumb.draggable(ac);
  var ae = jsPlumb.addEndpoint(ac, { anchor:[ "BottomCenter"], deleteEndpointsOnDetach:true }, attributeEndpoint());
  jsPlumb.connect({source: jsPlumb.getEndpoints("node_" + node_id)[1], target: ae});
};

// call the backend and retrieve the next attribute filter line
var addAttributeFilter = function(node_id, url) {
  if(url){
    return $.ajax({
      url: url,
      success: function(data) {
        insertAttributeConstraint(node_id, data)
      }
    })
  } else {
    return $.ajax({
      url: new_attribute_constraint_path,
      type: "POST",
      data: {node_id: node_id, rdf_type: rdfTypeForNode(node_id)},
      success: function(data) {
        insertAttributeConstraint(node_id, data)
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
      jsPlumb.remove(target);
    }
  });

  $.ajax({url: delete_url, method: "DELETE", success: function(data){
    $(jsPlumb.getEndpoints(node_id)).each(function(i, endpoint){jsPlumb.deleteEndpoint(endpoint)});
    jsPlumb.remove(node);
  }});
};

// returns the rdf type value for a node
var rdfTypeForNode = function(node_id) {
  return $("#node_" + node_id).find("select").val();
};

// removes all unconnected Endpoints so users cannot somehow create new connections
var removeExcessEndpoints = function(){
  $("div.node.static").each(function(i,node){
    $(jsPlumb.getEndpoints($(node).attr("id"))).each(function(ii,endpoint){
      if(endpoint.connections.length == 0){
        jsPlumb.deleteEndpoint(endpoint);
      }
    });
  });
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
    anchor:[ "Perimeter", { shape:"Square", rotation: 180}],
    deleteEndpointsOnDetach:true,
		scope: "relations",
		connectorStyle:{ strokeStyle:"#ffa500", lineWidth:3 },
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
		endpoint:["Rectangle", {width:5, height:5} ],
		anchor: ["Top"],
    deleteEndpointsOnDetach:false,
		paintStyle:{ fillStyle:"#0087CF", opacity:0.5 },
		scope: "attributes",
    maxConnections: -1,
		connectorStyle:{ strokeStyle:"#0087CF", lineWidth:2 },
		connector : "Straight"
	};
};