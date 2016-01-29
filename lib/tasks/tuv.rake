require 'csv'
require 'parsers/wordpress_blog_parser.rb'
require 'rake'

# this file was exported from the users table for TheUpperValley.com.  I added three columns,
# publication, copyright and duser_id (dailyUV user_id).  Rows from this table are selected
# by the WP user id which is passed in post['post_author'] and then applied to customize the
# information passed to the parse_post function in wordpress_blog_parser.rb
users_path = File.join(File.dirname(__FILE__),'tuv_users-20160111.csv')

namespace :tuv_import do

  desc 'Import data from TheUpperValley.com Wordpress site'
  task import: :environment do

    # get the user information
    users = read_users_csv(users_path)
    puts "Read #{users.count} users from #{users_path}"

    # setup the WP client
    wpcl = setup_client

    # get the raw post info
    wp_posts = get_posts(wpcl, 850)
    puts "Read #{wp_posts.count} posts from #{wpcl.host}"

    # transform posts using parse_post from wordpress_blog_parser.rb
    docs = process_posts(wp_posts, users)
    puts "Prepared #{docs.count} docs for import"

    # import posts to MySQL and publish
    import_posts(docs)
    puts "\nImported #{docs.count} posts of the original #{wp_posts.count} posts from #{wpcl.host}\n"
  end
end

def read_users_csv(path)
  CSV.read(path, {:headers => true, :header_converters => :symbol, :converters => :all})
end

def setup_client
  Rubypress::Client.new(host: 'uppervalley.usmblogs.com', path: '/xmlrpc.php',
                        username: 'sarahbarnes', password: '360#rt120', use_ssl: false)
end

def get_posts(wpcl, number)
  options = {:blog_id=>560, :username=>'sarahbarnes', :password=>'360#rt120',
             :filter=>{:post_status=>'publish', :number=>number}}
  wpcl.getPosts(options)
end

# NG NOTE: all the references to 'publication' in this rake task are specific
# to the context of the data being parsed. So, to avoid having to change a bunch of code
# that is internally consistent, I'm leaving it 'publication' instead of changing to
# 'organization'

def process_posts(posts, users)
  contents = []

  config = {'blogname' => 'The Upper Valley', 'host' => 'uppervalley.usmblogs.com', 'username' => 'sarahbarnes',
            'password' => '360#rt120', 'url' => 'http://theuppervalley.com/', 'copyright' => 'TheUpperValley.com'}

  posts.each do | post |

    # We only want to import posts from users who have a publication in the users array
    user = get_user(users, post['post_author'])
    if user.present? and user[:publication].present?
      # prepare custom fields and other hashes for parse_post
      post['custom_fields'] << {'key' => 'author', 'value' => user[:displayname]}
      post['custom_fields'] << {'key' => 'publication', 'value' => user[:publication]}
      post['custom_fields'] << {'key' => 'userid', 'value' => user[:duser_id]}
      post['contentsource'] = 'TheUpperValley.com'
      if post['post_thumbnail'].present?
        image_link = post['post_thumbnail']['link']
        post['post_content'] = "<img src=\"#{image_link}\"> " + post['post_content']
      end

      # overwrite some of the config fields for a revshare blogger's entries
      config['copyright'] = user[:copyright]
      config['blogname'] = user[:publication]

      # use the wordpress_blog_parser's parse_post() function to prep hash for import
      content = parse_post(post, 'local_news', config)
      contents << content unless content.empty?
    end

  end

  contents

end

def import_posts(docs)
  ij = ImportJob.new(name: 'The Upper Valley.com - temp', job_type: 'ad_hoc',
                     stop_loop: true, automatically_publish: true,
                     repository_id: 3, publish_method: 'publish_to_dsp')
  ij.before(self) # sets up logging
  ij.docs_to_contents(docs)
  ij.delete
end

def get_user(users, userid)
  users.select { |u| u[:userid] == userid.to_i}[0]
end
