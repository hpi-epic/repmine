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
    addMatchedClass();
    addOnclickHandler();	  
	});
	
  loadTranslationPattern();
});

// function called when the "new Node" button is being clicked
var newTranslationNode = function(url){
  $.post(url, getSelectedSourceElement(), function(data, textStatus, jqXHR){
    var node = $(data);
    node.appendTo($("#drawing_canvas"));
    addNodeToGraph(node);
    showGrowlNotification(jqXHR);
  });
};

// adds the css class 'matched' to all elements we already know have a mactching concept
var addMatchedClass = function(){
  $("div.static").each(function(i, el){
    if(matched_concepts.indexOf($(el).find("select[id$='rdf_type']").val()) > -1){
      $(el).addClass("matched")
    }
  })
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

// adds an onclick handler to nodes, relations, and attributes that are not matched
var addOnclickHandler = function(){
  $(".immutable_node, .relation.static, .attribute_constraint.static").not(".matched").each(function(i, node){
    $(node).on("click", function(){$(this).toggleClass("selected")})
  });
};

// out of the static elements (i.e., the ones on the left), the selected one is retrieved
var getSelectedSourceElement = function(){
  return {
    element_id: $(".static.selected").data("id"),
    element_type: $(".static.selected").data("class")
  }
};

var getSelectedTranslationElements = function(){
  return $(".selected").not(".static").map(function(){
    return {
      element_id: $(this).data("id"),
      element_type: $(this).data("class")
    }
  });
};

// switches from pure translation to an interaction suitable for providing OM user input
var toogleOntologyMatchingMode = function(btn){
  var switch_on = btn.hasClass("btn-danger");
  toggleOmControls(switch_on, btn);
  toggleOutputSelection(switch_on);
  $(".matched").each(function(i,el){$(el).toggleClass("matched_marked")});
};

// either switches on or disables clickable target elements
var toggleOutputSelection = function(switch_on){
  $(".node, .relation, .attribute_constraint").not(".static").each(function(i, el){
    if(switch_on){
      $(el).on("click", function(){$(this).toggleClass("selected")});
    } else {
      $(el).removeClass("selected");
      $(el).unbind("click");
    }
  });
};

// updates the controls by changing the button and disabling the 'new node' button
var toggleOmControls = function(switch_on, btn){
  if(switch_on){
    btn.text("Translation Mode")
    $.jGrowl("Select Input and Output Elements and store the correspondence when done.")
  } else {
    btn.text("OM Mode");
  }
  btn.toggleClass("btn-danger");
  btn.toggleClass("btn-warning");
  $("#new_node_button").toggle();
  $("#save_correspondence_button").toggle();
  $("#save_pattern_button").toggle();  
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