# frozen_string_literal: true

module GrayCRM
  class Relation
    include Enumerable

    def initialize(klass, path = nil)
      @klass = klass
      @path = path || klass.resource_path
      @filters = {}
      @page_num = nil
      @per_num = nil
      @cursor_token = nil
    end

    def where(filters = {})
      dup.tap do |r|
        r.instance_variable_set(:@filters, @filters.merge(filters))
        r.instance_variable_set(:@collection, nil)
      end
    end

    def page(num)
      dup.tap do |r|
        r.instance_variable_set(:@page_num, num)
        r.instance_variable_set(:@collection, nil)
      end
    end

    def per(num)
      dup.tap do |r|
        r.instance_variable_set(:@per_num, num)
        r.instance_variable_set(:@collection, nil)
      end
    end

    def cursor(token)
      dup.tap do |r|
        r.instance_variable_set(:@cursor_token, token)
        r.instance_variable_set(:@collection, nil)
      end
    end

    def each(&block)
      collection.each(&block)
    end

    def to_a
      collection.to_a
    end

    def collection
      @collection ||= fetch
    end

    def first
      per(1).to_a.first
    end

    def count
      collection.total || collection.to_a.size
    end

    def find(id)
      @klass.find(id)
    end

    def create(attrs = {})
      resource_key = @klass.resource_name
      response = GrayCRM.client.post(@path, body: { resource_key => attrs })
      data = response.is_a?(Hash) && response["data"] ? response["data"] : response
      @klass.new(data)
    end

    private

    def fetch
      params = build_params
      response = GrayCRM.client.get(@path, params: params)
      Collection.from_response(response, @klass, path: @path, params: params)
    end

    def build_params
      params = {}

      @filters.each do |key, value|
        case key
        when :flag
          params[:flag_key] = value[:key] if value[:key]
          params[:flag_value] = value[:value] if value[:value]
        when :tag
          params[:tag] = value
        when :attr
          params[:attr_key] = value[:key] if value[:key]
          params[:attr_value] = value[:value] if value[:value]
        when :app_tag
          params[:app_tag] = value
        else
          params[:"q[#{key}]"] = value
        end
      end

      params[:page] = @page_num if @page_num
      params[:per_page] = @per_num || GrayCRM.configuration.per_page
      params[:cursor] = @cursor_token if @cursor_token

      params
    end
  end

  class NestedRelation < Relation
    def create(attrs = {})
      resource_key = @klass.resource_name
      response = GrayCRM.client.post(@path, body: { resource_key => attrs })
      data = response.is_a?(Hash) && response["data"] ? response["data"] : response
      instance = @klass.new(data)
      instance._base_path = @path
      instance
    end

    private

    def fetch
      params = build_params
      response = GrayCRM.client.get(@path, params: params)
      Collection.from_response(response, @klass, path: @path, params: params, base_path: @path)
    end
  end
end
