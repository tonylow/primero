require 'spec_helper'

#TODO revisit when implement export.
# def inject_export_generator( fake_export_generator, tracing_request_data )
  # ExportGenerator.stub(:new).with(tracing_request_data).and_return( fake_export_generator )
# end
#
# def stub_out_export_generator tracing_request_data = []
  # inject_export_generator( stub_export_generator = stub(ExportGenerator) , tracing_request_data)
  # stub_export_generator.stub(:tracing_request_photos).and_return('')
  # stub_export_generator
# end

def stub_out_tracing_request_get(mock_tracing_request = double(TracingRequest))
  TracingRequest.stub(:get).and_return( mock_tracing_request )
  mock_tracing_request
end

describe TracingRequestsController do

  before :each do
    fake_admin_login
  end

  def mock_tracing_request(stubs={})
    @mock_tracing_request ||= mock_model(TracingRequest, stubs).as_null_object
  end

  def stub_form(stubs={})
    form = stub_model(FormSection) do |form|
      form.fields = [stub_model(Field)]
    end
  end

  it 'GET reindex' do
    TracingRequest.should_receive(:reindex!).and_return(nil)
    get :reindex
    response.should be_success
  end



  describe '#authorizations' do
    describe 'collection' do
      it "GET index" do
        @controller.current_ability.should_receive(:can?).with(:index, TracingRequest).and_return(false);
        controller.stub :get_form_sections
        get :index
        response.status.should == 403
      end

      it "GET search" do
        @controller.current_ability.should_receive(:can?).with(:index, TracingRequest).and_return(false);
        get :search
        response.status.should == 403
      end

      it "GET new" do
        @controller.current_ability.should_receive(:can?).with(:create, TracingRequest).and_return(false);
        controller.stub :get_form_sections
        get :new
        response.status.should == 403
      end

      it "POST create" do
        @controller.current_ability.should_receive(:can?).with(:create, TracingRequest).and_return(false);
        post :create
        response.status.should == 403
      end

    end

    describe 'member' do
      before :each do
        User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
        @tracing_request = TracingRequest.create('last_known_location' => "London", :short_id => 'short_id', :created_by => "uname")
        @tracing_request_arg = hash_including("_id" => @tracing_request.id)
      end

      it "GET show" do
        @controller.current_ability.should_receive(:can?).with(:read, @tracing_request_arg).and_return(false);
        controller.stub :get_form_sections
        get :show, :id => @tracing_request.id
        response.status.should == 403
      end

      it "PUT update" do
        @controller.current_ability.should_receive(:can?).with(:update, @tracing_request_arg).and_return(false);
        put :update, :id => @tracing_request.id
        response.status.should == 403
      end

      it "DELETE destroy" do
        @controller.current_ability.should_receive(:can?).with(:destroy, @tracing_request_arg).and_return(false);
        delete :destroy, :id => @tracing_request.id
        response.status.should == 403
      end
    end
  end

  describe "GET index" do

    shared_examples_for "viewing tracing requests by user with access to all data" do
      describe "when the signed in user has access all data" do
        before do
          fake_tracing_request_admin_login
          @options ||= {}
          @stubs ||= {}
        end

        it "should assign all tracing requests as @tracing_requests" do
          page = @options.delete(:page)
          per_page = @options.delete(:per_page)
          tracing_requests = [mock_tracing_request(@stubs)]
          @status ||= "all"
          tracing_requests.stub(:paginate).and_return(tracing_requests)
          TracingRequest.should_receive(:fetch_paginated).with(@options, page, per_page).and_return([1, tracing_requests])

          get :index, :status => @status
          assigns[:tracing_requests].should == tracing_requests
        end
      end
    end

    shared_examples_for "viewing tracing requests as a mrm worker" do
      describe "when the signed in user is a field worker" do
        before do
          @session = fake_tracing_request_worker_login
          @stubs ||= {}
          @options ||= {}
          @params ||= {}
        end

        it "should assign the tracing requests created by the user as @tracing_requests" do
          tracing_requests = [mock_tracing_request(@stubs)]
          page = @options.delete(:page)
          per_page = @options.delete(:per_page)
          @status ||= "all"
          tracing_requests.stub(:paginate).and_return(tracing_requests)
          TracingRequest.should_receive(:fetch_paginated).with(@options, page, per_page).and_return([1, tracing_requests])
          @params.merge!(:status => @status)
          get :index, @params
          assigns[:tracing_requests].should == tracing_requests
        end
      end
    end

    context "viewing all tracing requests" do
      before { @stubs = { :reunited? => false } }
      context "when status is passed for admin" do
        before { @status = "all"}
        before {@options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_valid_record_view_enquirer_name}}
        it_should_behave_like "viewing tracing requests by user with access to all data"
      end

      context "when status is passed for mrm worker" do
        before { @status = "all"}
        before {@options = {:startkey=>["all", "fakemrmworker"], :endkey=>["all","fakemrmworker", {}], :page=>1, :per_page=>20, :view_name=>:by_valid_record_view_with_created_by_created_at}}

        it_should_behave_like "viewing tracing requests as a mrm worker"
      end

      context "when status is not passed admin" do
        before {@options = {:startkey=>["all"], :endkey=>["all", {}], :page=>1, :per_page=>20, :view_name=>:by_valid_record_view_enquirer_name}}
        it_should_behave_like "viewing tracing requests by user with access to all data"
      end

      context "when status is not passed mrm worker" do
        before {@options = {:startkey=>["all", "fakemrmworker"], :endkey=>["all","fakemrmworker", {}], :page=>1, :per_page=>20, :view_name=>:by_valid_record_view_with_created_by_created_at}}
        it_should_behave_like "viewing tracing requests as a mrm worker"
      end

      context "when status is not passed mrm worker and order is name" do
        before {@options = {:startkey=>["all", "fakemrmworker"], :endkey=>["all","fakemrmworker", {}], :page=>1, :per_page=>20, :view_name=>:by_valid_record_view_with_created_by_name}}
        before {@params = {:order_by => 'name'}}
        it_should_behave_like "viewing tracing requests as a mrm worker"
      end

      context "when status is not passed mrm worker, order is created_at and page is 2" do
        before {@options = {:view_name=>:by_valid_record_view_with_created_by_created_at, :startkey=>["all", "fakemrmworker", {}], :endkey=>["all", "fakemrmworker"], :descending=>true, :page=>2, :per_page=>20}}
        before {@params = {:order_by => 'created_at', :page => 2}}
        it_should_behave_like "viewing tracing requests as a mrm worker"
      end
    end

    #TODO Commented in Incidents, do we still need?
    # context "viewing active tracing_requests" do
      # before do
        # @status = "active"
        # @stubs = {:reunited? => false}
      # end
      # context "admin" do
        # before {@options = {:startkey=>["active"], :endkey=>["active", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_name}}
        # it_should_behave_like "viewing tracing_requests by user with access to all data"
      # end
      # context "field worker" do
        # before {@options = {:startkey=>["active", "fakefieldworker"], :endkey=>["active", "fakefieldworker", {}], :page=>1, :per_page=>20, :view_name=>:by_all_view_with_created_by_created_at}}
        # it_should_behave_like "viewing tracing_requests as a field worker"
      # end
    # end

    #TODO revisit when implement export.
    # describe "export all to PDF/CSV/CPIMS/Photo Wall" do
      # before do
        # fake_field_admin_login
        # @params ||= {}
        # controller.stub :paginated_collection => [], :render => true
      # end
      # it "should flash notice when exporting no records" do
        # format = "cpims"
        # @params.merge!(:format => format)
        # get :index, @params
        # flash[:notice].should == "No Records Available!"
      # end
    # end
  end

  describe "GET show" do
    it 'does not assign tracing request name in page name' do
      tracing_request = build :tracing_request, :unique_identifier => "1234"
      controller.stub :render
      controller.stub :get_form_sections
      get :show, :id => tracing_request.id
      assigns[:page_name].should == "View Tracing Request 1234"
    end

    it "assigns the requested tracing request" do
      TracingRequest.stub(:get).with("37").and_return(mock_tracing_request)
      controller.stub :get_form_sections
      get :show, :id => "37"
      assigns[:tracing_request].should equal(mock_tracing_request)
    end

    it "retrieves the grouped forms that are permitted to this user and tracing request" do
      TracingRequest.stub(:get).with("37").and_return(mock_tracing_request)
      forms = [stub_form]
      grouped_forms = forms.group_by{|e| e.form_group_name}
      FormSection.should_receive(:get_permitted_form_sections).and_return(forms)
      FormSection.should_receive(:link_subforms)
      FormSection.should_receive(:group_forms).and_return(grouped_forms)
      get :show, :id => "37"
      assigns[:form_sections].should == grouped_forms
    end

    it "should flash an error and go to listing page if the resource is not found" do
      TracingRequest.stub(:get).with("invalid record").and_return(nil)
      controller.stub :get_form_sections
      get :show, :id=> "invalid record"
      flash[:error].should == "Tracing request with the given id is not found"
      response.should redirect_to(:action => :index)
    end

    it "should include duplicate records in the response" do
      TracingRequest.stub(:get).with("37").and_return(mock_tracing_request)
      duplicates = [TracingRequest.new(:name => "duplicated")]
      TracingRequest.should_receive(:duplicates_of).with("37").and_return(duplicates)
      controller.stub :get_form_sections
      get :show, :id => "37"
      assigns[:duplicates].should == duplicates
    end
  end

  describe "GET new" do
    it "assigns a new tracing request as @tracing_request" do
      TracingRequest.stub(:new).and_return(mock_tracing_request)
      controller.stub :get_form_sections
      get :new
      assigns[:tracing_request].should equal(mock_tracing_request)
    end

    it "retrieves the grouped forms that are permitted to this user and tracing request" do
      TracingRequest.stub(:get).with("37").and_return(mock_tracing_request)
      forms = [stub_form]
      grouped_forms = forms.group_by{|e| e.form_group_name}
      FormSection.should_receive(:get_permitted_form_sections).and_return(forms)
      FormSection.should_receive(:link_subforms)
      FormSection.should_receive(:group_forms).and_return(grouped_forms)
      get :new, :id => "37"
      assigns[:form_sections].should == grouped_forms
    end
  end

  describe "GET edit" do
    it "assigns the requested tracing request as @tracing_request" do
      TracingRequest.stub(:get).with("37").and_return(mock_tracing_request)
      controller.stub :get_form_sections
      get :edit, :id => "37"
      assigns[:tracing_request].should equal(mock_tracing_request)
    end

    it "retrieves the grouped forms that are permitted to this user and tracing request" do
      TracingRequest.stub(:get).with("37").and_return(mock_tracing_request)
      forms = [stub_form]
      grouped_forms = forms.group_by{|e| e.form_group_name}
      FormSection.should_receive(:get_permitted_form_sections).and_return(forms)
      FormSection.should_receive(:link_subforms)
      FormSection.should_receive(:group_forms).and_return(grouped_forms)
      get :edit, :id => "37"
      assigns[:form_sections].should == grouped_forms
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested tracing request" do
      TracingRequest.should_receive(:get).with("37").and_return(mock_tracing_request)
      mock_tracing_request.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the tracing requests list" do
      TracingRequest.stub(:get).and_return(mock_tracing_request(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(tracing_requests_url)
    end
  end

  #TODO Commented in Incidents, do we still need this?
  # describe "PUT update" do
    # it "should sanitize the parameters if the params are sent as string(params would be as a string hash when sent from mobile)" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = TracingRequest.create('last_known_location' => "London", :created_by => "uname", :created_at => "Jan 16 2010 14:05:32")
      # tracing_request.attributes = {'histories' => [] }
      # tracing_request.save!
#
      # Clock.stub(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))
      # histories = "[{\"datetime\":\"2013-02-01 04:49:29UTC\",\"user_name\":\"rapidftr\",\"changes\":{\"photo_keys\":{\"added\":[\"photo-671592136-2013-02-01T101929\"],\"deleted\":null}},\"user_organisation\":\"N\\/A\"}]"
      # put :update, :id => tracing_request.id,
           # :tracing_request => {
               # :last_known_location => "Manchester",
               # :histories => histories
           # }
#
     # assigns[:tracing_request]['histories'].should == JSON.parse(histories)
    # end

    # it "should update tracing_request on a field and photo update" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = TracingRequest.create('last_known_location' => "London", :created_by => "uname")
#
      # Clock.stub(:now).and_return(Time.parse("Jan 17 2010 14:05:32"))
      # put :update, :id => tracing_request.id,
        # :tracing_request => {
          # :last_known_location => "Manchester",
          # :photo => Rack::Test::UploadedFile.new(uploadable_photo_jeff) }
#
      # assigns[:tracing_request]['last_known_location'].should == "Manchester"
      # assigns[:tracing_request]['_attachments'].size.should == 2
      # updated_photo_key = assigns[:tracing_request]['_attachments'].keys.select {|key| key =~ /photo.*?-2010-01-17T140532/}.first
      # assigns[:tracing_request]['_attachments'][updated_photo_key]['data'].should_not be_blank
    # end

    # it "should update only non-photo fields when no photo update" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = TracingRequest.create('last_known_location' => "London", :created_by => "uname")
#
      # put :update, :id => tracing_request.id,
        # :tracing_request => {
          # :last_known_location => "Manchester",
          # :age => '7'}
#
      # assigns[:tracing_request]['last_known_location'].should == "Manchester"
      # assigns[:tracing_request]['age'].should == "7"
      # assigns[:tracing_request]['_attachments'].size.should == 1
    # end

    # it "should not update history on photo rotation" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.create('last_known_location' => "London", 'photo' => uploadable_photo_jeff, :created_by => "uname")
      # Child.get(tracing_request.id)["histories"].size.should be 1
#
      # expect{put(:update_photo, :id => tracing_request.id, :tracing_request => {:photo_orientation => "-180"})}.to_not change{Child.get(tracing_request.id)["histories"].size}
    # end

    # it "should allow a records ID to be specified to create a new record with a known id" do
      # new_uuid = UUIDTools::UUID.random_create()
      # put :update, :id => new_uuid.to_s,
        # :tracing_request => {
            # :id => new_uuid.to_s,
            # :_id => new_uuid.to_s,
            # :last_known_location => "London",
            # :age => "7"
        # }
      # Child.get(new_uuid.to_s)[:unique_identifier].should_not be_nil
    # end

    # it "should update flag (cast as boolean) and flag message" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.create('last_known_location' => "London", 'photo' => uploadable_photo, :created_by => "uname")
      # put :update, :id => tracing_request.id,
        # :tracing_request => {
          # :flag => true,
          # :flag_message => "Possible Duplicate"
        # }
      # assigns[:tracing_request]['flag'].should be_true
      # assigns[:tracing_request]['flag_message'].should == "Possible Duplicate"
    # end

    # it "should update history on flagging of record" do
      # current_time_in_utc = Time.parse("20 Jan 2010 17:10:32UTC")
      # current_time = Time.parse("20 Jan 2010 17:10:32")
      # Clock.stub(:now).and_return(current_time)
      # current_time.stub(:getutc).and_return current_time_in_utc
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.create('last_known_location' => "London", 'photo' => uploadable_photo_jeff, :created_by => "uname")
#
      # put :update, :id => tracing_request.id, :tracing_request => {:flag => true, :flag_message => "Test"}
#
      # history = Child.get(tracing_request.id)["histories"].first
      # history['changes'].should have_key('flag')
      # history['datetime'].should == "2010-01-20 17:10:32UTC"
    # end

    # it "should update the last_updated_by_full_name field with the logged in user full name" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.new_with_user_name(user, {:name => 'existing tracing_request'})
      # Child.stub(:get).with("123").and_return(tracing_request)
      # subject.should_receive('current_user_full_name').and_return('Bill Clinton')
#
      # put :update, :id => 123, :tracing_request => {:flag => true, :flag_message => "Test"}
#
      # tracing_request['last_updated_by_full_name'].should=='Bill Clinton'
    # end
#
    # it "should not set photo if photo is not passed" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.new_with_user_name(user, {:name => 'some name'})
      # params_tracing_request = {"name" => 'update'}
      # controller.stub(:current_user_name).and_return("user_name")
      # tracing_request.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, false, params_tracing_request)
      # Child.stub(:get).and_return(tracing_request)
      # put :update, :id => '1', :tracing_request => params_tracing_request
      # end
#
    # it "should delete the audio if checked delete_tracing_request_audio checkbox" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.new_with_user_name(user, {:name => 'some name'})
      # params_tracing_request = {"name" => 'update'}
      # controller.stub(:current_user_name).and_return("user_name")
      # tracing_request.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, true, params_tracing_request)
      # Child.stub(:get).and_return(tracing_request)
      # put :update, :id => '1', :tracing_request => params_tracing_request, :delete_tracing_request_audio => "1"
    # end
#
    # it "should redirect to redirect_url if it is present in params" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.new_with_user_name(user, {:name => 'some name'})
      # params_tracing_request = {"name" => 'update'}
      # controller.stub(:current_user_name).and_return("user_name")
      # tracing_request.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, false, params_tracing_request)
      # Child.stub(:get).and_return(tracing_request)
      # put :update, :id => '1', :tracing_request => params_tracing_request, :redirect_url => '/cases'
      # response.should redirect_to '/cases?follow=true'
    # end
#
    # it "should redirect to case page if redirect_url is not present in params" do
      # User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      # tracing_request = Child.new_with_user_name(user, {:name => 'some name'})
#
      # params_tracing_request = {"name" => 'update'}
      # controller.stub(:current_user_name).and_return("user_name")
      # tracing_request.should_receive(:update_properties_with_user_name).with("user_name", "", nil, nil, false, params_tracing_request)
      # Child.stub(:get).and_return(tracing_request)
      # put :update, :id => '1', :tracing_request => params_tracing_request
      # response.should redirect_to "/cases/#{tracing_request.id}?follow=true"
    # end

  # end

  describe "GET search" do
    it "should not render error by default" do
      get(:search, :format => 'html')
      assigns[:search].should be_nil
    end

    it "should render error if search is invalid" do
      get(:search, :format => 'html', :query => '2'*160)
      search = assigns[:search]
      search.errors.should_not be_empty
    end

    it "should stay in the page if search is invalid" do
      get(:search, :format => 'html', :query => '1'*160)
      response.should render_template("search")
    end

    it "performs a search using the parameters passed to it" do
      search = double("search", :query => 'the tracing_request name', :valid? => true, :page => 1)
      Search.stub(:new).and_return(search)

      fake_results = ["fake_tracing_request","fake_tracing_request"]
      fake_full_results =  [:fake_tracing_request,:fake_tracing_request, :fake_tracing_request, :fake_tracing_request]
      TracingRequest.should_receive(:search).with(search, 1).and_return([fake_results, fake_full_results])
      get(:search, :format => 'html', :query => 'the tracing_request name')
      assigns[:results].should == fake_results
    end

    describe "with no results" do
      before do
        get(:search, :query => 'blah')
      end

      it 'asks view to not show csv export link if there are no results' do
        assigns[:results].size.should == 0
      end

      it 'asks view to display a "No results found" message if there are no results' do
        assigns[:results].size.should == 0
      end

    end
  end

  describe "searching as mrm worker" do
    before :each do
      @session = fake_tracing_request_worker_login
    end
    it "should only list the tracing requests which the user has registered" do
      search = double("search", :query => 'some_name', :valid? => true, :page => 1)
      Search.stub(:new).and_return(search)

      fake_results = [:fake_tracing_request,:fake_tracing_request]
      fake_full_results =  [:fake_tracing_request,:fake_tracing_request, :fake_tracing_request, :fake_tracing_request]
      TracingRequest.should_receive(:search_by_created_user).with(search, @session.user_name, 1).and_return([fake_results, fake_full_results])

      get(:search, :query => 'some_name')
      assigns[:results].should == fake_results
    end
  end

  it 'should export tracing requests using #respond_to_export' do
    tracing_request1 = build :tracing_request
    tracing_request2 = build :tracing_request
    controller.stub :paginated_collection => [ tracing_request1, tracing_request2 ], :render => true
    controller.should_receive(:YAY).and_return(true)

    controller.should_receive(:respond_to_export) { |format, tracing_requests|
      format.mock { controller.send :YAY }
      tracing_requests.should == [ tracing_request1, tracing_request2 ]
    }

    get :index, :format => :mock
  end

  it 'should export tracing request using #respond_to_export' do
    tracing_request = build :tracing_request
    controller.stub :render => true
    controller.should_receive(:YAY).and_return(true)

    controller.should_receive(:respond_to_export) { |format, tracing_requests|
      format.mock { controller.send :YAY }
      tracing_requests.should == [ tracing_request ]
    }

    get :show, :id => tracing_request.id, :format => :mock
  end

  #TODO revisit when implement export.
  # describe '#respond_to_export' do
    # before :each do
      # @tracing_request1 = build :tracing_request
      # @tracing_request2 = build :tracing_request
      # controller.stub :paginated_collection => [ @tracing_request1, @tracing_request2 ], :render => true
    # end
#
    # it "should handle full PDF" do
      # Addons::PdfExportTask.any_instance.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
      # get :index, :format => :pdf
    # end
#
    # it "should handle Photowall PDF" do
      # Addons::PhotowallExportTask.any_instance.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
      # get :index, :format => :photowall
    # end
#
    # it "should handle CSV" do
      # Addons::CsvExportTask.any_instance.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
      # get :index, :format => :csv
    # end
#
    # it "should handle custom export addon" do
      # mock_addon = double()
      # mock_addon_class = double(:new => mock_addon, :id => "mock")
      # RapidftrAddon::ExportTask.stub :active => [ mock_addon_class ]
      # controller.stub(:authorize!)
      # mock_addon.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
      # get :index, :format => :mock
    # end
#
    # it "should encrypt result" do
      # Addons::CsvExportTask.any_instance.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
      # controller.should_receive(:export_filename).with([ @tracing_request1, @tracing_request2 ], Addons::CsvExportTask).and_return("test_filename")
      # controller.should_receive(:encrypt_exported_files).with('data', 'test_filename').and_return(true)
      # get :index, :format => :csv
    # end
#
    # it "should create a log_entry when record is exported" do
      # fake_login User.new(:user_name => 'fakeuser', :organisation => "STC", :role_ids => ["abcd"])
      # @controller.stub(:authorize!)
      # RapidftrAddonCpims::ExportTask.any_instance.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
#
      # LogEntry.should_receive(:create!).with :type => LogEntry::TYPE[:cpims], :user_name => "fakeuser", :organisation => "STC", :tracing_request_ids => [@tracing_request1.id, @tracing_request2.id]
#
      # get :index, :format => :cpims
    # end
#
    # it "should generate filename based on tracing_request ID and addon ID when there is only one tracing_request" do
      # @tracing_request1.stub :short_id => 'test_short_id'
      # controller.send(:export_filename, [ @tracing_request1 ], Addons::PhotowallExportTask).should == "test_short_id_photowall.zip"
    # end
#
    # it "should generate filename based on username and addon ID when there are multiple tracing_requests" do
      # controller.stub :current_user_name => 'test_user'
      # controller.send(:export_filename, [ @tracing_request1, @tracing_request2 ], Addons::PdfExportTask).should == "test_user_pdf.zip"
    # end
#
    # it "should handle CSV" do
      # Addons::CsvExportTask.any_instance.should_receive(:export).with([ @tracing_request1, @tracing_request2 ]).and_return('data')
      # get :index, :format => :csv
    # end
#
  # end

  # describe "PUT select_primary_photo" do
    # before :each do
      # @tracing_request = stub_model(Child, :id => "id")
      # @photo_key = "key"
      # @tracing_request.stub(:primary_photo_id=)
      # @tracing_request.stub(:save)
      # Child.stub(:get).with("id").and_return @tracing_request
    # end
#
    # it "set the primary photo on the tracing_request and save" do
      # @tracing_request.should_receive(:primary_photo_id=).with(@photo_key)
      # @tracing_request.should_receive(:save)
#
      # put :select_primary_photo, :tracing_request_id => @tracing_request.id, :photo_id => @photo_key
    # end
#
    # it "should return success" do
      # put :select_primary_photo, :tracing_request_id => @tracing_request.id, :photo_id => @photo_key
#
      # response.should be_success
    # end
#
    # context "when setting new primary photo id errors" do
      # before :each do
        # @tracing_request.stub(:primary_photo_id=).and_raise("error")
      # end
#
      # it "should return error" do
        # put :select_primary_photo, :tracing_request_id => @tracing_request.id, :photo_id => @photo_key
#
        # response.should be_error
      # end
    # end
  # end

  #TODO Commented in Incidents, do we still need this?
  # TODO: Bug - JIRA Ticket: https://quoinjira.atlassian.net/browse/PRIMERO-136
  #
  # I switch between the latest and tag 1.0.0.1 to find out what is causing the issue.
  # In the older tag, the add_to_history method in the records_helper.rb is not being call where in the latest it is.
  # The latest is not being sent the creator and created_at information. This is not an issue on the
  # front-end, but only in the rspec test.
  #
  # describe "PUT create" do
  #   it "should add the full user_name of the user who created the Child record" do
  #     Child.should_receive('new_with_user_name').and_return(tracing_request = Child.new)
  #     controller.should_receive('current_user_full_name').and_return('Bill Clinton')
  #     put :create, :tracing_request => {:name => 'Test Child' }
  #     tracing_request['created_by_full_name'].should=='Bill Clinton'
  #   end
  # end

  # describe "sync_unverified" do
    # before :each do
      # @user = build :user, :verified => false, :role_ids => []
      # fake_login @user
    # end
#
    # it "should mark all tracing_requests created as verified/unverifid based on the user" do
      # @user.verified = true
      # Child.should_receive(:new_with_user_name).with(@user, {"name" => "timmy", "verified" => @user.verified?}).and_return(tracing_request = Child.new)
      # tracing_request.should_receive(:save).and_return true
#
      # post :sync_unverified, {:tracing_request => {:name => "timmy"}, :format => :json}
#
      # @user.verified = true
    # end
#
    # it "should set the created_by name to that of the user matching the params" do
      # Child.should_receive(:new_with_user_name).and_return(tracing_request = Child.new)
      # tracing_request.should_receive(:save).and_return true
#
      # post :sync_unverified, {:tracing_request => {:name => "timmy"}, :format => :json}
#
      # tracing_request['created_by_full_name'].should eq @user.full_name
    # end
#
    # it "should update the tracing_request instead of creating new tracing_request everytime" do
      # tracing_request = Child.new
      # view = double(CouchRest::Model::Designs::View)
      # Child.should_receive(:by_short_id).with(:key => '1234567').and_return(view)
      # view.should_receive(:first).and_return(tracing_request)
      # controller.should_receive(:update_tracing_request_from).and_return(tracing_request)
      # tracing_request.should_receive(:save).and_return true
#
      # post :sync_unverified, {:tracing_request => {:name => "timmy", :unique_identifier => '12345671234567'}, :format => :json}
#
      # tracing_request['created_by_full_name'].should eq @user.full_name
    # end
  # end

  describe "POST create" do
    it "should update the tracing request record instead of creating if record already exists" do
      User.stub(:find_by_user_name).with("uname").and_return(user = double('user', :user_name => 'uname', :organisation => 'org'))
      tracing_request = TracingRequest.new_with_user_name(user, {:name => 'old name'})
      tracing_request.save
      fake_admin_login
      controller.stub(:authorize!)
      post :create, :tracing_request => {:unique_identifier => tracing_request.unique_identifier, :name => 'new name'}
      updated_tracing_request = TracingRequest.by_short_id(:key => tracing_request.short_id)
      updated_tracing_request.all.size.should == 1
      updated_tracing_request.first.name.should == 'new name'
    end
  end

  describe "reindex_params_subforms" do

    it "should correct indexing for nested subforms" do
      params = {
        "tracing_request"=> {
          "name"=>"",
         "top_1"=>"This is a top value",
          "nested_form_section" => {
            "0"=>{"nested_1"=>"Keep", "nested_2"=>"Keep", "nested_3"=>"Keep"},
           "2"=>{"nested_1"=>"Drop", "nested_2"=>"Drop", "nested_3"=>"Drop"}},
          "fathers_name"=>""}}

      controller.reindex_hash params['tracing_request']
      expected_subform = params["tracing_request"]["nested_form_section"]["1"]

      expect(expected_subform.present?).to be_true
      expect(expected_subform).to eq({"nested_1"=>"Drop", "nested_2"=>"Drop", "nested_3"=>"Drop"})
    end

  end

end
