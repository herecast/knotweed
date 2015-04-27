require 'rspec'

describe 'localize listserve imports' do

  before do
    @config = Hash.new
    @config["username"] = 'subtextuvltest@gmail.com'
    @config["password"] = 'RailRoad202'
    parser_path = Dir.pwd + "/lib/parsers/"
    @test_files_path = Dir.pwd + "/spec/fixtures/listserv_test_files"

    require parser_path + "mail_extractor.rb"

  end

  it 'read entry to norwich' do

    eml = Mail.read(@test_files_path+"/norwich.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['source'].include?('VC Listserv') == true
    parsed_emails[0]['listserv_locations'].length.should == 1
    parsed_emails[0]['listserv_locations'].include?('Norwich,VT') == true

  end

  it 'read entry to norwich and thetford' do

    eml = Mail.read(@test_files_path+"/norwich_thetford.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 2
    parsed_emails[0]['listserv_locations'].include?('Norwich,VT') == true
    parsed_emails[0]['listserv_locations'].include?('Thetford,VT') == true
  end

  it 'read entry to hanover' do

    eml = Mail.read(@test_files_path+"/hanover.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 1
    parsed_emails[0]['listserv_locations'].include?('Hanover,NH') == true

  end

  it 'read entry to woodstock' do

    eml = Mail.read(@test_files_path+"/woodstock.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 1
    parsed_emails[0]['listserv_locations'].include?('Woodstock,VT') == true

  end

  it 'read entry to lebanon' do

    eml = Mail.read(@test_files_path+"/lebanon.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 1
    parsed_emails[0]['listserv_locations'].include?('Lebanon,NH') == true

  end

  it 'read entry to thetford' do

    eml = Mail.read(@test_files_path+"/thetford.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 1
    parsed_emails[0]['listserv_locations'].include?('Thetford,VT') == true

  end

  it 'read entry to lrn' do

    eml = Mail.read(@test_files_path+"/lrn.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 2
    parsed_emails[0]['listserv_locations'].include?('Corinth,VT') == true
    parsed_emails[0]['listserv_locations'].include?('Topsham,VT') == true
  end

  it 'read entry to mascoma and others' do

    eml = Mail.read(@test_files_path+"/mascoma_plus.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 10
    parsed_emails[0]['listserv_locations'].include?('Enfield,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Canaan,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Dorchester,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Grafton,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Orange,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Thetford,VT') == true
    parsed_emails[0]['listserv_locations'].include?('Norwich,VT') == true
    parsed_emails[0]['listserv_locations'].include?('Hanover,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Lebanon,NH') == true
    parsed_emails[0]['listserv_locations'].include?('Hartford,VT') == true
    parsed_emails[0]['listserv_locations'].include?('Upper Valley,') == false

  end

  it 'read entry to strafford' do

    eml = Mail.read(@test_files_path+"/strafford.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 1
    parsed_emails[0]['listserv_locations'].include?('Strafford,VT') == true

  end

  it 'read entry to unknown' do

    eml = Mail.read(@test_files_path+"/unknown_address.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    parsed_emails[0]['listserv_locations'].length.should == 0
  end



end

describe 'init mapping' do

  before do
    parser_path = Dir.pwd + "/lib/parsers/"
    require parser_path + "mail_extractor.rb"

  end
  it 'initializes the listserv mapping' do

    listserv_mapping = init_listserv_mapping

    listserv_mapping.should_not == nil
    listserv_mapping.is_a?(Hash).should == true
    listserv_mapping.length.should > 0

  end
end

