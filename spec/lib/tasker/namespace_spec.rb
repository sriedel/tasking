require 'spec_helper'

describe Tasker::Namespace do
  describe "a new namespace" do
    subject { Tasker::Namespace.new( "foo" ) }

    its( :tasks ) { should == [] }
  end
end
