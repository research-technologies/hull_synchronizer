module DataCrosswalks
  class DataArchiveModel

    def calm_fields
      [
        filename,
        accession_number,
        reference,
        title,
        access_status,
        copyright,
        creator,
        date,
        user_description,
        keywords,
        language,
        depositor,
        level
      ]
    end

    def dao_fields
      []
    end

    def required_fields
      [
        filename,
        accession_number,
        reference
      ]
    end

    def id
      'id'
    end

    def access_levels
      'access_levels'
    end

    def access_status
      'access_status'
    end

    def accession_number
      'accession_number'
    end

    def copyright
      'copyright'
    end

    def creator
      'creator'
    end

    def creation_status
      'creation_status'
    end

    def data_classification
      'data_classification'
    end

    def date
      'date'
    end

    def date_added
      'date_added'
    end

    def date_created
      'date_created'
    end

    def date_modified
      'date_modified'
    end

    def depositor
      'depositor'
    end

    def description
      'description'
    end

    def filename
      'filename'
    end

    def file_location
      'file_location'
    end

    def file_size
      'file_size'
    end

    def keywords
      'keywords'
    end

    def language
      'language'
    end

    def last_modified_by
      'last_modified_by'
    end

    def orientation
      'orientation'
    end

    def original_filename
      'original_filename'
    end

    def ip_ownership
      'ip_ownership'
    end

    def photo_credit
      'photo_credit'
    end

    def related_items
      'related_items'
    end

    def reference
      'reference'
    end

    def title
      'title'
    end

    def usage_rights
      'usage_rights'
    end

    def user_description
      'user_description'
    end

    def level
      'level'
    end

  end
end
