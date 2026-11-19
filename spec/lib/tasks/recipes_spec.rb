# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'recipes:get_json_schema' do # rubocop:disable RSpec/DescribeClass
  let(:url) { 'https://example.com/recipe' }
  let(:task) { Rake::Task['recipes:get_json_schema'] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?('recipes:get_json_schema')
    task.reenable
    stub_request(:get, url).to_return(body: <<~HTML)
      <script type="application/ld+json">
        {"@graph":[{"@type":"Recipe","name":"Cake","recipeIngredient":["Flour"],"extra":"ignored"}]}
      </script>
    HTML
  end

  it 'prints the selected JSON-LD fields independently of host importer selection' do
    expect { task.invoke(url) }.to output(
      "#{JSON.pretty_generate('name' => 'Cake', 'recipeIngredient' => ['Flour'])}\n"
    ).to_stdout
  end
end
