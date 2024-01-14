require 'rails_helper'


RSpec.describe Recipe, :type => :model do
    it { is_expected.to validate_presence_of(:name)}
    it { is_expected.to validate_length_of(:name)}
    
    

end