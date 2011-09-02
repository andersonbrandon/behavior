require 'active_support'
module Behavior
  def self.included(base)
    base.class_eval do
      def config
        Behavior::Base.new
      end      
      helper_method :config if respond_to?(:helper_method)
    end
  end
  
  class << self
    def config
      Behavior::Base.new
    end
  end
  
  class Base
    def meta
      HashWithIndifferentAccess.new(YAML.load_file(Behavior::Settings.config_file))
    end
    
    def config_name
      Behavior::Settings.config_name
    end
    
    def [](key)
      out = begin
        BehaviorConfig.find_by_key_and_config_name(key.to_s, config_name).value
      rescue NoMethodError
        meta[key][:default]
      end
      case meta[key][:type]
      when 'integer'
        out.to_i
      when 'decimal'
        BigDecimal.new(out.to_s)
      else
        out
      end
    end
    
    def all
      meta.keys
    end
    
    def update(attrs = {})
      attrs.each do |key,value|
        result = BehaviorConfig.find_or_create_by_key_and_config_name(key.to_s, config_name)
        result.update_attribute(:value, value) if result
      end
    end
  end
  
  class Settings
    class << self
      def config_name
        lambda { params[:config] || 'default' }.call
      end
      
      def config_file
        filename = "#{Rails.root}/config/behaviors/#{config_name}.yml"
        File.exists?(filename) ? filename : "#{Rails.root}/config/behaviors/default.yml"
        # @config_file ||= "#{Rails.root}/config/behaviors/default.yml"
      end
      
      def config_file=(file)
        @config_file = file
      end
      
      def layout
        @layout ||= 'admin'
      end
      
      def layout=(layout_choice)
        @layout = layout_choice
      end
      
      def before_filters
        @before_filters ||= []
      end
      
      def before_filters=(filters)
        @before_filters ||= filters
      end
    end
  end
end

ActionController::Base.send(:include, Behavior)