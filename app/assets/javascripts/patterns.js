jsPlumb.ready(function() {
  
  jsPlumb.importDefaults({
    Container: "drawing_canvas"
	});
	
	jsPlumb.bind("connection", function(info, originalEvent) {
	  if(info.connection.scope == "relations") {
		  createConnection(info.connection);
	  }
	});
});

$("#new_pattern_node").on("ajax:success", function(e, data, status, xhr){
  $("#drawing_canvas").append(xhr.responseText);
  var node_id = $(xhr.responseText).attr("id");
  // make the node draggable
  jsPlumb.draggable(node_id);
  // endpoint for relations
  jsPlumb.addEndpoint(node_id, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());
  // endpoint for attributes
  var ae = jsPlumb.addEndpoint(node_id, attributeEndpoint());  
  
  // bind the doubleclick to the attribute filter opening button
  ae.bind("dblclick", function(endpoint) {
    if(endpoint.connections.length == 0) {
      createNodeAttributeFilter(endpoint, node_id);
    }
	});
});

var createConnection = function(connection) {
  var source_id = $(connection.source).attr("data-node-id");
  var target_id = $(connection.target).attr("data-node-id");
  
  // reinstall the endpoints
  jsPlumb.addEndpoint(connection.source, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());  
  jsPlumb.addEndpoint(connection.target, { anchor:[ "Perimeter", { shape:"Circle"}] }, connectionEndpoint());

  // get the available relations from the server. this highly simplifies the JS...
  $.ajax({
    url: new_relation_constraint_path,
    type: "POST",
    data: {source_id: source_id, target_id: target_id},
    success: function(data) {
      var overlay = $(connection.getOverlay("customOverlay").getElement())
      overlay.html(data);
    }
  });
};

var createNodeAttributeFilter = function(endpoint, node_id) {
  // build the div
  var node_html_id = "nodes_" + node_id + "__attributes_";
  var attributeFilter = "<div id='" + node_html_id  + "' class='attributeFilter' style='left: ";
  attributeFilter += (endpoint.canvas.offsetLeft + 3) + "px; top: " + (endpoint.canvas.offsetTop - 120) + "px;'></div>";
  
  // make the div draggable and connect it to the node
  $("#drawing_canvas").append(attributeFilter);  
      
  jsPlumb.draggable(node_html_id);
  var ae = jsPlumb.addEndpoint(node_html_id, { anchor:[ "BottomLeft"] }, attributeEndpoint());
  jsPlumb.connect({source: endpoint, target: ae});
  
  jQuery.get(
    new_attribute_constraint_path,
    {node_id: node_id).val()},
    function(data) {$("#" + node_html_id).html(data);}
  );
};

var connectionEndpoint = function() {
  return {
		endpoint:["Dot", {radius:4} ],
		paintStyle:{ fillStyle:"#ffa500", opacity:0.5 },
		isSource:true,
		scope: "relations",
		connectorStyle:{ strokeStyle:"#ffa500", lineWidth:3 },
		connectorOverlays:[
      ["Custom", {
        create:function(component) {
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