require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Diff do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ diff }).should.be.instance_of Command::Diff
      end
    end
  end
end

