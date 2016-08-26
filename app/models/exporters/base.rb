
module Exporters
  private

  class BaseExporter
    class << self
      extend Memoist

      public

      def id
        raise NotImplementedError
      end

      def supported_models
        CouchRest::Model::Base.descendants
      end

      def mime_type
        id
      end

      def excluded_properties
        []
      end

      def excluded_forms
        []
      end

      def authorize_fields_to_user?
        true
      end

      #This is a class method that does a one-shot export to a String buffer.
      #Don't use this for large datasets.
      def export(*args)
        exporter_obj = new()
        exporter_obj.export(*args)
        buffer = exporter_obj.complete
        return buffer.string
      end

      def properties_to_export(props)
        props = exclude_forms(props) if self.excluded_forms.present?
        props = properties_to_keys(props)
        props.reject {|p| self.excluded_properties.include?(p.name) } if self.excluded_properties.present?
        return props
      end

      def exclude_forms(props)
        filtered_props = {}
        if props.is_a?(Hash)
          props.each do |mod, forms|
            forms = forms.to_h.reject do |form_name, _|
              self.excluded_forms.include?(form_name)
            end
            filtered_props[mod] = forms
          end
        else
          filtered_props = props
        end
        return filtered_props
      end

      def properties_to_keys(props)
        #This flattens out the properties by modules by form,
        # while maintaining form order and discarding dupes
        if props.present?
          if props.is_a?(Hash)
            props.reduce({}) do |acc1, primero_module|
              hash = primero_module[1].reduce({}) do |acc2, form|
                acc2.merge(form[1])
              end
              acc1.merge(hash)
            end.values
          else
            props
          end
        else
          []
        end
      end

      ## Add other useful information for the report.
      def include_metadata_properties(props, model_class)
        props.each do |pm, fs|
          #TODO: Does order of the special form matter?
          props[pm].merge!(model_class.record_other_properties_form_section)
        end
        return props
      end

      def current_model_class(models)
        if models.present? && models.is_a?(Array)
          models.first.class
        end
      end

      # @param properties: array of CouchRest Model Property instances
      def to_2D_array(models, properties)
        emit_columns = lambda do |props, parent_props=[], &column_generator|
          props.map do |p|
            prop_tree = parent_props + [p]
            if p.array
              longest_array = find_longest_array(models, prop_tree)
              (1..(longest_array || 0)).map do |n|
                new_prop_tree = prop_tree.clone + [n]
                if p.type.include?(CouchRest::Model::Embeddable)
                  emit_columns.call(p.type.properties, new_prop_tree, &column_generator)
                else
                  column_generator.call(new_prop_tree)
                end
              end.flatten
            else
              if !p.type.nil? && p.type.include?(CouchRest::Model::Embeddable)
                emit_columns.call(p.type.properties, prop_tree, &column_generator)
              else
                column_generator.call(prop_tree)
              end
            end
          end.flatten
        end

        header_columns = ['_id', 'model_type'] + emit_columns.call(properties) do |prop_tree|
          pt = prop_tree.clone
          init = pt.shift.name
          pt.inject(init) do |acc, prop|
            if prop.is_a?(Numeric)
              "#{acc}[#{prop}]"
            else
              "#{acc}#{prop.name}"
            end
          end
        end

        yield header_columns

        models.each do |m|
          # TODO: RENAME Child to Case like we should have done months ago
          model_type = {'Child' => 'Case'}.fetch(m.class.name, m.class.name)
          row = [m.id, model_type] + emit_columns.call(properties) do |prop_tree|
            get_value_from_prop_tree(m, prop_tree)
          end

          yield row
        end
      end

      def find_longest_array(models, prop_tree)
        models.map {|m| (get_value_from_prop_tree(m, prop_tree) || []).length }.max
      end
      memoize :find_longest_array

      # TODO: axe this in favor of the similar function in the Accessible model
      # concern.  Have to figure out the inheritance tree for the models first
      # so that all exportable models get that method.
      def get_value_from_prop_tree(model, prop_tree)

        prop_tree.inject(model) do |acc, prop|
          if acc.nil?
            nil
          elsif prop.is_a?(Numeric)
            # We use 1-based numbering in the output but arrays in Ruby are
            # still 0-based
            acc[prop - 1]
          else
            get_model_value(acc, prop)
          end
        end
      end

      #Date field in the index page are displayed with some format
      #and they should be exported using the same format.
      def to_exported_value(value)
        if value.is_a?(Date)
          value.strftime("%d-%b-%Y")
        else
          #Returns original value.
          value
        end
      end

      def get_model_value(model, property)
        exclude_name_mime_types = ['xls', 'csv', 'selected_xls']
        if property.name == 'name' &&  model.module_id == PrimeroModule::GBV && exclude_name_mime_types.include?(id)
          "*****"
        else
          model.send(property.name)
        end
      end
    end

    def initialize(output_file_path=nil)
      @io = if output_file_path.present?
        File.new(output_file_path, "w")
      else
        StringIO.new
      end
    end

    def export(*args)
      raise NotImplementedError
    end

    def complete
      return @io
    end

    def buffer
      return @io
    end
  end
end
