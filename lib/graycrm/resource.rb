# frozen_string_literal: true

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
          define_method(:"#{name}=") { |v| @attributes[name.to_s] = v; @changed_attributes << name.to_s }
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
      end

      def create!(attrs = {})
        create(attrs)
      end

      def resource_name
        name.split("::").last.gsub(/([A-Z])/, '_\1').sub(/^_/, "").downcase
      end
    end

    attr_reader :attributes

    def initialize(attrs = {})
      @attributes = {}
      @changed_attributes = []
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
      if persisted?
        body = { self.class.resource_name => changed_hash }
        response = GrayCRM.client.patch("#{self.class.resource_path}/#{id}", body: body)
        data = response.is_a?(Hash) && response["data"] ? response["data"] : response
        @attributes.merge!(data)
      else
        body = { self.class.resource_name => @attributes }
        response = GrayCRM.client.post(self.class.resource_path, body: body)
        data = response.is_a?(Hash) && response["data"] ? response["data"] : response
        @attributes.merge!(data)
      end
      @changed_attributes.clear
      self
    rescue ValidationError
      false
    end

    def save!
      result = save
      raise GrayCRM::ValidationError, "Save failed" if result == false
      self
    end

    def update(attrs = {})
      attrs.each { |k, v| @attributes[k.to_s] = v; @changed_attributes << k.to_s }
      save
    end

    def update!(attrs = {})
      attrs.each { |k, v| @attributes[k.to_s] = v; @changed_attributes << k.to_s }
      save!
    end

    def destroy
      GrayCRM.client.delete("#{self.class.resource_path}/#{id}")
      true
    end

    def reload
      response = GrayCRM.client.get("#{self.class.resource_path}/#{id}")
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

    def changed_hash
      @changed_attributes.each_with_object({}) { |k, h| h[k] = @attributes[k] }
    end
  end
end
