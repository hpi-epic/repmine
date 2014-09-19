// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  
  jsPlumb.importDefaults({
    Container: "drawing_canvas"
	});	
	
  $(".immutable_node").each(function(index, node_div){
	  addNodeEndpoints($(node_div).attr("id"));
	});
	
	var requests = loadExistingConnections(connect_these_static_nodes, load_static_attribute_constraints, true);
  $.when.apply($, requests).done(function(){
    removeExcessEndpoints();
    addOnclickHandler();	  
	});
  

  loadTranslationPattern();
});

// function called when the "new Node" button is being clicked
var newTranslationNode = function(url){
  $.post(url, function(data){
    var node = $(data);
    node.appendTo($("#drawing_canvas"))
    addNodeToGraph(node);
  });
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
  
  $(".relation.static").each(function(i, relation){
    $(relation).parent().on("click", function(){highlightRelation($(this))});
  })
  
  $(".attribute_constraint.static").each(function(i, ac){
    $(ac).on("click", function(){toggleClasses($(this), ["selected","red_background"])});
  });
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
  toggleClasses(overlay, ["selected", "red_background"])
};

var loadTranslationPattern = function(){
  $(".node").not(".immutable_node").each(function(index,node_div){
	  addNodeToGraph($(node_div));
	});
	
  loadExistingConnections(connect_these_nodes, load_their_attribute_constraints);
  
	jsPlumb.bind("connection", function(info, originalEvent) {
	  if(info.connection.scope == "relations") {  
		  createConnection(info.connection, true);
	  }
	});
};

var saveTranslation = function(){
  var selected_elements = $(".selected");
  if(selected_elements.length == 0){
    alert("You have to select at least one element from the input graph");
  } else {
    str = "Save Translation pattern? The following elements are thereby translated\n\n";
    str += addInformation("Nodes", ".node.selected");
    str += addInformation("Relations", "._jsPlumb_overlay.selected");
    str += addInformation("Attributes", ".attribute_constraint.selected");
    if(confirm(str)){
      console.log("please submit me...")
    };
  }
};

var addInformation = function(name, search_string){
  var stuff = "";
  $(search_string).each(function(i, element){
    stuff += $(element).find("form select").first().text() + "\n";
  });
  
  if(stuff.length > 0){
    return name + ":\n\t" + stuff
  } else {
    return stuff;
  }
}