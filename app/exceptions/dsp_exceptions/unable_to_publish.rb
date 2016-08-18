module DspExceptions
  class UnableToPublish < ::StandardError
    attr_reader :content, :repo, :dsp_response
    def initialize(content, repo, dsp_response)
      @content = content
      @repo = repo
      @dsp_response = dsp_response
      super("failed to publish #{@content.id} to #{@repository.name}: #{@dsp_response}")
    end
  end
end
