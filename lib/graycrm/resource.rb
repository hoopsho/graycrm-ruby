# frozen_string_literal: true

require 'set'

module GrayCRM
  class Resource
    class << self
      attr_accessor :resource_path
      attr_reader :attribute_names, :nested_resources

      def attribute(*names)
        @attribute_names ||= []
        @attribute_names.concat(names.map(&:to_s))

        names.each do |name|
          define_method(name) { @attributes[name.to_s] }
          define_method(:"#{name}=") { |v| @attributes[name.to_s] = v; @changed_attributes.add(name.to_s) }
        end
      end

      def has_many(name, class_name: nil, path: nil)
        @nested_resources ||= {}
        @nested_resources[name] = {
          class_name: class_name || name.to_s.split("_").map(&:capitalize).join,
          path: path || name.to_s
        }

        define_method(name) do
          nested_path = "#{self.class.resource_path}/#{id}/#{self.class.nested_resources[name][:path]}"
          klass_name = self.class.nested_resources[name][:class_name]
          klass = GrayCRM.const_get(klass_name)
          NestedRelation.new(klass, nested_path)
        end
      end

      def find(id)
        response = GrayCRM.client.get("#{resource_path}/#{id}")
        data = response.is_a?(Hash) && response["data"] ? response["data"] : response
        new(data)
      end

      def all
        Relation.new(self)
      end

      def where(filters = {})
        Relation.new(self).where(filters)
      end

      def page(num)
        Relation.new(self).page(num)
      end

      def per(num)
        Relation.new(self).per(num)
      end

      def cursor(token)
        Relation.new(self).cursor(token)
      end

      def create(attrs = {})
        resource_key = resource_name
        response = GrayCRM.client.post(resource_path, body: { resource_key => attrs })
        data = response.is_a?(Hash) && response["data"] ? response["data"] : response
        new(data)
      rescue ValidationError
        nil
      end

      def create!(attrs = {})
        resource_key = resource_name
        response = GrayCRM.client.post(resource_path, body: { resource_key => attrs })
        data = response.is_a?(Hash) && response["data"] ? response["data"] : response
        new(data)
      end

      def resource_name
        name.split("::").last.gsub(/([A-Z])/, '_\1').sub(/^_/, "").downcase
      end
    end

    attr_reader :attributes
    attr_accessor :_base_path

    def initialize(attrs = {})
      @attributes = {}
      @changed_attributes = Set.new
      @_base_path = nil
      attrs.each { |k, v| @attributes[k.to_s] = v }
    end

    def id
      @attributes["id"]
    end

    def new_record?
      id.nil?
    end

    def persisted?
      !new_record?
    end

    def changed?
      @changed_attributes.any?
    end

    def save
      perform_save
      @changed_attributes.clear
      self
    rescue ValidationError => e
      @_last_validation_error = e
      false
    end

    def save!
      perform_save
      @changed_attributes.clear
      self
    end

    def update(attrs = {})
      attrs.each { |k, v| @attributes[k.to_s] = v; @changed_attributes.add(k.to_s) }
      save
    end

    def update!(attrs = {})
      attrs.each { |k, v| @attributes[k.to_s] = v; @changed_attributes.add(k.to_s) }
      save!
    end

    def destroy
      GrayCRM.client.delete(instance_path)
      true
    end

    def reload
      response = GrayCRM.client.get(instance_path)
      data = response.is_a?(Hash) && response["data"] ? response["data"] : response
      @attributes = data
      @changed_attributes.clear
      self
    end

    def to_h
      @attributes.dup
    end

    def to_json(*args)
      @attributes.to_json(*args)
    end

    def inspect
      "#<#{self.class.name} #{@attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')}>"
    end

    private

    def perform_save
      if persisted?
        body = { self.class.resource_name => changed_hash }
        response = GrayCRM.client.patch(instance_path, body: body)
      else
        body = { self.class.resource_name => @attributes }
        path = @_base_path || self.class.resource_path
        response = GrayCRM.client.post(path, body: body)
      end
      data = response.is_a?(Hash) && response["data"] ? response["data"] : response
      @attributes.merge!(data)
    end

    def instance_path
      "#{@_base_path || self.class.resource_path}/#{id}"
    end

    def changed_hash
      @changed_attributes.each_with_object({}) { |k, h| h[k] = @attributes[k] }
    end
  end
end
