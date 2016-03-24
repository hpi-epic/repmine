// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  jsPlumb.importDefaults({Container: "drawing_canvas"});
	loadNodesAndConnections();
});
