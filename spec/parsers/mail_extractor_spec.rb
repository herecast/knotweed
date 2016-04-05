# encoding: UTF-8
require 'spec_helper'
require "#{Rails.root}/lib/parsers/mail_extractor.rb"

describe 'mail_extractor.rb parser helper' do
  describe '#convert_eml_to_hasharray' do
    before { @config = {} }

    # convert_eml_to_hasharray returns an array of hashes, but this file outputs an array
    # of length 1
    subject { convert_eml_to_hasharray(Mail.read("#{fixture_path}/parser_inputs/#{filename}"), @config)[0] }

    describe 'config' do
      # doesn't matter what file input we use here
      let(:filename) { 'valleynet_listserv_1.eml' }
      
      { 
        'copyright' => 'Test Copyright'
      }.each do |k,v|
        it "should use the config value for #{k}" do
          @config[k] = v
          subject[k].should eq v
        end
      end
    end

    describe 'valleynet_listserv_1.eml' do
      let(:filename) { 'valleynet_listserv_1.eml' }

      { 
        'authoremail' => "Gwendolyn.Thompson@VALLEY.NET (Gwendolyn Thompson)",
        'authors' => "Gwendolyn.Thompson@VALLEY.NET (Gwendolyn Thompson)",
        "location" => "Norwich",
        "title" => "[Norwich] Office equipment for sale",
        "pubdate" => DateTime.parse('Mon, 04 Apr 2016 21:15:41 -0400'),
        "content" => "Office equipment for sale, all perfect condition \n\n\nSiddons Office Chair, black upholstery, contoured design, adjustable, asking $50.00 \n\n2 Poppin 3 drawer file cabinets, white with blue, new $229 each, asking $75.00 each \n\nBrookfield Natural Spectrum Desk lamp by Verilux , brushed nickle, new $129, asking $50.00 \n\n6’ metal work table, about 30 inches deep, BO \n\ncomputer desk, black, wood, drawer for keyboard, BO \n\nBrothers FAX, laser Fax, Super G3, 33.6, Intellifax 2840, BO \n\n\nHP Color Laser Jet PRo MFP M47 6nw, new $499.00, asking BO \n",
        "guid" => "184218229@retriever.VALLEY.NET",
        "content_locations" => ["Norwich,VT"]
      }.each do |k,v|
        it "should correctly determine #{k}" do
          subject[k].should eq v
        end
      end
    end

    describe 'valleynet_listserv_2.eml' do
      let(:filename) { 'valleynet_listserv_2.eml' }

      {
        "authors" => "Linda Bryan",
        "authoremail" => "linda@redhousestudio.com",
        "location" => "Bradford",
        "title" => "[Bradford] Photography Workshops at Tenney Library",
        "in_reply_to" => nil,
        "guid" => "CE39EB45-07EA-4C6B-A42E-E4725EC7804C@redhousestudio.com",
        "pubdate" => DateTime.parse('Tue, 02 Feb 2016 08:53:41 -0500'),
        "content_locations" => ["Bradford,VT"]
      }.each do |k,v|
        it "should correctly determine #{k}" do
          subject[k].should eq v
        end
      end
    end

    # this one is content type multipart
    describe 'valleynet_listserv_3.eml' do
      let(:filename) { 'valleynet_listserv_3.eml' }

      {
        "authors" => "Danielle Robinson",
        "authoremail" => "administrator@bradford-vt.us",
        "location" => "Bradford",
        "title" => "[Bradford] Town of Bradford- Special Meeting Warning",
        "guid" => "006401d18f65$71a4ce30$54ee6a90$@bradford-vt.us",
        "pubdate" => DateTime.parse('Tue, 05 Apr 2016 14:03:20 -0400'),
        'content_locations' => ["Bradford,VT"]
      }.each do |k,v|
        it "should correctly assign #{k}" do
          subject[k].should eq v
        end
      end
    end
  end

  describe '#is_listserve_address' do
    subject { is_listserve_address(email) }

    describe 'typical listserv emails' do
      let(:email) { "norwich@lists.valley.net" }

      it { should be_true }
    end

    describe 'request listserv emails' do
      let(:email) { "request@lists.valley.net" }

      it { should be_false }
    end

    describe 'upper valley listserv emails' do
      let(:email) { "uppervalley@lists.valley.net" }

      it { should be_false }
    end
  end
end
