# frozen_string_literal: true

module GrayCRM
  class Search
    Result = Struct.new(:contacts, :properties, :tags, :total_count, keyword_init: true)

    def self.query(q, per_resource: 5)
      response = GrayCRM.client.get("/search", params: { q: q, per_resource: per_resource })
      data = response["data"] || {}
      meta = response["meta"] || {}

      Result.new(
        contacts: (data["contacts"] || []).map { |c| Contact.new(c) },
        properties: (data["properties"] || []).map { |p| Property.new(p) },
        tags: (data["tags"] || []).map { |t| Tag.new(t) },
        total_count: meta["total_count"] || 0
      )
    end
  end
end
