// jsPlumb initializer - creates the drawing canvas and binds the 'connection' event
jsPlumb.ready(function() {

  jsPlumb.importDefaults({Container: "drawing_canvas"});

  $(".immutable_node").each(function(index, node_div){
    addNodeEndpoints($(node_div).attr("id"));
  });

	var requests = loadExistingConnections(connect_these_static_nodes, load_static_attribute_constraints, true);
  $.when.apply($, requests).done(function(){
    removeExcessEndpoints();
  });
			
	$(".node.static").each(function(i, node){
		$(node).on("click", function(){
			$("div[data-pattern-id='" + $(node).attr("data-pattern-id") + "']").each(function(x, pnode){
				$(pnode).removeClass("selected")
			});
			$(node).toggleClass("selected");
			$("#selected_node_" + $(node).attr("data-pattern-id")).val($(node).attr("data-id"));
		})
	});
	
	$.jGrowl("Please pick exactly <b>2</b> combination nodes!", {theme: 'error'});
});
