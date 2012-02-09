# lib/acts_as_tree/class_methods.rb

require 'acts_as_tree/instance_methods'

module SleepingKingStudios
  module ActsAsTree
    module ClassMethods
      def acts_as_tree(options = {})
        configuration = {
          counter_cache: nil,
          dependent: :destroy,
          foreign_key: "parent_id",
          order: nil,
        } # end Hash configuration
        configuration.update(options) if options.is_a?(Hash)
        
        belongs_to :parent,
          :class_name => self.name,
          :foreign_key => configuration[:foreign_key],
          :counter_cache => configuration[:counter_cache]
        has_many :children,
          :class_name => self.name,
          :foreign_key => configuration[:foreign_key],
          :order => configuration[:order],
          :dependent => configuration[:dependent]
        
        self.class_eval <<-EOV
          include SleepingKingStudios::ActsAsTree::InstanceMethods
          
          # Find all root nodes.
          def self.roots
            find(:all,
              :conditions => "#{configuration[:foreign_key]} IS NULL",
              :order => #{configuration[:order].nil? ? "nil" : %Q{"#{configuration[:order]}"}}
            ) # end find
          end # class method self.roots
          
          # Find the first root node. Included for compatibility.
          def self.root
            find(:first,
              :conditions => "#{configuration[:foreign_key]} IS NULL",
              :order => #{configuration[:order].nil? ? "nil" : %Q{"#{configuration[:order]}"}}
            ) # end find
          end # class method self.root
        EOV
      end # class method acts_as_tree
    end # module ClassMethods
  end # module ActsAsTree
end # module SleepingKingStudios
