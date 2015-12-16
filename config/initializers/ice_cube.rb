# avoid deprecation warnings about syntax we're not using
IceCube.compatibility = 12

module IceCube
  class ValidatedRule
    def dst_adjust?
      false
    end
  end
end
