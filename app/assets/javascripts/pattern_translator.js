// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {
  jsPlumb.importDefaults({Container: "drawing_canvas"});
  $(".immutable_node").each(function(index, node_div){addNodeEndpoints($(node_div).attr("id"));});

	var requests = loadExistingConnections(connect_these_static_nodes, load_static_attribute_constraints, true);

  $.when.apply($, requests).done(function(){
    removeExcessEndpoints();
    addMatchedClass();
	});

	loadNodesAndConnections();
});

// adds the css class 'matched' to all elements we already know have a mactching concept
var addMatchedClass = function(){
  $("div.static").each(function(i, el){
    if(matched_elements.indexOf($(el).attr("data-id")) > -1){
      $(el).addClass("matched")
    }
  })
};

// returns the selections, except for the exceptions
var getSelectedElements = function(selector, exception){
  values = []
  $(selector).not(exception).each(function(i,el){
    values.push($(el).data("id"));
  });
  return values;
};

// switches from pure translation to an interaction suitable for providing OM user input
var toggleOntologyMatchingMode = function(on){
  if(allUnmatchedElementsOf(allStaticPatternElements()).size() == 0){
    $.jGrowl("All elements are matched. Thank you!");
  } else {
    $("a.om-control").each(function(i,el){$(el).toggle()});
    $(".matched").each(function(i,el){$(el).toggleClass("matched_marked")});
    toggleSelectability(on);
    if(on){selectNextElement()};
  }
};

// determines which static elements are not yet matched and clicks on the next one
var selectNextElement = function(){
  var available = $(".node.static").not(".matched");
  available = available.add($(".relation.static").not(".matched"));
  available = available.add($(".attribute_constraint.static").not("matched"));
  var selected = $(".static.selected");
  var next_one = available.index(selected[selected.size() - 1]) + 1;
  if(next_one >= available.size()){next_one = 0};
  selected.each(function(i, el){$(el).removeClass("selected")});
  $(available[next_one]).click();
}

// makes everything clickable, except the
var toggleSelectability = function(switch_on){
  allUnmatchedElementsOf(allPatternElements()).each(function(i, el){
    if(switch_on){
      $(el).on("click", function(){
        $(this).toggleClass("selected");
        var selected_in = $(".selected.static");
        var selected_out = $(".selected").not(".static").find("select[id$='rdf_type']");
        showHelpfulMessage(selected_in, selected_out);
      });
    } else {
      $(el).removeClass("selected");
      $(el).unbind("click");
    }
  });
};

var allPatternElements = function(){
  return $(".node, .relation, .attribute_constraint");
}

var allStaticPatternElements = function(){
  return $(".node.static, .relation.static, .attribute_constraint.static");
}

var allUnmatchedElementsOf = function(elements){
  return elements.not(".matched")
}

// provides the users with feedback regarding the current state of matching
var showHelpfulMessage = function(selected_in, selected_out){
  var msg = ""
  switch(selected_in.size()){
    case 0:
      msg += "<b>Please select an <u>input</u> element!</b>";
      break;
    case 1:
      msg += "Input: <b>" + $(selected_in[0]).attr("data-rdf-type") +"</b>";
      break;
    default:
      msg += "Input: <b>" + selected_in.size() +" concepts</b>";
      break;
  }
  msg += "<br />";
  switch(selected_out.size()){
    case 0:
      msg += "<b>Please select an <u>output</u> element!</b>";
      break;
    case 1:
      msg += "Output: <b>" + $(selected_out[0]).val() +"</b>";
      break;
    default:
      msg += "Output: <b>" + selected_out.size() +" concepts</b>";
      break;
  }
  msg += "<br />";
  if(selected_in.size() > 0 && selected_out.size() > 0){
    msg += "Press <i><u>Save Mapping</u></i> when ready!"
  }
  $.jGrowl(msg, {theme: 'info'});
};

// submits the correspondence selected by the user...
var saveCorrespondence = function(){
  savePattern();
  var form = $("#save_correspondence_form");
  form.find("#source_element_ids_").val(getSelectedElements(".static.selected"));
  form.find("#target_element_ids_").val(getSelectedElements(".selected", ".static"));
  return $.ajax({
    url : form.attr("action"),
    type: "POST",
    data : form.serialize(),
    success: function(data, textStatus, jqXHR){
      showGrowlNotification(jqXHR);
      toggleOntologyMatchingMode(false);
      matched_elements = matched_elements.concat(data);
      addMatchedClass();
      toggleOntologyMatchingMode(true);
    },
    error: function(jqXHR, textStatus, errorThrown){
      showGrowlNotification(jqXHR);
    }
  });
};
