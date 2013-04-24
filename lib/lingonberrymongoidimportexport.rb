# encoding: utf-8

# Mass assignment Lingonberry Style
# ==================================
# While there is support for mass assignment in ActiveModel and thus
# in Mongoid, it seems to lack the ability to specify publicly accessible
# fields and fields that are only supposed to be publicly readable.

# Ideally we'd like to have some fields that a client should be able to
# update and some they should be able to read but not update.

# So this is a very basic export/import (or mass assignment) implemenation
# meant to be mixed into a Mongoid model.

# Usage:
# Export with as_external_document.
# Update attributes with hash from client with external_update.

module LingonberryMongoidImportExport
  EXTERNALLY_ACCESSIBLE_FIELDS = []
  EXTERNALLY_READABLE_FIELDS = []

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def as_external_document
     allowed_fields = (EXTERNALLY_ACCESSIBLE_FIELDS + EXTERNALLY_READABLE_FIELDS).map(&:to_s)
     self.as_document.slice(*allowed_fields)
    end

    def external_update!(document_as_hash)
      allowed_updates = document_as_hash.slice(*EXTERNALLY_ACCESSIBLE_FIELDS.map(&:to_s))
      update_attributes!(allowed_updates)
    end
  end

  module ClassMethods
    # Externally accessible fields and embedded documents.
    def externally_accessible(*fields)
      EXTERNALLY_ACCESSIBLE_FIELDS.push(*fields)
    end

    # Externally readable fields and embedded documents.
    def externally_readable(*fields)
      EXTERNALLY_READABLE_FIELDS.push(*fields)
    end
  end
end