// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  jsPlumb.importDefaults({Container: "drawing_canvas"});
  $(".node.static").each(function(index, node_div){
    addNodeEndpoints($(node_div).attr("id"));
    jsPlumb.draggable($(node_div).attr("id"));
  });

	var requests = loadExistingConnections(connect_these_static_nodes, load_static_attribute_constraints, true);
  $.when.apply($, requests).done(function(){
    removeExcessEndpoints();
	});

	loadNodesAndConnections();
});

// returns the selections, except for the exceptions
var getSelectedElements = function(selector, exception){
  values = []
  $(selector).not(exception).each(function(i,el){
    values.push($(el).data("id"));
  });
  return values;
};

// switches from pure translation to an interaction suitable for providing OM user input
var startOmMode = function(){
  $(".om-control").each(function(i,el){$(el).show()});
  $(".p-control").each(function(i,el){$(el).hide()});
  $(".matched").each(function(i,el){$(el).addClass("matched_marked")});
  $(".selected").each(function(i,el){$(el).removeClass("selected")});
  makeElementsClickable();
};

var stopOmMode = function(){
  $(".om-control").each(function(i,el){$(el).hide()});
  $(".p-control").each(function(i,el){$(el).show()});
  $(".matched").each(function(i,el){$(el).removeClass("matched_marked")});
  removeClickHandler();
};

var makeElementsClickable = function(){
  allUnmatchedElementsOf(allPatternElements()).each(function(i, el){
    $(el).on("click", function(){
      $(this).toggleClass("selected");
      var selected_in = $(".selected.static");
      var selected_out = $(".selected").not(".static").find("select[id$='rdf_type']");
    });
  });
};

var removeClickHandler = function(){
  allUnmatchedElementsOf(allPatternElements()).each(function(i, el){
    $(el).removeClass("selected");
    $(el).unbind("click");
  });
}

var allPatternElements = function(){
  return $(".ge");
}

var allStaticPatternElements = function(){
  return $(".static");
}

var allUnmatchedElementsOf = function(elements){
  return elements.not(".matched")
}

// submits the correspondence selected by the user...
var saveCorrespondence = function(){
  var form = $("#save_correspondence_form");
  form.find("#source_element_ids_").val(getSelectedElements(".static.selected"));
  form.find("#target_element_ids_").val(getSelectedElements(".selected", ".static"));
  return $.ajax({
    url : form.attr("action"),
    type: "POST",
    data : form.serialize()
  });
};

// handler for pressing the 'Show Correspondences' button
$("#toggle_correspondences").on("ajax:success", function(e, data, status, xhr){
  $("#correspondences").html(xhr.responseText);
  $("#correspondences").toggle();
  e.stopPropagation();
});

$(document).on("click", ".highlight-correspondence", function () {
  $(this).closest("form").find(".highlight-id").each(function(){
    $("#" + $(this).val()).effect("highlight", {}, 2000);
  })
});