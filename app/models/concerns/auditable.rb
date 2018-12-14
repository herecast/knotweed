# app/models/concerns/auditable.rb
#
# Implementing this as a 'concern' in view of us upgrading to Rails 4 at some point.
# The caveat is we don't have access to ActiveSupport::Concern like Rails 4 concerns do,
# but we don't need it for the functionality of this module.
#
# This module can be included in models that have both created_by and updated_by relationships
# with users and implements a before_save callback that appropriately sets those relationships.
# Include it with:
#   include Auditable
#
require 'active_support/concern'

module Auditable
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
    belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by_id'
    before_save :set_auditables
  end

  def set_auditables
    if User.current.present?
      unless persisted? # only set created_by if the object is new
        self.created_by = self.created_by || User.current
      end
      # always set updated_by, even if we're creating
      self.updated_by = User.current
    end
  end
end
