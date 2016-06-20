require 'rake'
require 'optparse'

namespace :wordpress do

  desc "Import all published posts in a Wordpress blog"
  task :import, [:blogTitle] => :environment do |t, args|

    blogTitle = args[:blogTitle]

    unless blogTitle.present?
      puts "no blogTitle passed: use rake wordpress:import['My BlogTitle']"
      exit 1
    end

    org = Organization.find_by_name("#{blogTitle}")
    unless org.present?
      puts "#{blogTitle} does not exist in Organizations table"
      exit 1
    end

    HOST = 'dailyuv.net'
    USERNAME = 'testuser'
    PASSWORD = 'jgs4sbtx'
    USESSL = false

    # set up a client to the multisite root to get the list of blogs (for the specified user)
    wpcl = Rubypress::Client.new(host: HOST, username: USERNAME, password: PASSWORD, use_ssl: USESSL)
    blogs = wpcl.getUsersBlogs

    # find the blog_id and the path to the xmlrpc file
    blogEntry = blogs.select{|b| b['blogName'] == blogTitle}[0]
    blog_url = blogEntry['url']
    BLOG_ID = blogEntry['blogid']
    hostLen = blogEntry['xmlrpc'].index(HOST)+HOST.length
    PATH = blogEntry['xmlrpc'][hostLen..-1]

    # reset the client to the correct path
    wpcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: USESSL)

    num_processed = 0
    content_category_id = ContentCategory.find_by_name('local_news').id

    # get the posts
    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}
    p_opts = options.merge(filter: {post_status: 'publish', number: '300'})
    wp_posts = wpcl.getPosts(p_opts)

    retPosts = wp_posts.count

    # process all the posts
    wp_posts.each do |wp_post|

      # do we already have this entry?
      if Content.find_by_guid(wp_post['guid'])
        puts "'#{wp_post['post_title']}' (#{wp_post['guid']}) already in database"
        next
      end

      if wp_post['post_date'].to_time > Time.current
        puts "'#{wp_post['post_title']}' (#{wp_post['guid']}) is scheduled for the future (#{wp_post['post_date']})."
        next
      end

      # parse the WP post hash into a Content object
      wp = newContentFromWP(blogTitle, wp_post, org, content_category_id, blog_url)

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
      num_processed += 1
    end
    puts "Retrieved #{retPosts} posts, processed #{num_processed}."

    exit 0
  end

  def newContentFromWP(blogTitle, wp_post, org, content_category_id, blog_url)
    wp = Content.new

    wp.contentsource = blogTitle

    post_tag = wp_post['terms'].select{|t| 'post_tag' == t['taxonomy']}
    tag_org = Organization.find_by_name(post_tag[0]['name']) if post_tag.present?
    wp.organization = tag_org ? tag_org : org

    wp.title = wp_post['post_title']
    wp.guid = wp_post['guid']
    wp.url = blog_url + "?p=#{wp_post['post_id']}"
    wp.raw_content = wp_post['post_content']
    wp.pubdate = wp_post['post_date'].to_time

    wp.content_category_id = content_category_id

    # get user info
=begin
      # this code sometimes fails and Rob claims that most of the time they don't want an author displaying,
      # so commented out for the 1.9 release
      user_id = wp_post['post_author']
      userInfo = wpcl.getUser(blog_id: BLOG_ID, user_id: user_id, fields: ['email','display_name'])
      wp.authors = userInfo['display_name']
      wp.authoremail = userInfo['email']
=end

    wp.images = []
    ng = Nokogiri::HTML.parse(wp_post['post_content'])
    imgTags = ng.css('a img')
    imgTags.each do |img|
      image = Image.new
      image.remote_image_url = image.source_url = img['src']
      wp.images << image
    end

    #wp_media = wpcl.getMediaLibrary(blog_id: BLOG_ID, username: USERNAME, password: PASSWORD, filter: {parent_id: wp_post['post_id']})
    wp_media = wp_post['post_thumbnail']

    # add an image only if you have one and there's not already one in the content that will display
    if wp_media.present? and !wp.sanitized_content.include? wp_post['post_thumbnail']['link']
      image = Image.new
      image.remote_image_url = wp_media['link']
      image.source_url = wp_media['link']
      wp.images << image
    end

    wp
  end

  desc "Set up organizations"
  task setup_pubs: :environment do
    lebpubs = ["The Lebanon Beacon", "Lebanon City Council", "Lebanon Conservation Commission", "Lebanon School District", "Mt. Lebanon School", "Lebanon High School", "City of Lebanon NH", "Mascoma River Greenway", "dailyUV-Lebanon"]
    norpubs = ["The Norwich Harbinger", "Norwich Historical Society", "Norwich Women's Club", "Montshire Museum of Science", "Town of Norwich VT", "Dresden School Board", "King Arthur Flour", "Norwich School Board", "Marion Cross School", "Book Jam", "Hanover High School", "Norwich Public Library", "Richmond Middle School", "Norwich Bookstore", "dailyUV-Norwich", "Jim and Tim Report", "dailyUV-UV"]
    hartpubs = ["The Hartford Observer", "Ottauquechee School", "Hartford High School", "Hartford Memorial Middle School", "dailyUV-Hartford", "Hartford Police Department", "Quechee and Wilder Libraries", "Hartford Area Career and Technical Center", "Town of Hartford VT", "dailyUV-UV"]

    lebloc = Location.find_by_city("Lebanon")
    lebpubs.each do |org|
      neworg = Organization.find_or_create_by_name(org) do | p |
        p.locations = [lebloc]
      end
    end

    norloc = Location.find_by_city("Norwich")
    norpubs.each do |org|
      neworg = Organization.find_or_create_by_name(org) do | p |
        p.locations = [norloc]
      end
    end

    hartloc = Location.find_by_city("Hartford")
    hartpubs.each do |org|
      neworg = Organization.find_or_create_by_name(org) do | p |
        p.locations = [hartloc]
      end
    end

  end

  desc "Reimport dailyUV"
  task reimport: :environment do
    blogTitle = 'dailyUV'

    HOST = 'dailyuv.net'
    USERNAME = 'jgstephe'
    PASSWORD = 'jgs4sbtx'
    USESSL = false
    # set up a client to the multisite root to get the list of blogs (for the specified user)
    wpcl = Rubypress::Client.new(host: HOST, username: USERNAME, password: PASSWORD, use_ssl: USESSL)
    blogs = wpcl.getUsersBlogs

    # find the blog_id and the path to the xmlrpc file
    blogEntry = blogs.select{|b| b['blogName'] == blogTitle}[0]
    blog_url = blogEntry['url']
    BLOG_ID = blogEntry['blogid']
    hostLen = blogEntry['xmlrpc'].index(HOST)+HOST.length
    PATH = blogEntry['xmlrpc'][hostLen..-1]

    # reset the client to the correct path
    wpcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: USESSL)

    num_processed = 0
    content_category_id = ContentCategory.find_by_name('local_news').id

    # get the posts
    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}
    p_opts = options.merge(filter: {post_status: 'publish', number: '500'})
    wp_posts = wpcl.getPosts(p_opts)

    retPosts = wp_posts.count
    found = updated = failed = norwich = lebanon = hartford = 0

    loc_norwich = Location.find_by_city('Norwich')
    loc_lebanon = Location.find_by_city('Lebanon')
    loc_hartford = Location.find_by_city('Hartford')

    unrecognized_posts = []

    # process all the posts
    wp_posts.each do |wp_post|

      # do we already have this entry?
      existing_content = Content.find_by_title_and_pubdate(wp_post['post_title'], wp_post['post_date'].to_time)
      if existing_content
        puts "'#{wp_post['post_title']}' (#{wp_post['guid']}) already in database at #{existing_content.id}"
        found += 1
        existing_content.guid = wp_post['guid']
        existing_content.url = blog_url + "?p=#{wp_post['post_id']}"
        existing_content.origin = 'Wordpress Parser'
        # reset the organization if it's dailyUV-Norwich
        if existing_content.organization_id == 469 # 469 -> dailyUV-Norwich
          existing_content.organization_id = 398 # dailyUV
          existing_content.locations = [loc_norwich]
          puts "  changed dailyUV-Norwich to dailyUV"
          norwich += 1
        end
        if existing_content.organization_id == 456 # 456 -> dailyUV-Lebanon
          existing_content.organization_id = 398 # dailyUV
          existing_content.locations = [loc_lebanon]
          puts "  changed dailyUV-Lebanon to dailyUV"
          lebanon += 1
        end
        if existing_content.organization_id == 476 # 476 -> dailyUV-Norwich
          existing_content.organization_id = 398 # dailyUV
          existing_content.locations = [loc_hartford]
          puts "  changed dailyUV-Hartford to dailyUV"
          hartford += 1
        end
        if existing_content.save
          puts "  updated record"
          updated += 1
        else
          puts "  SAVE FAILED for #{wp_post['post_title']}"
          failed += 1
        end

        next
      else
        # not found, record info
        unrecognized_posts << wp_post
      end

      if wp_post['post_date'].to_time > Time.current
        puts "'#{wp_post['post_title']}' (#{wp_post['guid']}) is scheduled for the future (#{wp_post['post_date']})."
        next
      end

      num_processed += 1

    end
    puts "Retrieved #{retPosts} posts, found #{found}, updated #{updated}, failed #{failed}."
    puts "Changed #{norwich} Norwich, #{lebanon} Lebanon, #{hartford} Hartford"
    puts "\nUnpublished Posts\n\n"
    pp unrecognized_posts.map{|p| p['post_id'] + ':' + p['post_title'] + ' ' + p['post_date'].to_time.to_s + ' ' + p['guid']}

    exit 0

  end

  desc "Import a Wordpress post"
  task importone: :environment do

    blogTitle = 'The Norwich Harbinger'
    POST_ID = '489'

    unless blogTitle.present?
      puts "no blogTitle passed: use rake wordpress:import -- -b 'My BlogTitle'"
      exit 1
    end
    org = Organization.find_by_name(blogTitle).id
    unless org.present?
      puts "#{blogTitle} does not exist in Organizations table"
      exit 1
    end

    HOST = 'dailyuv.net'
    USERNAME = 'jgstephe'
    PASSWORD = 'jgs4sbtx'
    USESSL = false

    # set up a client to the multisite root to get the list of blogs (for the specified user)
    wpcl = Rubypress::Client.new(host: HOST, username: USERNAME, password: PASSWORD, use_ssl: USESSL)
    blogs = wpcl.getUsersBlogs

    # find the blog_id and the path to the xmlrpc file
    blogEntry = blogs.select{|b| b['blogName'] == blogTitle}[0]
    blog_url = blogEntry['url']
    BLOG_ID = blogEntry['blogid']
    hostLen = blogEntry['xmlrpc'].index(HOST)+HOST.length
    PATH = blogEntry['xmlrpc'][hostLen..-1]

    # reset the client to the correct path
    wpcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: USESSL)



    content_category_id = ContentCategory.find_by_name('local_news').id
    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}

    p_opts = options.merge(post_id: POST_ID)
    wp_post = wpcl.getPost(p_opts)

    wp = newContentFromWP(blogTitle, wp_post, org, content_category_id, blog_url)

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

  desc "Update legacy raw_content image tags"
  task update_image_sources: :environment do
    contents = Content.where(origin: 'Wordpress Parser').where('raw_content LIKE "%img%"')
    puts "running process_wp_content! on #{contents.count} records"

    contents.each do |c|
      c.process_wp_content!
    end
  end

end
