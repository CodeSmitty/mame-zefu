# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'recipe tasks' do # rubocop:disable RSpec/DescribeClass
  describe 'recipe archive tasks' do
    include ActiveSupport::Testing::TimeHelpers

    let(:user) { create(:user, email: 'admin@example.com') }

    before do
      Rails.application.load_tasks unless Rake::Task.task_defined?('recipes:export')
      user
    end

    describe 'recipes:export' do
      let(:task) { Rake::Task['recipes:export'] }
      let(:archive) { instance_double(Recipes::Archive) }
      let(:archive_file) { instance_double(Tempfile, path: '/tmp/recipe-archive.zip') }
      let(:filename) { Rails.root.join("Recipes_#{Time.current.strftime('%Y%m%d_%H%M%S')}.zip") }

      before do
        task.reenable
        allow(Recipes::Archive).to receive(:new).with(user).and_return(archive)
        allow(archive).to receive(:generate).and_return(archive_file)
        allow(FileUtils).to receive(:mv)
      end

      it 'moves the generated archive to the timestamped filename' do
        travel_to Time.zone.local(2026, 1, 2, 3, 4, 5) do
          expect { task.invoke }.to output("Exporting recipes to #{filename}...\n").to_stdout
          expect(FileUtils).to have_received(:mv).with(archive_file.path, filename)
        end
      end
    end

    shared_examples 'an archive import task' do
      let(:task) { Rake::Task[task_name] }
      let(:archive) { instance_double(archive_class) }
      let(:file) { Tempfile.new(['recipe-import', '.zip']) }

      before do
        task.reenable
        file.write('archive contents')
        file.flush
        allow(archive_class).to receive(:new).with(user).and_return(archive)
        allow(archive).to receive(:restore).and_return({ created: 3, skipped: 2 })
      end

      after { file.close! }

      it 'restores the supplied archive and reports the result' do
        expect { task.invoke(file.path) }.to output(
          "Importing recipes from #{file.path}...\nImported 3 recipes (2 skipped)\n"
        ).to_stdout
        expect(archive).to have_received(:restore).with(have_attributes(path: file.path))
      end
    end

    describe 'recipes:import' do
      let(:task_name) { 'recipes:import' }
      let(:archive_class) { Recipes::Archive }

      it_behaves_like 'an archive import task'
    end

    describe 'recipes:import:recipe_keeper' do
      let(:task_name) { 'recipes:import:recipe_keeper' }
      let(:archive_class) { Recipes::Archive::RecipeKeeper }

      it_behaves_like 'an archive import task'
    end
  end

  describe 'recipes:get_json_schema' do
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
end
