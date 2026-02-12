# frozen_string_literal: true

module GrayCRM
  class Collection
    include Enumerable

    attr_reader :items, :total, :total_pages, :current_page, :next_cursor, :has_more

    def initialize(items:, total: nil, total_pages: nil, current_page: nil,
                   next_cursor: nil, has_more: nil, klass: nil, path: nil,
                   params: nil, base_path: nil)
      @items = items
      @total = total
      @total_pages = total_pages
      @current_page = current_page
      @next_cursor = next_cursor
      @has_more = has_more
      @klass = klass
      @path = path
      @params = params || {}
      @base_path = base_path
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

    # Fetch the next page of results (cursor or offset).
    # Returns nil when there are no more pages.
    def next_page
      if next_cursor
        next_params = @params.merge(cursor: next_cursor)
        next_params.delete(:page)
        response = GrayCRM.client.get(@path, params: next_params)
        self.class.from_response(response, @klass, path: @path, params: next_params, base_path: @base_path)
      elsif current_page && total_pages && current_page < total_pages
        next_params = @params.merge(page: current_page + 1)
        next_params.delete(:cursor)
        response = GrayCRM.client.get(@path, params: next_params)
        self.class.from_response(response, @klass, path: @path, params: next_params, base_path: @base_path)
      end
    end

    # Iterate through all pages starting from the current one.
    # Returns an Enumerator if no block given.
    def each_page
      return enum_for(:each_page) unless block_given?

      page = self
      loop do
        yield page
        page = page.next_page
        break unless page
      end
    end

    def self.from_response(response, klass, path: nil, params: nil, base_path: nil)
      data = response["data"] || []
      items = data.map do |attrs|
        instance = klass.new(attrs)
        instance._base_path = base_path if base_path
        instance
      end

      pagination = response["pagination"] || {}
      new(
        items: items,
        total: pagination["total"],
        total_pages: pagination["total_pages"],
        current_page: pagination["page"],
        next_cursor: pagination["next_cursor"],
        has_more: pagination["has_more"],
        klass: klass,
        path: path,
        params: params,
        base_path: base_path
      )
    end
  end
end
