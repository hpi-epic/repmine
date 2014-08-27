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

// function called when the "new Node" button is being clicked
var newTranslationNode = function(url){
  var selected_elements = $(".selected");
  if(selected_elements.length == 0){
    alert("You have to select at least one element from the input graph");
  } else {
    $.post(url, function(data){
      var node = $(data);
      node.appendTo($("#drawing_canvas"))
      addNodeToGraph(node);
    });
  }
}

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
    $(node).on("click", function(){toggleClasses($(this), ["selected","red_node"])});
  });
  
  $(jsPlumb.getConnections("relations")).each(function(i, connection){
    var overlay = connection.getOverlay("customOverlay").getElement();
    $(overlay).on("click", function(){highlightRelation($(overlay))});
  })
};

// adds or removes the provided classes on the thingy
var toggleClasses = function(element, css_classes){  
  $(css_classes).each(function(i, css_class){
    if(element.hasClass(css_class)){
      element.removeClass(css_class);        
    } else {
      element.addClass(css_class);
    }
  })  
};

// highlights a relation. TODO: highlight the arrow, as well...
var highlightRelation = function(overlay){
  toggleClasses(overlay, ["red_background", "selected"])
};

// loads every translation that we already know of. TODO: do!
var loadExistingTranslations = function(){
  
};