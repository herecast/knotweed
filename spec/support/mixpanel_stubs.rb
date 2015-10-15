def mixpanel_track_stub
  WebMock.stub_request(:post, "https://api.mixpanel.com/track").
             with(:body => /.*/, :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => {'status' => 1}.to_json, :headers => {})
end
