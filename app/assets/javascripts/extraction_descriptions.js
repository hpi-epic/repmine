$("#mapping_tree ul").sortable({
  connectWith: "#mapping_tree ul",
  placeholder: "ui-state-highlight",
  receive: function(e, ui) { 
    var parentMapping = $(e.target).parent().children("form")[0];
    var movedMapping = $(e.target).find("form")[0];
    if(parentMapping != null) {
      $.post(
        movedMapping.action + "/reassign",
        {"parent":parentMapping.action},
        function(data){
          if(data["success"] == true) {
            alert("successfully moved the mapping to its new parent.");
          } else {
            alert("error during moving: " + data["error"]);
          }
        },
        'json'
      );
    }
  }
});

$(document).ready(function() {
  $("form.edit_mapping").each(function(index, form){
    $(form).bind("change", function(){
      $.post( 
        $(this).attr("action"), 
        $(this).serialize(),
        function(data) {
          if(data["success"] == true) {
            $("#edit_mapping_" + data["id"]).effect( "highlight", {color:"#669966"}, 1000 );            
          } else {
            alert("Could not save changes! Errors: " + data["errors"]);
          }
        },
        'json'
      );
    });
  });
});

var toggleIgnored = function(){
  $("input[type='checkbox'][name='mapping[ignore]'][checked='checked']").each(function(index, element){
    $($(element).parents("ul")[0]).toggle();
  })
};