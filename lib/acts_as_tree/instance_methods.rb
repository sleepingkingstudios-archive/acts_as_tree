# lib/acts_as_tree/instance_methods.rb

module SleepingKingStudios
  module ActsAsTree
    module InstanceMethods
      # Returns list of ancestors, starting from parent until root.
      #
      #   subchild1.ancestors # => [child1, root]
      def ancestors
        node, nodes = self, []
        nodes << node = node.parent while node.parent
        nodes
      end # method ancestors
      
      # Returns the root node of the tree.
      def root
        node = self
        node = node.parent while node.parent
        node
      end # method root
      
      # Returns all siblings of the current node.
      #
      #   subchild1.siblings # => [subchild2]
      def siblings
        self_and_siblings - [self]
      end # method siblings
      
      # Returns all siblings and a reference to the current node.
      #
      #   subchild1.self_and_siblings # => [subchild1, subchild2]
      def self_and_siblings
        parent ? parent.children : self.class.roots
      end # method self_and_siblings
    end # module InstanceMethods
  end # module ActsAsTree
end # module SleepingKingStudios