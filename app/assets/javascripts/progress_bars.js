var intervals = {};
jQuery.each(jobs, function(job_id, initial_text){
	intervals[job_id] = setInterval(function(){
		var pbar = $("#progress_bar_" + job_id);		
	  $.ajax({
	    url: '/progress-job/' + job_id,
	    success: function(job){
	      var stage, progress;

	      // If there are errors
	      if (job.last_error != null) {
	        pbar.find('.progress-status').addClass('text-danger').text(job.progress_stage);
					pbar.find('.progress-bar').addClass('progress-bar-danger');
					pbar.find('.progress').removeClass('active');
	        clearInterval(intervals[job_id]);
	      }

	      // Upload stage
	      if (job.progress_stage != null){
	        stage = job.progress_stage;
	        progress = job.progress_current / job.progress_max * 100;
	      } else {
	        progress = 0;
	        stage = initial_text;
	      }

	      // In job stage
	      if (progress !== 0){
					pbar.find('.progress-bar').css('width', progress + '%').text(Number((progress).toFixed(2)) + '%');
	      }

				pbar.find('.progress-status').text(stage);
	    },
	    error: function(){
	      // Job is no loger in database which means it finished successfuly
				pbar.find('.progress').removeClass('active');
				pbar.find('.progress-bar').css('width', '100%').text('100%');
				pbar.find('.progress-status').text('Successfully finished: ' + initial_text);
				pbar.find('.well').hide();
	      clearInterval(intervals[job_id]);
	    }
	  })
	},1000);	
});