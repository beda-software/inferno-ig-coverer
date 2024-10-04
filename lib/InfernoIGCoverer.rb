# frozen_string_literal: true

require 'zlib'
require 'rubygems/package'
require 'fhir_models'

require_relative 'InfernoIGCoverer/version'
require_relative 'InfernoIGCoverer/generator/ig_loader'
require_relative 'InfernoIGCoverer/generator/ig_metadata_extractor'
require_relative 'InfernoIGCoverer/generator/extension'

module InfernoIGCoverer
  class Generator
    def self.generate(folder_path, output_path)
      ig_packages = Dir.glob(File.join(Dir.pwd, folder_path, '*.tgz'))

      ig_packages.each do |ig_package|
        new(ig_package).generate(folder_path, output_path)
      end
    end

    attr_accessor :ig_resources, :ig_metadata, :ig_file_name

    def initialize(ig_file_name)
      self.ig_file_name = ig_file_name
    end

    def generate(folder_path, output_path)
      puts "Generating tests for IG #{File.basename(ig_file_name)}"
      load_ig_package(folder_path)
      extract_metadata(output_path)
      # generate_search_tests
      # generate_read_tests
      # generate_provenance_revinclude_search_tests
      # generate_validation_tests
      # generate_must_support_tests
      # generate_reference_resolution_tests
      # generate_groups
      # generate_suites
      # use_tests
    end

    def extract_metadata(output_path)
      self.ig_metadata = IGMetadataExtractor.new(ig_resources).extract

      base_output_dir = base_output_dir(output_path)

      FileUtils.mkdir_p(base_output_dir)
      File.open(File.join(base_output_dir, 'metadata.yml'), 'w') do |file|
        file.write(YAML.dump(ig_metadata.to_hash))
      end
    end

    def base_output_dir(output_path)
      File.join(Dir.pwd, output_path, ig_metadata.ig_version)
    end

    def load_ig_package(folder_path)
      # FHIR.logger = Logger.new('/dev/null')
      self.ig_resources = IGLoader.new(ig_file_name, folder_path).load
    end

    def generate_reference_resolution_tests
      ReferenceResolutionTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_must_support_tests
      MustSupportTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_validation_tests
      ValidationTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_read_tests
      ReadTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_search_tests
      SearchTestGenerator.generate(ig_metadata, base_output_dir)
      generate_multiple_or_search_tests
      generate_multiple_and_search_tests
      generate_chain_search_tests
      generate_special_identifier_search_tests
      generate_special_identifiers_chain_search_tests
    end

    def generate_provenance_revinclude_search_tests
      ProvenanceRevincludeSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_multiple_or_search_tests
      MultipleOrSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_multiple_and_search_tests
      MultipleAndSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_chain_search_tests
      ChainSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_special_identifier_search_tests
      SpecialIdentifierSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_special_identifiers_chain_search_tests
      SpecialIdentifiersChainSearchTestGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_groups
      GroupGenerator.generate(ig_metadata, base_output_dir)
    end

    def generate_suites
      SuiteGenerator.generate(ig_metadata, base_output_dir)
    end

    def use_tests
      file_path = File.expand_path('../au_core_test_kit.rb', __dir__)

      file_content = File.read(file_path)
      string_to_add = "require_relative '#{base_output_dir.split('/opt/inferno/lib/').last}/au_core_test_suite'"

      return if file_content.include? string_to_add

      file_content << "\n#{string_to_add}"
      File.write(file_path, file_content)
    end
  end
end
