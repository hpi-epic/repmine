var checkExecutionStatus = function(form, url, button){
  // return if users chose the blank value
  if(form.find("select").val() == ""){
    button.html("<i class='fa fa-chevron-circle-left'></i>&nbsp;choose")
    return;
  };
  
  // replace text with a spinner and fire the ajax call
  button.html("<i class='fa fa-spinner fa-spin'></i>&nbsp;matching...");
  $.ajax({
    url: url, 
    data: {repository_id: form.find("select").val()},
    success: function(data,status,stuff){
      button.html(data);
    },
    error: function(stuff, status, errorMsg){
      alert(errorMsg);
      button.html("<i class='fa fa-chevron-circle-left'></i>&nbsp;choose");      
    }
  })
};