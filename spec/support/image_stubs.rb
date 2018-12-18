# frozen_string_literal: true

def google_logo_stub
  # Stub out image requests
  stub_request(:get, 'https://www.google.com/images/srpr/logo11w.png') \
    .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
    .to_return(status: 200, headers: {}, body: File.read('spec/fixtures/photo.png'))
end

def google_logo2_stub
  # Stub out image requests
  stub_request(:get, 'https://www.google.com/images/srpr/logo9w.png') \
    .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
    .to_return(status: 200, headers: {}, body: File.read('spec/fixtures/photo.png'))
end

def google_logo3_stub
  # Stub out image requests
  stub_request(:get, 'https://www.google.com/images/srpr/logo7w.png') \
    .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
    .to_return(status: 200, headers: {}, body: File.read('spec/fixtures/photo.png'))
end

def google_logo4_stub
  # Stub out image requests
  stub_request(:get, 'https://www.google.com/images/srpr/logo6w.png') \
    .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
    .to_return(status: 200, headers: {}, body: File.read('spec/fixtures/photo.png'))
end

def google_logo5_stub
  # Stub out image requests
  stub_request(:get, 'https://www.google.com/images/srpr/logo5w.png') \
    .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
    .to_return(status: 200, headers: {}, body: File.read('spec/fixtures/photo.png'))
end
