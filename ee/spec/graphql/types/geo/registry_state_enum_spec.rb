# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['RegistryState'] do
  it { expect(described_class.graphql_name).to eq('RegistryState') }

  it 'exposes the correct registry states' do
    expect(described_class.values.keys).to include(*%w[PENDING STARTED SYNCED FAILED])
  end
end
