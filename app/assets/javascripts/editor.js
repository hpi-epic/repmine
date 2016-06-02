// makes a node draggable and creates the onclick and
function addNodeToGraph(node){
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
  $(".inplace").editable();
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

function loadNodesAndConnections(){
	$(".node").not(".static").each(function(index,node_div){
	  addNodeToGraph($(node_div));
	});

	loadExistingConnections(connect_these_nodes, load_their_attribute_constraints);

	jsPlumb.bind("connection", function(info, originalEvent) {
	  if(info.connection.scope == "relations") {
		  buildDraggedConnection(info.connection, true);
	  }
	});

  $(".inplace").editable();
}

/*   node.find("#node_rdf_type").change(function(event){
    updateConnectionsAndAttributes($(this).closest("div"));
}); */


// adds only the endpoints to a given node without making it draggable or registering callbacks
function addNodeEndpoints(node_html_id){
  var endpoints = []
  endpoints.push(jsPlumb.addEndpoint(node_html_id, connectionEndpoint()));
  endpoints.push(jsPlumb.addEndpoint(node_html_id, attributeEndpoint()));
  return endpoints;
};

// creates the relations and attribute constraint thingies
function loadExistingConnections(connect_them, load_attributes, make_static){
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

// make every edit form report back to mommy
$(document).on("change", "form[class*='edit_']", function(e){
  var form = $(this);
  $.when(submitAndHighlight(form)).then(function(data, textStatus, jqXHR){
    updateConnectionsAndAttributes(form.closest("div"));
  });
});

// handler for the 'save' button. basically submits all forms
function savePattern(){
  var requests = submitForm("form.edit_node").concat(submitForm("form[class*=edit_][class*=_constraint]"));
  $.when.apply($, requests).done(function(){
    submitAndHighlight($("form.edit_pattern"));
  });
};

// takes a form, submits it, and stores all the requests so we can wait for ... it
function submitForm(form_finder){
  var requests = [];
  $(form_finder).not(".static").each(function(index){
    requests.push(submitAndHighlight($(this)));
  });
  return requests;
};

// submits the form and highlights possible errors
function submitAndHighlight(form){
  updatePositionInformation(form);
  return $.ajax({
    url : form.attr("action"),
    type: "POST",
    data : form.serialize(),
    success: function(data, textStatus, jqXHR){
      showGrowlNotification(jqXHR);
    },
    error: function(jqXHR, textStatus, errorThrown){
      form.parent().effect("highlight", {color: '#CC3412'}, 2000);
      showGrowlNotification(jqXHR);
    }
  });
};

function updatePositionInformation(form){
  var position = $(form).parent().position();
	if($(form).find("input[id$=_x]").length > 0){
	  $(form).find("input[id$=_x]").val(position.left);
	  $(form).find("input[id$=_y]").val(position.top);
	}
};

// updates all connections of a node upon change of the node class
function updateConnectionsAndAttributes(node){
  var node_id = node.attr("id");
  // update the relations. cannot use jsplumb querying, as we need incoming and outgoing
  $(jsPlumb.getConnections({scope: "relations"})).each(function(index, connection){
    if(connection.sourceId == node_id || connection.targetId == node_id){
      var overlay = $(connection.getOverlay("customOverlay").getElement());
      reloadElement(overlay);
    }
  });
  // and the attributes using jsplumb querying
  $(jsPlumb.getConnections({scope: "attributes", source: node_id})).each(function(index, connection){
    reloadElement($(connection.target));
  });
};

function reloadElement(element, params){
  var update_url = element.find("form").attr("action");
  $.get(update_url, params, function(data) {element.html(data)});
};


function toggleNodeGroup(button, node_id){
  button.toggleClass("wicked");
  $("#" + node_id).toggleClass("double-border");
  var field = $("form[id='edit_" + node_id + "'] input[id='node_is_group']");
  field.val(field.val() === "true" ? "false" : "true");
};

function buildDraggedConnection(connection, rebuild_endpoints){
  var source_id = $(connection.source).attr("data-id");
  var target_id = $(connection.target).attr("data-id");
  jsPlumb.detach(connection, {fireEvent:false});
  createConnection(source_id, target_id, rebuild_endpoints);
};

// creates a connection between two endpoints
function createConnection(source_id, target_id, reinstall_endpoints, url) {
  // get the available relations from the server oder simply load the existing one
  if(url){
    return $.ajax({url: url, success: function(data){
      buildConnection(source_id, target_id, reinstall_endpoints, $(data));
    }});
  } else {
    return $.ajax({
      url: new_relation_constraint_path,
      type: "POST",
      data: {source_id: source_id, target_id: target_id},
      success: function(data) {
        buildConnection(source_id, target_id, reinstall_endpoints, $(data));
      }
    })
  }
};

function buildConnection(source_id, target_id, reinstall_endpoints, overlay){
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

function insertAttributeConstraint(node_id, data){
  var ac = $(data);
  var ac_div = $("<div class='ac_wrapper'></div>");

  if(0 === ac.attr("style").length){
    var node_position = $("#node_" + node_id).position()
    ac.css({left: node_position.left - 100, top: node_position.top - 150});
  }
  ac_div.css({left: ac.css("left"), right: ac.css("right")});
  ac.removeAttr("style");
  ac_div.append(ac);

  $("#drawing_canvas").append(ac_div);
  jsPlumb.draggable(ac_div);
  var ae = jsPlumb.addEndpoint(ac_div, { anchor:[ "BottomCenter"], deleteEndpointsOnDetach:true }, attributeEndpoint());
  jsPlumb.connect({source: jsPlumb.getEndpoints("node_" + node_id)[1], target: ae});
};

// call the backend and retrieve the next attribute filter line
function addAttributeFilter(node_id, url) {
  if(url){
    return $.ajax({
      url: url,
      success: function(data) {
        insertAttributeConstraint(node_id, data);
        $(".inplace").editable();
      }
    })
  } else {
    return $.ajax({
      url: new_attribute_constraint_path,
      type: "POST",
      data: {node_id: node_id},
      success: function(data) {
        insertAttributeConstraint(node_id, data);
        $(".inplace").editable();
      }
    });
  }
};

// removes a node from the graph
function deleteNode(node){
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

// removes all unconnected Endpoints so users cannot somehow create new connections
function removeExcessEndpoints(){
  $("div.node.static").each(function(i,node){
    $(jsPlumb.getEndpoints($(node).attr("id"))).each(function(ii,endpoint){
      if(endpoint.connections.length == 0){
        jsPlumb.deleteEndpoint(endpoint);
      }
    });
  });
};

function freeRelationEndpointOn(node_html_id){
  var endpoints = jsPlumb.getEndpoints(node_html_id);
  var free_endpoint;
  $(endpoints).each(function(i,e){
    if(e.scope == "relations"){free_endpoint = e}
  });
  return free_endpoint
};

// encapsulates the enpoint options for the orange connection thingies
function connectionEndpoint() {
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
function attributeEndpoint() {
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