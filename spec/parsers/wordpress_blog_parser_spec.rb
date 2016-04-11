require 'spec_helper'


describe 'Wordpress Blog Parser' do
  let(:mock_rubypress_client) { double() }
  before do
    allow(Rubypress::Client).to receive(:new).and_return(mock_rubypress_client)
    load File.join(Rails.root, 'lib','parsers','wordpress_blog_parser.rb')
  end

  describe '#parse_file' do
    context 'given valid url and config;' do
      let(:url) { 'http://myblog.example' }
      let(:config) do
        {
          'host'     => url,
          'blogname' => 'myblog',
          'username' => 'johndoe',
          'password' => 'drowssap'
        }
      end

      subject { parse_file(url, config) }

      context 'when userblog exists with same name;' do
        let(:user_blogs_response) do
          [{
            'blogName' => config['blogname'],
            'url'      => url,
            'blogid'   => 1,
            'isAdmin'  => false,
            'xmlrpc'  => url + '/xmlrpc.php'
          }]
        end

        before do
          allow(mock_rubypress_client).to receive(:getUsersBlogs).and_return(user_blogs_response)
        end

        it 'fetches published posts ordered by post_date desc in the user blog' do
          expect(mock_rubypress_client).to receive(:getPosts).with(
            hash_including({
              blog_id: 1,
              username: config['username'],
              password: config['password'],
              filter: hash_including({
                post_status: 'publish',
                orderby: 'post_date',
                order: 'desc'
              })
            })
          ).and_return([])

          subject
        end

        context 'When posts exist;' do
          let(:wp_post_data) do
            {
              'post_id' => 2,
              'post_status' => 'publish',
              'post_title' => 'The title of my fine post',
              'guid' => 'c61bcbe3-ff40-48bf-8d2c-cdc1e6c41b05',
              'post_date_gmt' => Time.now.strftime('%F %T'),
              'custom_fields' => [
                { 'key' => 'author', 'value' => 'Jim Bob' },
                { 'key' => 'userid', 'value' => '1' },
              ],
              'post_content' => '<p>My Wonderful Content</p>'
            }
          end

          before do
            allow(mock_rubypress_client).to receive(:getPosts).and_return([wp_post_data])
          end

          it 'returns parsed contents' do
            expected = {
              'contentsource' => config['blogname'],
              'title' => 'The title of my fine post',
              'guid' => wp_post_data['guid'],
              'url' => url + "?p=2",
              'origin' => 'Wordpress Parser',
              'pubdate' => wp_post_data['post_date_gmt'].to_time,
              'authors' => 'Jim Bob',
              'source' => 'dailyUV News',
              'content' => wp_post_data['post_content']
            }

            expected.each do |k,v|
              expect(subject.first[k]).to eql v
            end
          end

          context 'When images are in content;' do
            before do
              wp_post_data['post_content'] += "<img src='http://placehold.it/300/300'/>"
              wp_post_data['post_content'] += "<img src='http://placehold.it/600/600'/>"
            end

            it 'returns the them under the "images" key' do
              images = subject.first['images']
              expect(images.count).to be 2
              expect( images.select{|i| i['image'] == 'http://placehold.it/300/300'}.count ).to be > 0
              expect( images.select{|i| i['image'] == 'http://placehold.it/600/600'}.count ).to be > 0
            end

            it 'sets the first one as the primary' do
              images = subject.first['images']
              primary = images.select{|i| i['primary']}.first
              expect( primary['image'] ).to eql 'http://placehold.it/300/300'
            end
          end
        end
      end
    end
  end
end
