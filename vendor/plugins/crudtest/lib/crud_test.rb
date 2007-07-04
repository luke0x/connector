module CRUDTest
  def self.included(base)
    base.extend ClassMethods
    base.class_eval <<-EOS
      if method_defined?(:setup)
        alias :orig_setup :setup
      end

      if self.name.to_s =~ /^(.*)Test$/
        write_inheritable_attribute :crud_model, $1
      end
      write_inheritable_attribute :crud_data,      {}
      write_inheritable_attribute :crud_fields,    []
      write_inheritable_attribute :crud_unique,    []
      write_inheritable_attribute :crud_protected, []

      include CRUDTest::InstanceMethods

      def self.method_added(amethod)
        case amethod.to_s
        when 'setup'
          unless method_defined?(:pre_test)
            alias_method :pre_test, :setup
            define_method(:setup) do
              setup_crud_module
            end
          end
        end
      end
    EOS
  end
  
  module ClassMethods    
    def crud_model(model)
      write_inheritable_attribute :crud_model, model
    end

    def crud_data(hash)
      write_inheritable_attribute :crud_data, hash
    end
    
    def crud_required(*array)
      write_inheritable_attribute :crud_fields, array
    end
    
    def crud_unique(*array)
      write_inheritable_attribute :crud_unique, array
    end

    def crud_protected(*array)
      write_inheritable_attribute :crud_protected, array
    end
  end
  
  module InstanceMethods
    def setup_crud_module
      orig_setup if self.class.method_defined?(:orig_setup)
      pre_test   if self.class.method_defined?(:pre_test)
      
      @test_data        = (self.class.read_inheritable_attribute(:crud_data)).dup
      @model            = (self.class.read_inheritable_attribute(:crud_model)).constantize
      @required_fields  = (self.class.read_inheritable_attribute(:crud_fields)).dup
      @unique_fields    = (self.class.read_inheritable_attribute(:crud_unique)).dup
      @protected_fields = (self.class.read_inheritable_attribute(:crud_protected)).dup
    end
    alias :setup :setup_crud_module
    
    def crud_data
      @test_data
    end
    
    def test_crud
      run_crud_tests
    end
    
    def run_crud_tests
      # We'll say @test_data is required to run_crud_tests
      assert @test_data, 'You need to define crud_data to use run_crud_tests.'
    
      # test basic creation
      assert_create('Basic Creation Failed').destroy
      assert_destroy('Destruction Failed')
    
      if @required_fields
        # test failed creation when missing required fields
        @required_fields.each do |field|
          assert_no_create_without field, "Created without #{field}."
        end
    
        # test that we can create with all required fields present
        # but the unrequired fields missing
        (@test_data.keys - @required_fields).each do |field|
          item = assert_create_without field, "Cannot create without #{field}."
        end
      end
      
      unless @unique_fields.empty?
        # If there are unique fields, should not be able to create a duplicate
        # record
        item = assert_create
        assert_no_create "Created two identical objects"
        item.destroy
        
        # Make assertions about case insensitivity
        @unique_fields.each do |field|
          @test_data[field].downcase!
          item = assert_create
          @test_data[field].upcase!
          assert_no_create "Uniqueness constraint was not case insensitive"
          item.destroy
        end
      end
    end
    
    def assert_create(msg='', data = nil)
      item = @model.new(data || @test_data)
      if @protected_fields
        @protected_fields.each do |f|
          item.send "#{f}=", @test_data[f]
        end
      end
      assert item.save, msg
      item
    end
  
    def assert_no_create(msg='')
      item = @model.new @test_data
      if @protected_fields
        @protected_fields.each do |f|
          item.send "#{f}=", @test_data[f]
        end
      end
      assert !item.save, msg
    end
  
    def assert_create_without(fields, msg='')
      if Array === fields
        data = @test_data.reject { |k,v| fields.include? k }
      else
        data = @test_data.reject { |k,v| k == fields }
      end
      item = assert_create msg, data
      item.destroy
    end
  
    def assert_no_create_without(fields, msg='')
      if Array === fields
        data = @test_data.reject { |k,v| fields.include? k }
      else
        data = @test_data.reject { |k,v| k == fields }
      end
      item = @model.new data
      assert !item.save, msg
    end
  
    def assert_destroy(msg = '')
      item = assert_create
      item.destroy
      assert !@model.find(:first, :conditions => ["#{@model.primary_key}='#{item.id}'"]), msg
    end
  end
end
