def prerender_cache_stub
  WebMock.stub_request(:post, "http://api.prerender.io/recache").
            with(:body => /.*/,:headers => {'Content-Type'=>'application/json'}).  
            to_return(:status => 200, :body => "", :headers => {})
end
