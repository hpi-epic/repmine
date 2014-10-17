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
  $.post(url, getSelectedTargetElement(), function(data, textStatus, jqXHR){
    var node = $(data);
    node.appendTo($("#drawing_canvas"));
    addNodeToGraph(node);
    showGrowlNotification(jqXHR);
  });
};

var getSelectedTargetElement = function(){
  return {
    element_id: $(".static.selected").attr("data-id"),
    element_type: $(".static.selected").attr("data-class")
  }
};

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
  $(".immutable_node, .relation.static, .attribute_constraint.static").each(function(i, node){
    $(node).on("click", function(){toggleAndSubmit($(this))})
  });  
};

var toggleAndSubmit = function(element, css_classes){
  $(".static.selected").each(function(i, el){
    $(el).removeClass("selected");
  })
  element.addClass("selected");
};

var toogleOntologyMatchingMode = function(btn){
  if(btn.hasClass("btn-danger")){
    $.jGrowl("Select one of the unmatched input nodes and choose its equivalent from the input!");
    btn.removeClass("btn-danger");
    btn.addClass("btn-warning");
    btn.text("Normal Mode")    
  } else {
    btn.addClass("btn-danger");
    btn.removeClass("btn-warning");
    btn.text("OM Mode");        
  }
  $("#new_node_button").toggle();
}


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
  var requests = saveNodes().concat(saveConstraints());
  $.when.apply($, requests).done(function(){
    submitTranslationPattern();
  });
};

var submitTranslationPattern = function(){
  var form = $("form.edit_pattern");
  return $.ajax({
    url : form.attr("action"),
    type: "POST",
    data : form.serialize(),
    success: function(data, textStatus, jqXHR){
      showGrowlNotification(jqXHR);
    },
    error: function(jqXHR, textStatus, errorThrown){
      showGrowlNotification(jqXHR);
    }
  });
};