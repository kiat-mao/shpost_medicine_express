class OrdersController < ApplicationController
  load_and_authorize_resource :order
  
  # GET /orders
  # GET /orders.json
  def index
    @orders_grid = initialize_grid(@orders.accessible_by(current_ability),
         :order => 'order_no',
         :order_direction => 'asc', 
         :per_page => params[:page_size])
  end
end