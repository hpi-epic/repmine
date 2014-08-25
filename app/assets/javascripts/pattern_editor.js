// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  
  jsPlumb.importDefaults({
    Container: "drawing_canvas"
	});	
	
	$("form[class=edit_node]").each(function(index){
	  addNodeToGraph($(this).parent());
	});
	
	loadExistingConnections();
	
	jsPlumb.bind("connection", function(info, originalEvent) {
	  if(info.connection.scope == "relations") {  
		  createConnection(info.connection, true);
	  }
	});
});

// handler for pressing the 'create node' button
$("#new_pattern_node").on("ajax:success", function(e, data, status, xhr){
  var node = $(xhr.responseText);
  node.appendTo($("#drawing_canvas"));
  addNodeToGraph(node);
});

jsPlumb.bind("connectionDetached", function(info, originalEvent){
  if(info.connection.scope == "relations"){
    var delete_me_link = $(info.connection.getOverlays()[0].canvas).find("form[class='edit_relation_constraint']").attr("action");
    if(delete_me_link != undefined){
      $.ajax({url: delete_me_link, method: "DELETE"});
    };
  }
});