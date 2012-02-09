require 'spec_helper'
require 'acts_as_tree'

# silence ActiveRecord schema statements
SleepingKingStudios::ActsAsTree::Logger = $stdout
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :type, :string
      t.column :name, :string
      t.column :parent_id, :integer
    end # create_table
  end # Schema.define
end # function setup_db

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end # each
end # function teardown_db

class Mixin < ActiveRecord::Base; end

class TreeMixin < Mixin 
  acts_as_tree :foreign_key => "parent_id", :order => "id"
end # class TreeMixin

class DurableTreeMixin < Mixin
  acts_as_tree :foreign_key => "parent_id", :order => "id", :dependent => nil
end # class TreeMixin

class TreeMixinWithoutOrder < Mixin
  acts_as_tree :foreign_key => "parent_id"
end # class TreeMixinWithoutOrder

class RecursivelyCascadedTreeMixin < Mixin
  acts_as_tree :foreign_key => "parent_id"
  has_one :first_child, :class_name => 'RecursivelyCascadedTreeMixin', :foreign_key => :parent_id
end # class RecursivelyCascadedTreeMixin

describe SleepingKingStudios::ActsAsTree do
  include SleepingKingStudios::ActsAsTree
  
  before :each do setup_db end
  after :each do teardown_db end
  
  it { ActiveRecord::Base.should have_method :acts_as_tree }
  
  context "(initialized)" do
    let!(:root0) { TreeMixin.create! }
    let!(:root0_child0) { TreeMixin.create! :parent_id => root0.id }
    let!(:root0_child0_child0) { TreeMixin.create! :parent_id => root0_child0.id }
    let!(:root0_child1) { TreeMixin.create! :parent_id => root0.id }
    let!(:root1) { TreeMixin.create! }
    let!(:root2) { TreeMixin.create! }
    
    describe "children association" do
      it { root0.children.should == [root0_child0, root0_child1] }
      it { root0_child0.children.should == [root0_child0_child0] }
      it { root0_child0_child0.children.should == [] }
      it { root0_child1.children.should == [] }
      it { root1.children.should == [] }
      it { root2.children.should == [] }
    end # describe children
    
    describe "parent association" do
      it { root0.parent.should be nil }
      it { root0_child0.parent.should == root0 }
      it { root0_child0_child0.parent.should == root0_child0 }
      it { root0_child1.parent.should == root0 }
      it { root1.parent.should == nil }
      it { root2.parent.should == nil }
    end # describe parent
    
    describe "delete dependent records" do
      it { TreeMixin.count.should be 6 }
      
      context do
        before :each do root0.destroy end
        
        it { TreeMixin.count.should be 2 }
        
        context do
          before :each do root1.destroy; root2.destroy; end
          
          it { TreeMixin.count.should be 0 }
        end # anonymous context
      end # anonymous context
      
      describe "unless :dependent is overriden" do
        let!(:durable_root) { DurableTreeMixin.create! }
        let!(:durable_child0) { DurableTreeMixin.create! :parent_id => durable_root }
        let!(:durable_child1) { DurableTreeMixin.create! :parent_id => durable_root }
        
        it { DurableTreeMixin.count.should be 3 }
        
        context do
          before :each do durable_root.destroy end
          
          it { DurableTreeMixin.count.should be 2 }
        end # anonymous context
      end # describe unless :dependent is overriden
    end # describe delete dependent records
    
    describe "inserting records" do
      let!(:root0_child2) { root0.children.create }
      
      it { root0_child2.should be_a TreeMixin }
      it { root0_child2.parent.should == root0 }
      
      it { root0.children.count.should == 3 }
      it { root0.children.should include root0_child0 }
      it { root0.children.should include root0_child1 }
      it { root0.children.should include root0_child2 }
    end # describe inserting records
    
    describe "root class method" do
      it { TreeMixin.root.should == root0 }
    end # describe root class method
    
    describe "roots class method" do
      it { TreeMixin.roots.should == [root0, root1, root2] }
    end # describe roots class method
    
    describe "ancestors method" do
      it { root0.ancestors.should == [] }
      it { root0_child0.ancestors.should == [root0] }
      it { root0_child0_child0.ancestors.should == [root0_child0, root0] }
      it { root0_child1.ancestors.should == [root0] }
      it { root1.ancestors.should == [] }
      it { root2.ancestors.should == [] }
    end # describe ancestors method
    
    describe "root method" do
      it { root0.root.should == root0 }
      it { root0_child0.root.should == root0 }
      it { root0_child0_child0.root.should == root0 }
      it { root0_child1.root.should == root0 }
      it { root1.root.should == root1 }
      it { root2.root.should == root2 }
    end # describe root method
    
    describe "self and siblings method" do
      it { root0.self_and_siblings.should == [root0, root1, root2] }
      it { root0_child0.self_and_siblings.should == [root0_child0, root0_child1] }
      it { root0_child0_child0.self_and_siblings.should == [root0_child0_child0] }
      it { root0_child1.self_and_siblings.should == [root0_child0, root0_child1] }
      it { root1.self_and_siblings.should == [root0, root1, root2] }
      it { root2.self_and_siblings.should == [root0, root1, root2] }
    end # describe self and siblings method
    
    describe "siblings method" do
      it { root0.siblings.should == [root1, root2] }
      it { root0_child0.siblings.should == [root0_child1] }
      it { root0_child0_child0.siblings.should == [] }
      it { root0_child1.siblings.should == [root0_child0] }
      it { root1.siblings.should == [root0, root2] }
      it { root2.siblings.should == [root0, root1] }
    end # describe sibling method
    
    describe "with eager loading" do
      describe "associations" do
        let!(:roots) { TreeMixin.find(:all,
          :include => :children,
          :conditions => "mixins.parent_id IS NULL",
          :order => "mixins.id") } # end let :roots
        
        # quick sanity check on custom execute_queries matcher
        it { lambda { TreeMixin.find(:all) }.should execute_queries 1 }
        
        it { roots.should == [root0, root1, root2] }
        it { expect {
          roots[0].children.size.should == 2
          roots[1].children.size.should == 0
          roots[2].children.size.should == 0
        }.not_to execute_queries }
        
        describe "recursive cascading" do
          let!(:recursive0) { RecursivelyCascadedTreeMixin.create! }
          let!(:recursive1) { RecursivelyCascadedTreeMixin.create! :parent_id => recursive0.id }
          let!(:recursive2) { RecursivelyCascadedTreeMixin.create! :parent_id => recursive1.id }
          let!(:recursive3) { RecursivelyCascadedTreeMixin.create! :parent_id => recursive2.id }
          
          describe "has_many" do
            let!(:recursive_root) {
              RecursivelyCascadedTreeMixin.find(:first,
                :include => { :children => { :children => :children } },
                :order => 'mixins.id') }
            
            it { expect {
              recursive_root.children.first.children.first.children.first.should == recursive3
            }.not_to execute_queries }
          end # describe has_many
          
          describe "has_one" do
            let!(:recursive_root) {
              RecursivelyCascadedTreeMixin.find(:first,
                :include => { :first_child => { :first_child => :first_child } },
                :order => 'mixins.id') }
            
            it { expect {
              recursive_root.first_child.first_child.first_child.should == recursive3
            }.not_to execute_queries }
          end # describe has_one
          
          describe "belongs_to" do
            let!(:recursive_leaf) {
              RecursivelyCascadedTreeMixin.find(:first,
                :include => { :parent => { :parent => :parent } },
                :order => 'mixins.id DESC') }
            
            it { expect {
              recursive_leaf.parent.parent.parent.should == recursive0
            }.not_to execute_queries }
          end # describe belongs_to
        end # describe recursive cascading
      end # describe associations
    end # describe with eager loading

    describe "unordered tree" do
      let!(:unordered0) { TreeMixinWithoutOrder.create! }
      let!(:unordered1) { TreeMixinWithoutOrder.create! }
      
      describe "root class method" do
        it { [unordered0, unordered1].should include TreeMixinWithoutOrder.root }
      end # describe root class method
      
      describe "roots class method" do
        it { (TreeMixinWithoutOrder.roots - [unordered0, unordered1]).should be_empty }
      end # describe roots class method
    end # describe unordered tree
  end # context initialized
end # describe SleepingKingStudios::ActsAsTree
