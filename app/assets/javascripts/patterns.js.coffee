$(document).ready ->
  jsPlumb.ready ->
    jsPlumb.importDefaults({Container: "drawing_canvas"})
  $("#new_pattern_node").on("ajax:success", (e, data, status, xhr) ->
    $("#drawing_canvas").append(xhr.responseText)
    jsPlumb.draggable($(xhr.responseText).attr("id"));
  ).bind "ajax:error", (e, xhr, status, error) ->
    $("#new_post").append "<p>ERROR</p>"