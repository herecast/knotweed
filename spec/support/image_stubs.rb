def google_logo_stub
  # Stub out image requests
  raw_resp = File.new('spec/fixtures/google_logo_resp.txt')
  stub_request(:get, 'https://www.google.com/images/srpr/logo11w.png'). \
    with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
    to_return(raw_resp.read)
end

def google_logo2_stub
  # Stub out image requests
  raw_resp = File.new('spec/fixtures/google_logo_resp.txt')
  stub_request(:get, 'https://www.google.com/images/srpr/logo9w.png'). \
    with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
    to_return(raw_resp.read)
end

def google_logo3_stub
  # Stub out image requests
  raw_resp = File.new('spec/fixtures/google_logo_resp.txt')
  stub_request(:get, 'https://www.google.com/images/srpr/logo7w.png'). \
    with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(raw_resp.read)
end
