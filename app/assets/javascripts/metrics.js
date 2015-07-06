jsPlumb.ready(function() {
  jsPlumb.importDefaults({Container: "drawing_canvas"});
	makeEverythingDraggable();
	createEndpoints();
	loadExistingConnections();
	jsPlumb.bind("connection", function(info, originalEvent) {
		updateConnection(connect_nodes_path, info.connection)
	});
	
	jsPlumb.bind("connectionDetached", function(info, originalEvent) {
		updateConnection(disconnect_nodes_path, info.connection)
	});
});

var updateConnection = function(url, connection){
	var source_id = $(connection.source).attr("data-id");
	var target_id = $(connection.target).attr("data-id");
	$.ajax({url: url, type: "POST", data: {source_id: source_id,target_id: target_id}});
}

$("#new_node").on("ajax:success", function(e, data, status, xhr){
  var node = $(xhr.responseText);
  node.appendTo($("#drawing_canvas"));
  jsPlumb.draggable(node);	
	jsPlumb.addEndpoint(node, topEndpoint());
	createDestroyCallback(node);
});

$("#new_operator").on("ajax:success", function(e, data, status, xhr){
  var node = $(xhr.responseText);
  node.appendTo($("#drawing_canvas"));
  jsPlumb.draggable(node);
	jsPlumb.addEndpoint(node, topEndpoint());
	jsPlumb.addEndpoint(node, bottomEndpoint());
	createDestroyCallback(node);
});

$(".edit_metric").on("ajax:success", function(e, data, status, xhr){
	$("form.edit_metric_node").each(function(i,form){
		var position = $(form).parent().position();
		$(form).find("input[id$=_x]").val(position.left);
		$(form).find("input[id$=_y]").val(position.top);
		$.ajax({
			url : $(form).attr("action"),
			type: "POST",
			data : $(form).serialize()
		});
	});
});

var makeEverythingDraggable = function(){
	$(".metric_node").each(function(i, node){
		jsPlumb.draggable($(node));
		createDestroyCallback($(node));
	});
};

var createDestroyCallback = function(node){
	node.dblclick(function() {
	  console.log($(this));
		var form = node.find("form");
		$.ajax({
			url : $(form).attr("action"),
			type: "DELETE",
			data : $(form).serialize(),
			success: function(data){
		    jsPlumb.remove(node);
			}
		});
	});
};

var createEndpoints = function(){
	$(".real_node").each(function(i, node){
		jsPlumb.addEndpoint($(node), topEndpoint());
	});
	
	$(".operator_node").each(function(i, node){
		jsPlumb.addEndpoint($(node), topEndpoint());
		jsPlumb.addEndpoint($(node), bottomEndpoint());
	});	
};

var loadExistingConnections = function(){
	jQuery.each(existingConnections, function(i, conn){
		var source = $("div[data-id=" + conn.source + "]");
		var target = $("div[data-id=" + conn.target + "]");
		var sourceEndpoint = jsPlumb.selectEndpoints({source: source.attr("id")}).get(0);
		var targetEndpoint = jsPlumb.selectEndpoints({target: target.attr("id")}).get(0);
		jsPlumb.connect({source: sourceEndpoint, target: targetEndpoint, fireEvent:false});
	});
}

// same for the attribute endpoints
var topEndpoint = function() {
  return {
		endpoint:["Dot", {radius:3}],
		anchor: ["Top"],
    deleteEndpointsOnDetach:false,
		paintStyle:{ fillStyle:"#0087CF", opacity:0.5 },
    maxConnections: 1,
		isTarget: true,
		connectorStyle:{ strokeStyle:"#0087CF", lineWidth:2 },
		connector : "Straight",
    dropOptions : {
  		tolerance:"touch",
  		hoverClass:"dropHover",
  		activeClass:"dragActive"
  	}			
	};
};

var bottomEndpoint = function() {
  return {
		endpoint:["Dot", {radius:3}],
		anchor: ["Bottom"],
    deleteEndpointsOnDetach:false,
		paintStyle:{ fillStyle:"#0087CF", opacity:0.5 },
    maxConnections: -1,
		connectorStyle:{ strokeStyle:"#0087CF", lineWidth:2 },
		connector : "Straight",
		isSource: true,
    dropOptions : {
  		tolerance:"touch",
  		hoverClass:"dropHover",
  		activeClass:"dragActive"
  	}		
	};
};

$(document).on("ajax:success", "#new_aggregation", function(e, data, status, xhr){
  var aggregation = $(xhr.responseText);
	updateAggregationSelections(aggregation.attr("data-node-id"));
});

$(document).on("ajax:success", ".delete_aggregation", function(event){
	updateAggregationSelections($(this).closest('span').attr("data-node-id"));
});

var updateAggregationSelections = function(node_id){
	var form = $("#edit_metric_node_" + node_id);
	$.ajax({
		url : $(form).attr("action"),
		type: "GET",
		success: function(data){
	    form.parent().html($(data).html());
		}
	});
};