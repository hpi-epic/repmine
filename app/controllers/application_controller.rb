class ApplicationController < ActionController::Base
  protect_from_forgery

  after_filter :flash_to_headers

  def flash_to_headers
    # only run this in case it's an Ajax request.
    return unless request.xhr?
    response.headers['X-Message'] = flash_message unless flash_message.nil?
    response.headers["X-Message-Type"] = flash_type unless flash_type.nil?
    flash.discard # don't want the flash to appear when you reload page
  end
  
  private

  def flash_message
    [:error, :warning, :notice].each do |type|
      return flash[type] unless flash[type].blank?
    end
    return nil
  end

  def flash_type
    [:error, :warning, :notice].each do |type|
      return type.to_s unless flash[type].blank?
    end
    return nil    
  end
end
