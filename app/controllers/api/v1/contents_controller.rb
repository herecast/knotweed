module Api
  module V1
    class ContentsController < ApiController

      def index
        params[:page] ||= 1
        params[:per_page] ||= 30
        if params[:query].present?
          query = Riddle::Query.escape(params[:query])

          opts = { select: '*, weight()', excerpts: { limit: 350, around: 5, html_strip_mode: "strip" } }
          opts[:order] = 'pubdate DESC' if params[:order] == 'pubdate'
          opts[:per_page] = params[:per_page]
          opts[:page] = params[:page]

          opts[:with] = {}
          opts[:conditions] = {}

          # have to duplicate a lot of the non-search logic here because Sphinx doesn't
          # allow us to use activerecord scopes
          opts[:conditions].merge!({published: 1}) if params[:repository].present?

          if @requesting_app.present?
            allowed_pubs = @requesting_app.publications
            if params[:publication_ids].present? # allows the My List / All Lists filter to work
              filter_pubs = Publication.where(id: params[:publication_ids])
              allowed_pubs.select! { |p| filter_pubs.include? p }
            end
            opts[:with].merge!({pub_id: allowed_pubs.collect{|c| c.id} })
          end

          if params[:categories].present?
            allowed_cats = ContentCategory.find_with_children(name: params[:categories]).collect{|c| c.id}
            opts[:with].merge!({:cat_ids => allowed_cats})
          end

          opts[:conditions].merge!({channelized_content_id: nil}) # note, that's how sphinx stores NULL

          # this is another query param that allows API users to search for entries
          # in publication_locations OR locations
          # at least as of now, it's safe to assume if we're querying by this, we're not querying
          # by the others.
          if params[:all_locations].present?
            all_locs = params[:all_locations].map{ |l| l.to_i }
            opts[:with].merge!({all_loc_ids: all_locs})
          else
            if params[:publication_locations].present?
              pub_locs = params[:publication_locations].map{ |l| l.to_i }
              opts[:with].merge!({ pub_loc_ids: pub_locs })
            end

            if params[:locations].present?
              locations = params[:locations].map{ |l| l.to_i } 
              opts[:with].merge!({loc_ids: locations})
            end
          end


          @contents = Content.search query, opts
          @contents.context[:panes] << ThinkingSphinx::Panes::WeightPane
          @contents.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane
          @page = @contents.current_page 
          @pages = @contents.total_pages
        else
          if params[:max_results].present? 
            @contents = Content.limit(params[:max_results])
          else
            @contents = Content
          end
          # exclude event content
          @contents = @contents.where("channel_type != 'Event' or channel_type IS NULL")

          @contents = @contents.includes(:publication).includes(:content_category).includes(:images)

          if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
            sort_order = params[:sort_order]
          end

          sort_order ||= "DESC"
          @contents = @contents.order("pubdate #{sort_order}")
          # filter contents by publication based on what publications are allowed
          # for the incoming consumer app
          if @requesting_app.present?
            allowed_pubs = @requesting_app.publications
            if params[:publication_ids].present? # allows the My List / All Lists filter to work
              filter_pubs = Publication.where(id: params[:publication_ids])
              allowed_pubs.select! { |p| filter_pubs.include? p }
            end
            # if viewing just the home list
            @contents = @contents.where(publication_id: allowed_pubs)
          end
          if params[:start_date].present?
            start_date = Chronic.parse(params[:start_date])
            @contents = @contents.where("pubdate >= :start_date", { start_date: start_date}) unless start_date.nil?
          end
          if params[:categories].present?
            allowed_cats = ContentCategory.find_with_children(name: params[:categories])
            @contents = @contents.where(content_category_id: allowed_cats)
          end

          # filter by location
          if params[:all_locations].present?
            locs = params[:all_locations].map{ |l| l.to_i }
            @contents = @contents.joins('left join contents_locations on contents.id = contents_locations.content_id')
              .joins('left join locations_publications on locations_publications.publication_id = contents.publication_id')
              .where('contents_locations.location_id in (?) OR locations_publications.location_id in (?)', locs, locs) 
          else
            if params[:locations].present?
              locations = params[:locations].map{ |l| l.to_i } # avoid SQL injection
              @contents = @contents.joins('inner join contents_locations on contents.id = contents_locations.content_id')
                .where('contents_locations.location_id in (?)', locations)
            end

            if params[:publication_locations].present?
              pub_locs = params[:publication_locations].map{ |l| l.to_i }
              @contents = @contents.joins('LEFT JOIN locations_publications on ' + 
                          'contents.publication_id = locations_publications.publication_id ')
                          .where('locations_publications.location_id in (?)', pub_locs)
            end
          end

          # workaround to avoid the extremely costly contents_repositories inner join
          # using the new "published" boolean on the content model
          # to avoid breaking specs and more accurately replicate the old behavior,
          # we're only introducing this condition when a repository parameter is provided.
          @contents = @contents.published if params[:repository].present?

          # for the dashboard, if there's an author email, just return their content records.
          @contents = @contents.where(authoremail: params[:authoremail]) if params[:authoremail].present?
        end

        @contents = @contents.page(params[:page].to_i).per(params[:per_page].to_i)
        @page = params[:page]
        @pages = @contents.total_pages unless @contents.empty?
      end

      def show
        @content = Content.find(params[:id])
        if params[:repository].present? and @content.present?
          repo = @content.repositories.find_by_dsp_endpoint params[:repository]
          @content = nil if repo.nil?
        end
      end

      # for now, this doesn't need to handle images
      def create_and_publish
        category = params[:content][:category]
        pubname = params[:content].delete :publication

        # destinations for reverse publishing
        listserv_ids = params[:content].delete :listserv_ids

        location_ids = params[:content].delete :location_ids
        if location_ids.present?
          location_ids.select!{ |l| l.present? }
          params[:content][:location_ids] = location_ids.map{ |l| l.to_i } if location_ids.present?
        end

        cat_name = params[:content].delete :category
        cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?
        if params[:content][:content].present?
          params[:content][:raw_content] = params[:content].delete :content
        end
        @content = Content.new(params[:content])
        @content.publication = Publication.find_by_name(pubname)
        @content.content_category = cat unless cat.nil?
        @content.pubdate = @content.timestamp = Time.zone.now
        @content.images=[@image] unless @image.nil?

        if @content.save
          # do reverse publishing if applicable
          if listserv_ids.present?
            listserv_ids.each do |d|
              next if d.empty?
              list = Listserv.find(d.to_i)
              PromotionListserv.create_from_content(@content, list, @requesting_app) if list.present? and list.active
            end
          end
          # regular publishing to DSP
          repo = Repository.find_by_dsp_endpoint(params[:repository])
          if repo.present? and @content.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
            render text: "#{@content.id}"
          else
            render text: "Content #{@content.id} was created, but not published", status: 500
          end
        else # if saving fails
          render text: "Content could not be created", status: 500
        end
      end

      # returns hash of IDs representing a full thread of conversation
      def get_tree
        if Content.exists? params[:id]
          @content = Content.find params[:id] 
          @repo = Repository.find_by_dsp_endpoint(params[:repository])
          thread = @content.get_full_ordered_thread
          # requested to remove this functionality because our published flag
          # is not always accurate right now. NG's opinion is that we should work
          # on making the published flag accurate rather than removing this filter
          # but to each their own I suppose.
          #thread.select! { |pair| @repo.contents.include? Content.find(pair[0]) }
          render json: thread.to_json
        else
          render json: {}
        end
      end

      def banner
        @content = Content.find(params[:id])
        @repo = Repository.find_by_dsp_endpoint(params[:repository])
        begin
          promoted_content_id = @content.get_related_promotion(@repo)
          promoted_content = Content.find promoted_content_id
        rescue
          promoted_content = nil
        end

        if promoted_content.nil?
          render json: {}
        else
          @banner = PromotionBanner.for_content(promoted_content.id).active.first
          unless @banner.present? # banner must've expired or been used up since repo last updated
            # so we need to trigger repo update
            PromotionBanner.remove_promotion(@repo, promoted_content.id)
            render json: {}
          else
            @banner.impression_count += 1
            @banner.save
            render json: { banner: @banner.banner_image.url, 
                           target_url: @banner.redirect_url, content_id: promoted_content.id }
          end
        end
      end

      def update
        @content = Content.find(params[:id])
        if params[:content][:category_reviewed].present?
          @content.update_attribute :category_reviewed, params[:content][:category_reviewed]
          # requested to create a (essentially) blank category_correction object when marking reviewed
          if params[:content][:category_reviewed] # if true
            CategoryCorrection.create(content: @content, new_category: @content.category, old_category: @content.category)
          end
        end
      end

      def moderate
        @message = 'success'

        begin
          content = Content.find(params[:id])
          subject = 'dailyUV Flagged as ' + params[:classification] + ': ' +  content.title

          ModerationMailer.send_moderation_flag(content, params, subject).deliver

        rescue Exception => e
          @message = e.message
        end
      end


    end
  end
end
