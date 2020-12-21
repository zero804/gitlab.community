# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::Helper do
  subject(:helper) { described_class.default }

  shared_context 'with a legacy index' do
    before do
      @index_name = helper.create_empty_index(with_alias: false, options: { index_name: helper.target_name })
    end
  end

  shared_context 'with an existing index and alias' do
    before do
      @index_name = helper.create_empty_index(with_alias: true)
    end
  end

  after do
    helper.delete_index(index_name: @index_name)
  end

  describe '.new' do
    it 'has the proper default values' do
      expect(helper).to have_attributes(
        version: ::Elastic::MultiVersionUtil::TARGET_VERSION,
        target_name: ::Elastic::Latest::Config.index_name)
    end

    context 'with a custom `index_name`' do
      let(:index_name) { 'custom-index-name' }

      subject(:helper) { described_class.new(target_name: index_name) }

      it 'has the proper `index_name`' do
        expect(helper).to have_attributes(target_name: index_name)
      end
    end
  end

  describe '#default_mappings' do
    it 'has only one type' do
      expect(helper.default_mappings.keys).to match_array %i(doc)
    end

    context 'custom analyzers' do
      let(:custom_analyzers_mappings) { { doc: { properties: { title: { fields: { custom: true } } } } } }

      before do
        allow(::Elastic::Latest::CustomLanguageAnalyzers).to receive(:custom_analyzers_mappings).and_return(custom_analyzers_mappings)
      end

      it 'merges custom language analyzers mappings' do
        expect(helper.default_mappings[:doc][:properties][:title]).to include(custom_analyzers_mappings[:doc][:properties][:title])
      end
    end
  end

  describe '#create_migrations_index' do
    after do
      helper.delete_index(index_name: helper.migrations_index_name)
    end

    it 'creates the index' do
      expect { helper.create_migrations_index }
             .to change { helper.index_exists?(index_name: helper.migrations_index_name) }
             .from(false).to(true)
    end
  end

  describe '#create_standalone_indices' do
    after do
      @indices.each do |index|
        helper.delete_index(index_name: index)
      end
    end

    it 'creates standalone indices' do
      @indices = helper.create_standalone_indices

      @indices.each do |index|
        expect(helper.index_exists?(index_name: index)).to be_truthy
      end
    end
  end

  describe '#create_empty_index' do
    context 'with an empty cluster' do
      context 'with alias and index' do
        include_context 'with an existing index and alias'

        it 'creates index and alias' do
          expect(helper.index_exists?).to eq(true)
          expect(helper.alias_exists?).to eq(true)
        end
      end

      context 'when there is a legacy index' do
        include_context 'with a legacy index'

        it 'creates the index only' do
          expect(helper.index_exists?).to eq(true)
          expect(helper.alias_exists?).to eq(false)
        end
      end

      it 'creates an index with a custom name' do
        @index_name = 'test-custom-index-name'

        helper.create_empty_index(with_alias: false, options: { index_name: @index_name })

        expect(helper.index_exists?(index_name: @index_name)).to eq(true)
        expect(helper.index_exists?).to eq(false)
      end
    end

    context 'when there is an alias' do
      include_context 'with an existing index and alias'

      it 'raises an error' do
        expect { helper.create_empty_index }.to raise_error(RuntimeError)
      end
    end

    context 'when there is a legacy index' do
      include_context 'with a legacy index'

      it 'raises an error' do
        expect { helper.create_empty_index }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#delete_index' do
    subject { helper.delete_index }

    context 'without an existing index' do
      it 'fails gracefully' do
        is_expected.to be_falsy
      end
    end

    context 'when there is an alias' do
      include_context 'with an existing index and alias'

      it { is_expected.to be_truthy }
    end

    context 'when there is a legacy index' do
      include_context 'with a legacy index'

      it { is_expected.to be_truthy }
    end
  end

  describe '#index_exists?' do
    subject { helper.index_exists? }

    context 'without an existing index' do
      it { is_expected.to be_falsy }
    end

    context 'when there is a legacy index' do
      include_context 'with a legacy index'

      it { is_expected.to be_truthy }
    end

    context 'when there is an alias' do
      include_context 'with an existing index and alias'

      it { is_expected.to be_truthy }
    end
  end

  describe '#alias_exists?' do
    subject { helper.alias_exists? }

    context 'without an existing index' do
      it { is_expected.to be_falsy }
    end

    context 'when there is a legacy index' do
      include_context 'with a legacy index'

      it { is_expected.to be_falsy }
    end

    context 'when there is an alias' do
      include_context 'with an existing index and alias'

      it { is_expected.to be_truthy }
    end
  end

  describe '#cluster_free_size' do
    it 'returns valid cluster size' do
      expect(helper.cluster_free_size_bytes).to be_positive
    end
  end

  describe '#switch_alias' do
    include_context 'with an existing index and alias'

    let(:new_index_name) { 'test-switch-alias' }

    it 'switches the alias' do
      helper.create_empty_index(with_alias: false, options: { index_name: new_index_name })

      expect { helper.switch_alias(to: new_index_name) }
      .to change { helper.target_index_name }.to(new_index_name)

      helper.delete_index(index_name: new_index_name)
    end
  end
end
