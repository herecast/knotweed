require 'spec_helper'

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

    expect(parsed_emails[0]['source'].include?('Listserv')).to eq(true)
    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    parsed_emails[0]['content_locations'].include?('Norwich,VT') == true

  end

  it 'read reply to norwich post' do

    eml = Mail.read(@test_files_path+'/norwich_re.txt')
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['source'].include?('Listserv')).to eq(true)
    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    parsed_emails[0]['content_locations'].include?('Norwich,VT') == true

  end

  it 'read entry to norwich and thetford' do

    eml = Mail.read(@test_files_path+"/norwich_thetford.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(2)
    expect(parsed_emails[0]['content_locations'].include?('Norwich,VT')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Thetford,VT')).to eq(true)
  end

  it 'read entry to hanover' do

    eml = Mail.read(@test_files_path+"/hanover.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    expect(parsed_emails[0]['content_locations'].include?('Hanover,NH')).to eq(true)

  end

  it 'read entry to woodstock' do

    eml = Mail.read(@test_files_path+"/woodstock.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    expect(parsed_emails[0]['content_locations'].include?('Woodstock,VT')).to eq(true)

  end

  it 'read entry to lebanon' do

    eml = Mail.read(@test_files_path+"/lebanon.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    expect(parsed_emails[0]['content_locations'].include?('Lebanon,NH')).to eq(true)

  end

  it 'read entry to thetford' do

    eml = Mail.read(@test_files_path+"/thetford.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    expect(parsed_emails[0]['content_locations'].include?('Thetford,VT')).to eq(true)

  end

  it 'read entry to lrn' do

    eml = Mail.read(@test_files_path+"/lrn.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(2)
    expect(parsed_emails[0]['content_locations'].include?('Corinth,VT')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Topsham,VT')).to eq(true)
  end

  it 'read entry to mascoma and others' do

    eml = Mail.read(@test_files_path+"/mascoma_plus.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(10)
    expect(parsed_emails[0]['content_locations'].include?('Enfield,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Canaan,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Dorchester,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Grafton,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Orange,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Thetford,VT')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Norwich,VT')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Hanover,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Lebanon,NH')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Hartford,VT')).to eq(true)
    expect(parsed_emails[0]['content_locations'].include?('Upper Valley,')).to eq(false)

  end

  it 'read entry to strafford' do

    eml = Mail.read(@test_files_path+"/strafford.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(1)
    expect(parsed_emails[0]['content_locations'].include?('Strafford,VT')).to eq(true)

  end

  it 'read entry to unknown' do

    eml = Mail.read(@test_files_path+"/unknown_address.txt")
    parsed_emails = convert_eml_to_hasharray(eml, @config)

    expect(parsed_emails[0]['content_locations'].length).to eq(0)
  end



end

describe 'init mapping' do

  before do
    parser_path = Dir.pwd + "/lib/parsers/"
    require parser_path + "mail_extractor.rb"

  end
  it 'initializes the listserv mapping' do

    listserv_mapping = init_listserv_mapping

    expect(listserv_mapping).not_to eq(nil)
    expect(listserv_mapping.is_a?(Hash)).to eq(true)
    expect(listserv_mapping.length).to be > 0

  end
end
