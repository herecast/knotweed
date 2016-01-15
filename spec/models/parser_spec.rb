# == Schema Information
#
# Table name: parsers
#
#  id              :integer          not null, primary key
#  filename        :string(255)
#  organization_id :integer
#  name            :string(255)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'
require 'lib/parsers/wordpress_blog_parser.rb'

describe Parser do

  # the test input and expected output is kept outside the test in spec/fixtures/wp_import
  # each _input file must have a matching named file ending with _output.
  describe 'when content includes YouTube URLs' do
    input_files = Dir['spec/fixtures/wp_import/*_input']
    output_files = Dir['spec/fixtures/wp_import/*_output']
    config = {'host' => 'example.com', "username"=>"testuser",
              "password"=>"password", "blogurl"=>"http://example.com/blog/",
              'url' => 'http://example.com/blog/' }
    raise 'unable to find any input files for this test!' if input_files.blank?

    input_files.each do |input_file|
      it "should convert them to iframes (#{input_file})" do
        output_file = input_file.gsub '_input', '_output'
        raise 'expected parsed output file not found' unless output_files.include? output_file
        raw_content = File.read input_file
        wp_post = JSON.parse raw_content

        # parse_post expects post_date_gmt to be in XMLRPC::DateTime format
        pubdate = wp_post['post_date_gmt']
        wp_post['post_date_gmt'] = XMLRPC::DateTime.new(pubdate['year'], pubdate['month'], pubdate['day'], pubdate['hour'], pubdate['min'], pubdate['sec'])

        doc = parse_post(wp_post, 'local_news', config)
        result = JSON.parse(File.read(output_file))
        doc['content'].should eq result['content']
      end
    end
  end

end
