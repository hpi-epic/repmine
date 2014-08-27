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