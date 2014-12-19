class Api::BusinessLocationsController < Api::ApiController

	# shamelessly copied from models/publication.rb JGS 20141202

	# returns list of business locations filtered by consumer app (if provided)
	def index
=begin
		if params[:consumer_app_uri].present?
			consumer_app = ConsumerApp.find_by_uri params[:consumer_app_uri]
			@businessLocations = consumer_app.business_locations
		else
			@businessLocations = BusinessLocation.all
		end
=end
		@businessLocations = BusinessLocation.all
		render json: @businessLocations
	end

	def show
		if params[:id].present?
			@businessLocation = BusinessLocation.find(params[:id])
		elsif params[:name].present?
			@businessLocation = BusinessLocation.find_by_name(params[:name])
		end
		if @businessLocation.present?
			render :json => @businessLocation
		else
			render text: "No business location found.", status: 500
		end
	end
end