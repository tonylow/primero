module RecordActions
  extend ActiveSupport::Concern

  include ImportActions
  include ExportActions
  include TransitionActions
  include MarkForMobileActions

  included do
    skip_before_filter :verify_authenticity_token
    skip_before_filter :check_authentication, :only => [:reindex]

    before_filter :load_record, :except => [:new, :create, :index, :reindex]
    before_filter :current_user, :except => [:reindex]
    before_filter :get_lookups, :only => [:new, :edit, :index]
    before_filter :load_locations, :only => [:new, :edit]
    before_filter :current_modules, :only => [:show, :index]
    before_filter :is_manager, :only => [:index]
    before_filter :is_admin, :only => [:index]
    before_filter :is_cp, :only => [:index]
    before_filter :is_gbv, :only => [:index]
    before_filter :is_mrm, :only => [:index]
    before_filter :load_consent, :only => [:show]
    before_filter :sort_subforms, :only => [:show, :edit]
  end

  def list_variable_name
    model_class.name.pluralize.underscore
  end

  def index
    authorize! :index, model_class
    @page_name = t("home.view_records")
    @aside = 'shared/sidebar_links'
    @associated_users = current_user.managed_user_names
    @filters = record_filter(filter)
    #make sure to get all records when querying for ids to sync down to mobile
    params['page'] = 'all' if params['mobile'] && params['ids']
    @records, @total_records = retrieve_records_and_total(@filters)

    @referral_roles = Role.by_referral.all
    @transfer_roles = Role.by_transfer.all
    module_ids = @records.map(&:module_id).uniq if @records.present? && @records.is_a?(Array)
    @associated_agencies = User.agencies_by_user_list(@associated_users).map{|a| {a.id => a.name}}
    @options_districts = Location.by_type_enabled.key('district').all.map{|loc| loc.placename}.sort
    module_users(module_ids) if module_ids.present?

    # Alias @records to the record-specific name since ERB templates use that
    # right now
    # TODO: change the ERB templates to just accept the @records instance
    # variable
    instance_variable_set("@#{list_variable_name}", @records)

    @per_page = per_page

    # @highlighted_fields = []

    respond_to do |format|
      format.html
      unless params[:password]
        format.json do
          @records = @records.select{|r| r.marked_for_mobile} if params[:mobile].present?
          if params[:ids].present?
            @records = @records.map{|r| r.id}
          else
            @records = @records.map{|r| r.format_json_response}
          end
          render :json => @records
        end
      end
      unless params[:format].nil? || params[:format] == 'json'
        if @records.empty?
          flash[:notice] = t('exports.no_records')
          redirect_to :action => :index and return
        end
      end

      respond_to_export format, @records
    end
  end

  def show
    authorize! :read, (@record || model_class)

    @referral_roles = Role.by_referral.all
    @transfer_roles = Role.by_transfer.all
    @associated_users = current_user.managed_user_names
    module_users([@record.module_id]) if @record.present?

    respond_to do |format|
      format.html do
        if @record.nil?
          redirect_on_not_found
          return
        end

        @page_name = t "#{model_class.locale_prefix}.view", :short_id => @record.short_id
        @body_class = 'profile-page'
        @duplicates = model_class.duplicates_of(params[:id])
        @form_sections = @record.allowed_formsections(current_user)
      end

      format.json do
        if @record.present?
          @record = format_json_response(@record)
          render :json => @record
        else
          render :json => '', :status => :not_found
        end
      end unless params[:password]

      respond_to_export format, [ @record ]
    end
  end

  def new
    authorize! :create, model_class

    # Ugh...why did we make two separate locale namespaces for each record type (cases/children have four)?
    @page_name = t("#{model_class.locale_prefix.pluralize}.register_new_#{model_class.locale_prefix}")

    @record = make_new_record
    # TODO: make the ERB templates use @record
    instance_variable_set("@#{model_class.name.underscore}", @record)

    @form_sections = @record.allowed_formsections(current_user)

    respond_to do |format|
      format.html
    end
  end

  def create
    authorize! :create, model_class
    reindex_hash record_params
    @record = create_or_update_record(params[:id])
    initialize_created_record(@record)
    respond_to do |format|
      @form_sections = @record.allowed_formsections(current_user)
      if @record.save
        post_save_processing @record
        flash[:notice] = t("#{model_class.locale_prefix}.messages.creation_success", record_id: @record.short_id)
        format.html { redirect_after_update }
        format.json do
          @record = format_json_response(@record)
          render :json => @record, :status => :created, :location => @record
        end
      else
        format.html {
          get_lookups
          load_locations
          render :action => "new"
        }
        format.json { render :json => @record.errors, :status => :unprocessable_entity }
      end
    end
  end

  def post_save_processing record
    # This is for operation after saving the record.
  end

  def edit
    if @record.nil?
      redirect_on_not_found
      return
    end

    authorize! :update, @record

    @form_sections = @record.allowed_formsections(current_user)
    @page_name = t("#{model_class.locale_prefix}.edit")
  end

  def update
    respond_to do |format|
      create_or_update_record(params[:id])
      if @record.save
        format.html do
          flash[:notice] = I18n.t("#{model_class.locale_prefix}.messages.update_success", record_id: @record.short_id)
          if params[:redirect_url]
            redirect_to "#{params[:redirect_url]}?follow=true"
          else
            redirect_after_update
          end
        end
        format.json do
          @record = format_json_response(@record)
          render :json => @record
        end
      else
        @form_sections ||= @record.allowed_formsections(current_user)
        format.html {
          get_lookups
          load_locations
          render :action => "edit"
        }
        format.json { render :json => @record.errors, :status => :unprocessable_entity }
      end
    end
  end

  def sort_subforms
    if @record.present?
      @record.field_definitions.select{|f| !f.subform_sort_by.nil?}.each do |field|
        if @record[field.name].present?
          # Partitioning because dates can be nil. In this case, it causes an error on sort.
          subforms = @record[field.name].partition{ |r| r[field.subform_sort_by].nil? }
          @record[field.name] = subforms.first + subforms.last.sort_by{|x| x[field.subform_sort_by]}.reverse
        end
      end
    end
  end

  def redirect_on_not_found
    respond_to do |format|
      format.html do
        flash[:error] = "#{model_class.name.underscore.capitalize.sub('_', ' ')} with the given id is not found"
        redirect_to :action => :index
        return
      end
    end
  end

  def retrieve_records_and_total(filter)
    records = []
    total_records = 0
    if params["selected_records"].present?
      selected_record_ids = params["selected_records"].split(',')
      if selected_record_ids.present?
        records = model_class.all(keys: selected_record_ids).all
        total_records = records.size
      end
    elsif params["page"] == "all"
      pagination_ops = {:page => 1, :per_page => 500}
      records = []
      begin
        search = model_class.list_records filter, order, pagination_ops, users_filter, params[:query], @match_criteria
        results = search.results
        records.concat(results)
        #Set again the values of the pagination variable because the method modified the variable.
        pagination_ops[:page] = results.next_page
        pagination_ops[:per_page] = 500
      end until results.next_page.nil?
      total_records = search.total
    else
      search = model_class.list_records filter, order, pagination, users_filter, params[:query], @match_criteria
      records = search.results
      total_records = search.total
    end
    [records, total_records]
  end

  #TODO - Primero - Refactor needed.  Determine more elegant way to load the lookups.
  def get_lookups
    @lookups = Lookup.all
  end

  def load_locations
    @locations = Location.all_names
  end

  # This is to ensure that if a hash has numeric keys, then the keys are sequential
  # This cleans up instances where multiple forms are added, then 1 or more forms in the middle are removed
  def reindex_hash(a_hash)
    a_hash.each do |key, value|
      if value.is_a?(Hash) and value.present?
        #if this is a hash with numeric keys, do the re-index, else keep searching
        if value.keys[0].is_number?
          new_hash = {}
          count = 0
          value.each do |k, v|
            new_hash[count.to_s] = v
            count += 1
          end
          value.replace(new_hash)
        else
          reindex_hash(value)
        end
      end
    end
  end

  def current_modules
    record_type = model_class.parent_form
    @current_modules ||= current_user.modules.select{|m| m.associated_record_types.include? record_type}
  end

  def is_admin
    @is_admin ||= @current_user.is_admin?
  end

  def is_manager
    @is_manager ||= @current_user.is_manager?
  end

  def is_cp
    @is_cp ||= @current_user.has_module?(PrimeroModule::CP)
  end

  def is_gbv
    @is_gbv ||= @current_user.has_module?(PrimeroModule::GBV)
  end

  def is_mrm
    @is_mrm ||= @current_user.has_module?(PrimeroModule::MRM)
  end

  def record_params
    param_root = model_class.name.underscore
    params[param_root] || {}
  end

  # All the stuff that isn't properties that should be allowed
  def extra_permitted_parameters
    ['base_revision', 'unique_identifier', 'upload_document', 'update_document', 'record_state']
  end

  def permitted_property_keys(record, user = current_user, read_only_user = false)
    record.permitted_property_names(user, read_only_user) + extra_permitted_parameters
  end

  # Filters out any unallowed parameters for a record and the current user
  def filter_params(record)
    permitted_keys = permitted_property_keys(record)
    record_params.select {|k,v| permitted_keys.include?(k) }
  end

  #TODO: This method will be very slow for very large exports: models.size > 1000.
  #      One such likely case will be the GBV IR export. We may need to either explicitly ignore it,
  #      pull out the recursion (this is there for nested forms, and it may be ok to grant access to the entire nest),
  #      or have a more efficient way of determining the `all_permitted_keys` set.
  def filter_permitted_export_properties(models, props, user = current_user, transitions = false)
    # this first condition is for the list view CSV export, which for some
    # reason is implemented with a completely different interface. TODO: don't
    # do that.
    # case_pdf, xls and selected_xls got his own logic to filter permitted properties.
    # No need to call extra logic.
    #Avoid call the filter readonly logic in the case of transitions (transfer and refereals).
    if props.include?(:fields) ||
       (!transitions && ["xls", "selected_xls", "case_pdf"].include?(params[:format]))
      props
    else
      read_only_user = false
      #Avoid call the filter readonly logic in the case of transitions (transfer and refereals).
      if !transitions && params[:format] == "csv"
        # For CSV filter the properties the readonly user can see.
        read_only_user = user.readonly?(model_class.name.underscore)
      end
      all_permitted_keys = models.inject([]) {|acc, m| acc | permitted_property_keys(m, user, read_only_user) }
      prop_selector = lambda do |ps|
        case ps
        when Hash
          ps.inject({}) {|acc, (k,v)| acc.merge( k => prop_selector.call(v) ) }
        when Array
          ps.select {|p| all_permitted_keys.include?(p.name) }
        else
          ps
        end
      end

      prop_selector.call(props)
    end
  end

  def record_short_id
    record_params.try(:fetch, :short_id, nil) || record_params.try(:fetch, :unique_identifier, nil).try(:last, 7)
  end

  def load_record
    if params[:id].present?
      @record = model_class.get(params[:id])
    end

    # Alias the record to a more specific name since the record controllers
    # already use it
    instance_variable_set("@#{model_class.name.underscore}", @record)
  end

  def load_consent
    if @record.present?
      @referral_consent = @record.given_consent(Transition::TYPE_REFERRAL)
      @transfer_consent = @record.given_consent(Transition::TYPE_TRANSFER)
    end
  end

  def exported_properties
    if params[:export_list_view].present? && params[:export_list_view] == "true"
      build_list_field_by_model(model_class)
    else
      model_class.properties
    end
  end

  private

  #Discard nil values and empty arrays.
  def format_json_response(record)
    record = record.as_couch_json.clone
    if params[:mobile].present?
      record.each do |field_key, value|
        if value.kind_of? Array
          if value.size == 0
            record.delete(field_key)
          elsif value.first.respond_to?(:each)
            value = value.map do |v|
              nested = v.clone
              v.each do |field_key, value|
                nested.delete(field_key) if !value.present?
              end
              nested
            end
            record[field_key] = value
          end
        end
      end
    end
    return record
  end

  def filter_custom_exports(properties_by_module)
    if params[:custom_exports].present?
      properties_by_module = properties_by_module.select{|key| params[:custom_exports][:module].include?(key)}

      if params[:custom_exports][:forms].present? || params[:custom_exports][:selected_subforms].present?
        properties_by_module = filter_by_subform(properties_by_module).deep_merge(filter_by_form(properties_by_module))
      elsif params[:custom_exports].present? && params[:custom_exports][:fields].present?
        #Filter the selected fields from the whole form section fields.
        properties_by_module.each do |pm, fs|
          filtered_forms = []
          fs.each do |fk, fields|
            selected_fields = []
            fields.each do |field|
              f_name, f_property = field[0], field[1]
              #Add selected fields.
              selected_fields << field if params[:custom_exports][:fields].include?(f_name)
              #If there is a subform in the section, filter the fields selected by the user
              #for the subform.
              if f_property.array && f_property.type.include?(CouchRest::Model::Embeddable)
                subform_props = f_property.type.properties.select do |property|
                  #Fields to be selected has the format: subform-field-name:field-name
                  params[:custom_exports][:fields].include?("#{f_name}:#{property.name}")
                end
                #Create the hash to hold the selected fields for the subform.
                selected_fields << [f_name, subform_props.map{|p| [p.name, p]}.to_h] if subform_props.present?
              end
            end
            filtered_forms << [fk, selected_fields.to_h]
          end
          properties_by_module[pm] = filtered_forms.to_h
        end
        #Find out duplicated fields assumed because they are shared fields.
        properties_by_module.each do |pm, form_sections|
          all_fields = []
          form_sections.each do |form_section_key, fields|
            filtered_fields = fields.map do |field_key, field|
              if all_fields.include?(field)
                #Field already seem, generate a key that will be wipe.
                element = [field_key, nil]
              else
                #First time seem the field, generate the key/value valid.
                element = [field_key, field]
              end
              all_fields << field
              element
            end
            form_sections[form_section_key] = filtered_fields.to_h.compact
          end
        end
        properties_by_module.compact
      end
    end
    properties_by_module
  end

  def filter_by_subform(properties)
    sub_props = {}
    if params[:custom_exports][:selected_subforms].present?
      properties.each do |pm, fs|
        sub_props[pm] = fs.map{|fk, fields| [fk, fields.select{|f| params[:custom_exports][:selected_subforms].include?(f)}]}.to_h.compact
      end
    end
    sub_props
  end

  def filter_by_form(properties)
    props = {}
    if params[:custom_exports][:forms].present?
      properties.each do |pm, fs|
        props[pm] = fs.select{|key| params[:custom_exports][:forms].include?(key)}
      end
    end
    props
  end

  #Filter out fields the current user is not allow to view.
  def filter_fields_read_only_users(form_sections, properties_by_module, current_user)
    if current_user.readonly?(model_class.name.underscore)
      #Filter showable properties for readonly users.
      properties_by_module.map do |pm, forms|
        forms = forms.map do |form, fields|
          #Find out the fields the user is able to view based on the form section.
          form_section_fields = form_sections[pm].select do |fs|
            fs.name == form
          end.map do |fs|
            fs.fields.map{|f| f.name if f.showable?}.compact
          end.flatten
          #Filter the properties based on the field on the form section.
          fields = fields.select{|f_name, f_value| form_section_fields.include?(f_name) }
          [form, fields]
        end
        [pm, forms.to_h.compact]
      end.to_h.compact
    else
      properties_by_module
    end
  end

  def create_or_update_record(id)
    @record = model_class.by_short_id(:key => record_short_id).first if record_params[:unique_identifier]

    if @record.nil?
      @record = model_class.new_with_user_name(current_user, record_params)
    else
      @record = update_record_from(id)
    end

    instance_variable_set("@#{model_class.name.underscore}", @record)
  end

  def update_record_from(id)
    authorize! :update, @record

    reindex_hash record_params
    update_record_with_attachments(@record)
  end

  def module_users(module_ids)
    @module_users = User.find_by_modules(module_ids).map(&:user_name).reject {|u| u == current_user.user_name}
  end

end
