require 'rspec'

describe 'parse upper valley list files' do

  before do
    @config = Hash.new
    @config["username"] = 'subtextuvltest@gmail.com'
    @config["password"] = 'RailRoad202'
    parser_path = Dir.pwd + "/lib/parsers/"
    @test_files_path = Dir.pwd + "/spec/fixtures/upper_valley_list_test_files"

    require parser_path + "upper_valley_list_parser.rb"

  end

  it 'source should be Listserv, and location Upper Valley' do

    body = get_body_from_file("/TwoEntries.html")
    results = []
    all_posts = find_posts(body)

    parse_posts(all_posts, results)

    results.should_not == nil
    results.each do |post|
        post['source'].should == 'Listserv'
        post['content_locations'][0].should == 'Upper Valley,'
    end

  end

  def get_body_from_file(filename)

    f = File.open(@test_files_path + filename)
    body = ""

    f.each_line do |line|
      body << line
    end
    f.close

    body
  end

end