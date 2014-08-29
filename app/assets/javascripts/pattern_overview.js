var checkExecutionStatus = function(radio_name, url, ontology_select, status_span){
  
  var pattern_id = $("input[name='" + radio_name + "']:checked").val();
  var ontology_id = $("input[name='" + ontology_select + "']:checked").val();
  
  // return if users chose the blank value  
  if(pattern_id == undefined || ontology_id == undefined){
    alert("Select a pattern and at least on ontology before proceeding!")
    return;
  };
  
  // replace text with a spinner and fire the ajax call
  status_span.html("<i class='fa fa-spinner fa-spin'></i>&nbsp;matching...");
  $.ajax({
    url: url,
    data: {pattern_id: pattern_id, ontology_id: ontology_id},
    success: function(data,status,stuff){
      status_span.html(data);
    },
    error: function(stuff, status, errorMsg){
      alert(errorMsg);
    }
  })
};