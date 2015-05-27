var interval;
interval = setInterval(function(){
  $.ajax({
    url: '/progress-job/' + job_id,
    success: function(job){
      var stage, progress;

      // If there are errors
      if (job.last_error != null) {
        $('.progress-status').addClass('text-danger').text(job.progress_stage);
        $('.progress-bar').addClass('progress-bar-danger');
        $('.progress').removeClass('active');
        clearInterval(interval);
      }

      // Upload stage
      if (job.progress_stage != null){
        stage = job.progress_stage;
        progress = job.progress_current / job.progress_max * 100;
      } else {
        progress = 0;
        stage = 'Starting to extract ontology';
      }

      // In job stage
      if (progress !== 0){
        $('.progress-bar').css('width', progress + '%').text(Number((progress).toFixed(2)) + '%');
      }

      $('.progress-status').text(stage);
    },
    error: function(){
      // Job is no loger in database which means it finished successfuly
      $('.progress').removeClass('active');
      $('.progress-bar').css('width', '100%').text('100%');
      $('.progress-status').text('Successfully created ontology!');
      $('.well').hide();
      clearInterval(interval);
    }
  })
},1000);