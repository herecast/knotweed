module SearchService
  extend self

  def apply_standard_chronology_to_opts
    eval_in_controller_context do
      @opts[:order] = { latest_activity: :desc }
      @opts[:page] = params[:page] || 1
      @opts[:per_page] = params[:per_page] || 12
      @opts[:where][:pubdate] = 5.years.ago..Time.zone.now
      @opts[:where][:published] = 1 if @repository.present?
    end
  end

  def apply_requesting_app_whitelist_to_opts
    eval_in_controller_context do
      if @requesting_app.present?
        allowed_orgs = @requesting_app.organizations.pluck(:id)
        @opts[:where][:organization_id] = allowed_orgs
      end
    end
  end

  def apply_standard_categories_to_opts
    eval_in_controller_context do
      @opts[:where][:root_content_category_id] = standard_category_ids
      @opts[:where][:or] ||= []
      @opts[:where][:or] << [
        {content_type: ['news', 'market', 'talk']},
        {content_type: 'event', "organization.name" => {not: 'Listserv'}}
      ]
    end
  end

  def apply_standard_locations_to_opts
    eval_in_controller_context do
      if params[:radius] == 'me'
        @opts[:where]['created_by.id'] = current_user.id
      elsif params[:location_id].present?
        @opts[:where][:or] ||= []
        location = Location.find_by_slug_or_id params[:location_id]

        if params[:radius].present? && params[:radius].to_i > 0
          locations_within_radius = Location.non_region.within_radius_of(location, params[:radius].to_i).map(&:id)

          @opts[:where][:or] << [
            {my_town_only: false, all_loc_ids: locations_within_radius},
            {my_town_only: true, all_loc_ids: location.id}
          ]
        else
          @opts[:where][:or] << [
            {about_location_ids: [location.id]},
            {base_location_ids: [location.id]}
          ]
        end
      end
    end
  end

  def apply_eager_loading_content_associations_to_opts
    eval_in_controller_context do
      @opts[:include] = [:promotions, :images, :organization, :channel]
    end
  end

  private

    def eval_in_controller_context
      self.instance_eval do
        raise UninitializedOpts if @opts == nil
        @opts[:where] ||= {}
        yield
      end
    end

    def standard_category_ids
      categories = %w(market event news)
      categories << 'talk_of_the_town' if @current_user.present?
      categories.map do |cat|
        ContentCategory.find_by_name(cat).id
      end
    end

end

class SearchService::UninitializedOpts < ::StandardError

  def initialize
    super("Uninitialized @opts: the controller must initialize @opts first")
  end
end
