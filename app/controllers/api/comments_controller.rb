class Api::CommentsController < Api::ApiController

  def create_and_publish
    category = params[:content][:category]
    pub_name = params[:content].delete :publication
    pub = Publication.find_by_name(pub_name)

    # destinations for reverse publishing
    listserv_ids = params[:content].delete :listserv_ids

    location_ids = params[:content].delete :location_ids
    if location_ids.present?
      location_ids.select!{ |l| l.present? }
      params[:content][:location_ids] = location_ids.map{ |l| l.to_i } if location_ids.present?
    end

    cat_name = params[:content].delete :category
    cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?

    # TODO: there has got to be a better way! but I tried simply piping the image straight through
    # and allowing mass assignment to upload it as you would a normal form submission and no dice, so using
    # JS's solution until we think of something better.
    comment_image = nil
    if params[:content][:image].present?
      img = params[:content].delete :image
      image_temp_file = Tempfile.new('tmpImage')
      image_temp_file.puts img[:image_content]
      file_to_upload = ActionDispatch::Http::UploadedFile.new(tempfile: image_temp_file,
                                                              filename: img[:image_name], type: img[:image_type])
      comment_image = Image.new image: file_to_upload
    end

    # create content record to associate with the new comment
    content_record = {}
    content_record['title'] = params[:content].delete(:title)
    content_record['raw_content'] = params[:content].delete(:content)
    content_record['authors'] = params[:content].delete(:authors)
    content_record['authoremail'] = params[:content].delete(:authoremail)
    content_record['images'] = [comment_image] if comment_image.present?
    content_record['content_category_id'] = cat.id
    content_record['publication_id'] = pub.id
    content_record['pubdate'] = content_record['timestamp'] = Time.zone.now

    # create the new comment and the associated content record
    @comment = Comment.new
    @comment.content_attributes = content_record

    if @comment.save
      # do reverse publishing if applicable
      if listserv_ids.present?
        listserv_ids.each do |d|
          next if d.empty?
          list = Listserv.find(d.to_i)
          PromotionListserv.create_from_content(@comment.content, list) if list.present? and list.active
        end
      end

      # regular publishing to DSP
      repo = Repository.find_by_dsp_endpoint(params[:repository])
      if repo.present? and @comment.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
        render text: "#{@comment.content.id}"
      else
        render text: "Comment #{@comment.content.id} was created, but not published", status: 500
      end
    else # if saving fails
      render text: "Comment could not be created", status: 500
    end
  end

end
