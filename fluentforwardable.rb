#from Bryan Helmkamp
#http://www.brynary.com/2007/4/8/fluent-interface-for-ruby-delegation

require "forwardable"

module FluentForwardable
  class FluentForwarder
    def initialize(klass, readers, writers, *methods)
      @klass    = klass
      @readers  = readers
      @writers  = writers
      @methods  = methods
    end
    
    def with_prefix(prefix)
      @prefix = prefix
      self
    end
    
    def as(custom_name)
      raise "Cannot delegate multiple methods with a custom name" if @methods.size > 1
      @custom_name = custom_name
      self
    end
    
    def to(receiver)
      for method in @methods
        new_method = new_method_name(method)
        if @readers
          @klass.class_eval { def_delegator receiver, method, new_method }
        end
        if @writers
          @klass.class_eval { def_delegator receiver, :"#{method}=", :"#{new_method}=" }
        end
      end
    end
    
  protected
    
    def new_method_name(method)
      return @custom_name if @custom_name
      @prefix ? "#{@prefix}_#{method}" : method
    end
  end
  
  def delegate_reader(*methods)
    FluentForwarder.new(self, true, false, *methods)
  end
  alias_method :delegate_readers, :delegate_reader
  
  def delegate_writer(*methods)
    FluentForwarder.new(self, false, true, *methods)
  end
  alias_method :delegate_writers, :delegate_writer
  
  def delegate_accessor(*methods)
    FluentForwarder.new(self, true, true, *methods)
  end
  alias_method :delegate_accessors, :delegate_accessor
end

Forwardable.send :include, FluentForwardable


#examples
#   extend Forwardable
# 
#   delegate_reader(:line_items).to(:line_item_list)
#   delegate_reader(:total_value).as(:subtotal).to(:line_item_list)
#   delegate_writers(:first_name, :last_name).to(:owner)
#   delegate_accessors(:city, :state, :zip).with_prefix(:shipping).to(:shipping_address)


