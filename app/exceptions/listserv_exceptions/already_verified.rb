module ListservExceptions
  class AlreadyVerified < ::StandardError
    def initialize(model)
      @model = model
      super("ListervContent: #{model.id} has already been verified.")
    end
  end
end
