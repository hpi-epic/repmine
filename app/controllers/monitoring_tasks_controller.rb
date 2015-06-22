class MonitoringTasksController < ApplicationController
  
  def index
    @repos_with_tasks = Repository.find(MonitoringTask.pluck(:repository_id).uniq)
  end
  
  def show_results
    #send_data(@repository.execute(params[:query_string]), :type => 'text/csv; charset=utf-8; header=present', )
  end
  
end
