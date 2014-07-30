// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  
  jsPlumb.importDefaults({
    Container: "drawing_canvas"
	});	
	
	$("form[class=edit_node]").each(function(index){
	  addNodeToGraph($(this).parent());
	});
	
	$(connect_these_nodes).each(function(index, el){
	  var free_source = freeRelationEndpointOn("node_" + el.source);
	  var free_target = freeRelationEndpointOn("node_" + el.target);
	  var connection = jsPlumb.connect({source: free_source, target: free_target});
	  createConnection(connection, true, el.url);
	});	
	
	jsPlumb.bind("connection", function(info, originalEvent) {
	  if(info.connection.scope == "relations") {  
		  createConnection(info.connection, true);
	  }
	});
});

$(document).ready(function(){

  for (var node_id in load_their_attribute_constraints){
    jsPlumb.getEndpoints("node_" + node_id)[1].fire("dblclick", jsPlumb.getEndpoints("node_" + node_id)[1]);
    /*for (var node_id in load_their_attribute_constraints){
      
    }*/
  }
  
});

// handler for pressing the 'create node' button
$("#new_pattern_node").on("ajax:success", function(e, data, status, xhr){
  var node = $(xhr.responseText);
  node.appendTo($("#drawing_canvas"));
  addNodeToGraph(node);
});

// makes a node draggable and creates the onclick and 
var addNodeToGraph = function(node){
  var node_id = node.attr("data-node-id");
  var node_html_id = node.attr("id");
  
  // make the node draggable
  jsPlumb.draggable(node_html_id);
  // endpoint for relations
  jsPlumb.addEndpoint(node_html_id, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());
  // endpoint for attributes
  var ae = jsPlumb.addEndpoint(node_html_id, attributeEndpoint());  

  // bind the doubleclick to the attribute filter opening button
  ae.bind("dblclick", function(endpoint) {
    // only perform actions, when there is no filter present
    if(endpoint.connections.length == 0) {
      createNodeAttributeFilter(endpoint, node_id);
    }
  });
  
  // insert an onchange handler for each node's type selector
  node.find("#node_rdf_type").change(function(event){
    update_connections_and_attributes($(this).closest("div"));
  })
};

// handler for the 'save' button. basically submits all forms
var save_pattern = function(){
  save_nodes();
  // all forms that edit_*_constraints (you get the hint) are submitted
  $("form[class*=edit_][class*=_constraint]").each(function(index){
    submit_and_highlight($(this));
  });
  submit_and_highlight($("form[class=edit_pattern]"));
};

// sets position variables for each node and submits the form
var save_nodes = function(){
  $("form[class=edit_node]").each(function(index){
    var position = $(this).parent().position()
    $(this).find("input[id=node_x]").val(position.left);
    $(this).find("input[id=node_y]").val(position.top);
    submit_and_highlight($(this));
  });
};

// submits the form and highlights possible errors
var submit_and_highlight = function(form){
  $.ajax({
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
var update_connections_and_attributes = function(node){
  var node_id = node.attr("id")
  $(jsPlumb.getConnections("relations")).each(function(index, connection){
    if(connection.sourceId == node_id || connection.targetId == node_id){
      createConnection(connection, false);
    }
  })
};

// creates a connection between two endpoints
var createConnection = function(connection, reinstall_endpoints, url) {
  var source_id = $(connection.source).attr("data-node-id");
  var target_id = $(connection.target).attr("data-node-id");
  
  // reinstall the endpoints
  if(reinstall_endpoints){
    jsPlumb.addEndpoint(connection.source, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());
    jsPlumb.addEndpoint(connection.target, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());        
  }
  
  var overlay = $(connection.getOverlay("customOverlay").getElement())

  // get the available relations from the server oder simply load the existing one
  if(url){
    $.ajax({url: url, success: function(data){overlay.html(data)}})
  } else {
    $.ajax({
      url: new_relation_constraint_path,
      type: "POST",
      data: {
        source_id: source_id, 
        target_id: target_id,
        source_type: rdfTypeForNode(source_id), 
        target_type: rdfTypeForNode(target_id)
      },
      success: function(data) {
        overlay.html(data);
      }
    });    
  }
};

// creates the box-nodes for attribute filtering
var createNodeAttributeFilter = function(endpoint, node_id) {
  // build the div
  var node_html_id = "node_" + node_id + "_attributes";
  var attributeFilter = "<div id='" + node_html_id  + "' class='attributeFilter' style='left: ";
  attributeFilter += (endpoint.canvas.offsetLeft + 3) + "px; top: " + (endpoint.canvas.offsetTop - 120) + "px;'></div>";
  
  // make the div draggable and connect it to the node
  $("#drawing_canvas").append(attributeFilter);  
  jsPlumb.draggable(node_html_id);
  var ae = jsPlumb.addEndpoint(node_html_id, { anchor:[ "BottomLeft"] }, attributeEndpoint());
  jsPlumb.connect({source: endpoint, target: ae});  
  
  // create the '+ add filter' link at the bottom of the div
  var more_link = jQuery('<a/>',{
    id: "append_attribute_filter_" + node_id,
    href: "#",
    text: "+ add filter"
  });
  more_link.appendTo($("#" + node_html_id));  
  
  // define onclick function for new filters
  more_link.click(function(){addAttributeFilter(node_id, more_link)});
  
  // create an initial attribute filter
  addAttributeFilter(node_id, more_link);
};

// call the backend and retrieve the next attribute filter line
var addAttributeFilter = function(node_id, bottom) {
  $.ajax({
    url: new_attribute_constraint_path,
    type: "POST",
    data: {node_id: node_id, rdf_type: rdfTypeForNode(node_id)},
    success: function(data) {
      $(data).insertBefore(bottom);
    }
  });
}

var rdfTypeForNode = function(node_id) {
  return $("#node_" + node_id).find("select").val();
}

var freeRelationEndpointOn = function(node_html_id){
  var endpoints = jsPlumb.getEndpoints(node_html_id);
  var free_endpoint;
  $(endpoints).each(function(i,e){
    if(e.scope == "relations"){free_endpoint = e}
  });
  return free_endpoint  
}

// encapsulates the enpoint options for the orange connection thingies
var connectionEndpoint = function() {
  return {
		endpoint:["Dot", {radius:4} ],
		paintStyle:{ fillStyle:"#ffa500", opacity:0.5 },
		isSource:true,
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
  	},
		beforeDetach:function(conn) { 
			return confirm("Detach connection?"); 
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
		connector : "Straight",
		beforeDetach:function(conn) { 
			return confirm("Detach connection?"); 
		}
	};
};