class PatternsController < ApplicationController

  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'
  
  def new
    @pattern = Pattern.new
  end
  
  def editor
    @pattern = Pattern.find(params[:pattern_id])
  end
  
  def translator
    @pattern = Pattern.find(params[:pattern_id])
  end
    
  def create
    @pattern = Pattern.new(params[:pattern])
    respond_to do |format|
      if @pattern.save
        @pattern.initialize_repository!
        flash[:notice] = 'Pattern was successfully created.'
        format.html { redirect_to @pattern}
      else
        flash[:error] = 'Could not create pattern. ' + @pattern.errors.full_messages.join(", ")
        format.html {render action: "new"}
      end
    end
  end
  
  def show
    @pattern = Pattern.find(params[:id])
    redirect_to pattern_editor_path(@pattern)
  end
  
  def index
    @patterns = Pattern.all
    if @patterns.empty?
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
      @repositories = Repository.all
    end
  end
  
  def update
    @pattern = Pattern.find(params[:id])
    respond_to do |format|
      if @pattern.update_attributes(params[:pattern])
        format.json { head :ok }
      else
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @pattern = Pattern.find(params[:id])
    qn = @pattern.name
    @pattern.destroy
    flash[:notice] = "Destroyed Pattern '#{qn}'"
    redirect_to queries_path
  end
    
  def reset
    @pattern = Pattern.find(params[:pattern_id])
    @pattern.reset!
    flash[:notice] = "Resetted Pattern to state of: #{@pattern.updated_at}"    
    redirect_to pattern_path(@pattern)
  end

  # callbacks from here on
  def possible_relations
    @pattern = Pattern.find(params[:pattern_id])
    render :json => @pattern.possible_relations_between(params[:source], params[:target])
  end
  
  def possible_attributes
    @pattern = Pattern.find(params[:pattern_id])
    render :json => @pattern.possible_attributes_for(params[:node_class])
  end
end
