require 'rake'
require 'optparse'

namespace :wordpress do

  desc "Import all published posts in a Wordpress blog"
  task import: :environment do

    blogTitle = 'The Lebanon Beacon'
    unless blogTitle.present?
      puts "no blogTitle passed: use rake wordpress:import -- -b 'My BlogTitle'"
      exit 1
    end
    pub_id = Publication.find_by_name(blogTitle).id
    unless pub_id.present?
      puts "#{blogTitle} does not exist in Publications table"
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
    BLOG_ID = blogEntry['blogid']
    hostLen = blogEntry['xmlrpc'].index(HOST)+HOST.length
    PATH = blogEntry['xmlrpc'][hostLen..-1]

    # reset the client to the correct path
    wpcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: USESSL)

    numProcessed = 0
    content_category_id = ContentCategory.find_by_name('local_news').id

    # get the posts
    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}
    p_opts = options.merge(filter: {post_status: 'publish', number: '150'})
    wp_posts = wpcl.getPosts(p_opts)

    retPosts = wp_posts.count

    # process all the posts
    wp_posts.each do |wp_post|

      # do we already have this entry?
      if Content.find_by_guid(wp_post['guid'])
        puts "'#{wp_post['post_title']}' (#{wp_post['guid']}) already in database"
        next
      end

      # parse the WP post hash into a Content object
      wp = newContentFromWP(blogTitle, wp_post, pub_id, content_category_id)

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
      numProcessed += 1
    end
    puts "Retrieved #{retPosts} posts, processed #{numProcessed}."

    exit 0
  end

  def newContentFromWP(blogTitle, wp_post, pub_id, content_category_id)
    wp = Content.new

    wp.contentsource = blogTitle

    post_tag = wp_post['terms'].select{|t| 'post_tag' == t['taxonomy']}
    tag_pub = Publication.find_by_name(post_tag[0]['name']) if post_tag.present?
    wp.publication_id = tag_pub ? tag_pub.id : pub_id

    wp.title = wp_post['post_title']
    wp.guid = wp_post['guid']
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


  desc "Import a Wordpress post"
  task importone: :environment do

    blogTitle = 'The Norwich Harbinger'
    POST_ID = '489'

    unless blogTitle.present?
      puts "no blogTitle passed: use rake wordpress:import -- -b 'My BlogTitle'"
      exit 1
    end
    pub_id = Publication.find_by_name(blogTitle).id
    unless pub_id.present?
      puts "#{blogTitle} does not exist in Publications table"
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
    BLOG_ID = blogEntry['blogid']
    hostLen = blogEntry['xmlrpc'].index(HOST)+HOST.length
    PATH = blogEntry['xmlrpc'][hostLen..-1]

    # reset the client to the correct path
    wpcl = Rubypress::Client.new(host: HOST, path: PATH, username: USERNAME, password: PASSWORD, use_ssl: USESSL)



    content_category_id = ContentCategory.find_by_name('local_news').id
    options = {blog_id: BLOG_ID, username: USERNAME, password: PASSWORD}

    p_opts = options.merge(post_id: POST_ID)
    wp_post = wpcl.getPost(p_opts)

    wp = newContentFromWP(blogTitle, wp_post, pub_id, content_category_id)

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


=begin
    # testing passing args to allow for changing blogTitle
    puts ARGV
    puts ARGV.class, ARGV.length
    puts "first"
    puts ARGV[0].class
    puts ARGV[0][2..-1]
    #ARGV.shift
    #puts '2: ' + ARGV
    puts ENV

    options = {}

    parser = OptionParser.new
    parser.banner = "Usage: rake wordpress:import [options]"
    parser.on("-b", "--blog {blogname}", "Blog Title (enclosed in quotes)", String) do |blog|
      options[:blog] = blog
    end
    myArgs = parser.order!(ARGV) {}
    parser.parse!(myArgs)

    puts "blogTitle: #{options[:blog]}"
    exit 0
=end
