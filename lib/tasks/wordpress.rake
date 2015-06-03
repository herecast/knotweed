namespace :wordpress do

  desc "Import all published posts in a Wordpress blog"
  task import: :environment do
=begin
    HOST = 'dailyuv.net'
    PATH = '/norwich/xmlrpc.php'
    BLOG_ID = 3
    USERNAME = 'jgstephe'
    PASSWORD = 'jgs4sbtx'
=end
    HOST = 'duvdive.wordpress.com'
    PATH = ''
    BLOG_ID = 0
    USERNAME = 'johnstephens889'
    PASSWORD = 'jgs4duvDive'

    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}

#    wpcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: true)
    wpcl = Rubypress::Client.new(host: HOST, username: USERNAME, password: PASSWORD, use_ssl: true)

    pub_id = Publication.find_by_name('dUVdive').id
    content_category_id = ContentCategory.find_by_name('local_news').id

    p_opts = options.merge(filter: {post_status: 'publish', number: '100'})
    wp_posts = wpcl.getPosts(p_opts)

    wp_posts.each do |wp_post|

      #wp_media = wpcl.getMediaLibrary(blog_id: BLOG_ID, username: USERNAME, password: PASSWORD, filter: {parent_id: wp_post['post_id']})
      wp_media = wp_post['post_thumbnail']

      wp = Content.new

      wp.title = wp_post['post_title']
      wp.guid = wp_post['guid']
      wp.raw_content = wp_post['post_content']
      wp.pubdate = wp_post['post_date'].to_time
      wp.publication_id = pub_id
      wp.content_category_id = content_category_id

      #wp.contentsource = HOST + ':' + BLOG_ID.to_s
      #wp.source_content_id = wp_post['post_id']

      wp.location_ids = [77, 78]

      # add an image only if you have one and there's not already one in the content that will display
      if wp_media.present? and !wp.sanitized_content.include? wp_post['post_thumbnail']['link']
        image = Image.new
        image.remote_image_url = wp_media['link']
        image.source_url = wp_media['link']
        wp.images = [image]
      end

      output = ''
      if wp.save
        output << "Content #{wp.id} saved"
        repo = Repository.find(Repository::PRODUCTION_REPOSITORY_ID)
        if repo.present?
          if wp.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
            output << ' and published'
          else
            output << ' but failed to publish'
          end
        end
      else
        output << wp.title + ' not saved'
      end

      puts output

    end
  end

  desc "Import a Wordpress post"
  task importone: :environment do
=begin
    HOST = 'dailyuv.net'
    PATH = '/norwich/xmlrpc.php'
    BLOG_ID = 3
    USERNAME = 'jgstephe'
    PASSWORD = 'jgs4sbtx'
=end
    HOST = 'duvdive.wordpress.com'
    PATH = ''
    BLOG_ID = 0
    USERNAME = 'johnstephens889'
    PASSWORD = 'jgs4duvDive'

    POST_ID = '489'

    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}

#    nwcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: true)
    nwcl = Rubypress::Client.new(host: HOST, username: USERNAME, password: PASSWORD, use_ssl: true)

    p_opts = options.merge(post_id: POST_ID)
    wp_post = nwcl.getPost(p_opts)
    wp_media = nwcl.getMediaLibrary(blog_id: BLOG_ID, username: USERNAME, password: PASSWORD, filter: {parent_id: POST_ID})

    wp = Content.new

    wp.title = wp_post['post_title']
    wp.guid = wp_post['guid']
    wp.raw_content = wp_post['post_content']
    wp.pubdate = wp_post['post_date'].to_time
    wp.publication_id = Publication.find_by_name('dUVdive').id
    wp.content_category_id = ContentCategory.find_by_name('Local News').id
    #wp.location_ids = [77]
    unless wp_media.empty?
      image = Image.new
      image.remote_image_url = wp_media[0]['link']
      image.source_url = wp_media[0]['link']
      # wp.images = [image]
    end

    output = ''
    if wp.save
      output << "Content #{wp.id} saved"
      repo = Repository.find(Repository::PRODUCTION_REPOSITORY_ID)
      if repo.present?
        if wp.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
          output << ' and published'
        else
          output << ' but failed to publish'
        end
      end
    else
      output << wp.title + ' not saved'
    end

    puts output

  end

end
