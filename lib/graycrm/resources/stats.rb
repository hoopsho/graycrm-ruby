# frozen_string_literal: true

module GrayCRM
  class Stats
    attr_reader :contacts_count, :properties_count, :tags_count, :flags_count,
                :activity_by_date, :top_tags

    def initialize(data)
      @contacts_count = data["contacts_count"]
      @properties_count = data["properties_count"]
      @tags_count = data["tags_count"]
      @flags_count = data["flags_count"]
      @activity_by_date = data["activity_by_date"] || []
      @top_tags = data["top_tags"] || []
    end

    def self.fetch
      response = GrayCRM.client.get("/stats")
      data = response["data"] || response
      new(data)
    end
  end
end
