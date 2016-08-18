module DspExceptions
  class UnableToClassify < ::StandardError
    attr_reader :content, :repo
    def initialize(content, repo)
      @content = content
      @repo = repo
      super("#{repo} failed to return a category for #{@content.class.to_s} #{@content.id}")
    end
  end
end
