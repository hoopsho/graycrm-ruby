# frozen_string_literal: true

module GrayCRM
  class Batch
    Result = Struct.new(:index, :status, :data, :error, keyword_init: true)

    def self.execute(operations)
      response = GrayCRM.client.post("/batch", body: { operations: operations })
      results = response["data"] || response["results"] || []
      results.map do |r|
        Result.new(
          index: r["index"],
          status: r["status"],
          data: r["data"],
          error: r["error"]
        )
      end
    end
  end
end
