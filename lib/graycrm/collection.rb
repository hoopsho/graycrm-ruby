# frozen_string_literal: true

module GrayCRM
  class Collection
    include Enumerable

    attr_reader :items, :total, :total_pages, :current_page, :next_cursor, :has_more

    def initialize(items:, total: nil, total_pages: nil, current_page: nil, next_cursor: nil, has_more: nil)
      @items = items
      @total = total
      @total_pages = total_pages
      @current_page = current_page
      @next_cursor = next_cursor
      @has_more = has_more
    end

    def each(&block)
      @items.each(&block)
    end

    def size
      @items.size
    end

    alias length size

    def empty?
      @items.empty?
    end

    def [](index)
      @items[index]
    end

    def has_more?
      !!@has_more
    end

    def self.from_response(response, klass)
      data = response["data"] || []
      items = data.map { |attrs| klass.new(attrs) }

      pagination = response["pagination"] || {}
      new(
        items: items,
        total: pagination["total"],
        total_pages: pagination["total_pages"],
        current_page: pagination["page"],
        next_cursor: pagination["next_cursor"],
        has_more: pagination["has_more"]
      )
    end
  end
end
