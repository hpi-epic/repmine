// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  
  jsPlumb.importDefaults({
    Container: "drawing_canvas"
	});	
	
	$("form[class=edit_node]").each(function(index){
	  addNodeEndpoints($(this).parent().attr("id"));
	});
	
  loadExistingConnections(true);
  removeExcessEndpoints();
  addOnclickHandler();
  loadExistingTranslations();
});

// handler for pressing the 'create node' button
$("#new_pattern_node").on("ajax:success", function(e, data, status, xhr){
  var node = $(xhr.responseText);
  node.appendTo($("#drawing_canvas"));
  addNodeToGraph(node);
});

// removes all unconnected Endpoints so users cannot somehow create new connections
var removeExcessEndpoints = function(){
  $("div.immutable_node").each(function(i,node){
    $(jsPlumb.getEndpoints($(node).attr("id"))).each(function(ii,endpoint){
      if(endpoint.connections.length == 0){
        jsPlumb.deleteEndpoint(endpoint);
      }
    });
  });
};

// adds an onclick handler to nodes, relations, and attributes
var addOnclickHandler = function(){
  $("div.immutable_node").each(function(i, node){
    $(node).on("click", function(){addClassToThingy($(this), "selected_node")});
  });
  
  $(jsPlumb.getConnections("relations")).each(function(i, connection){
    var overlay = connection.getOverlay("customOverlay").getElement();
    $(overlay).on("click", function(){highlightRelation($(overlay))});
  })
};

var addClassToThingy = function(thingy, css_class){  
  if(thingy.hasClass(css_class)){
    thingy.removeClass(css_class);        
  } else {
    thingy.addClass(css_class);
  }
};

var highlightRelation = function(overlay){
  addClassToThingy(overlay, "selected_thingy")
};

var loadExistingTranslations = function(){
  
};