require 'active_record'
require 'acts_as_tree/class_methods'

ActiveRecord::Base.send :extend, SleepingKingStudios::ActsAsTree::ClassMethods
