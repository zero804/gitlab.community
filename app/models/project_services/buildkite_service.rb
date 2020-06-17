# frozen_string_literal: true

require "addressable/uri"

class BuildkiteService < CiService
  include ReactiveService

  ENDPOINT = "https://buildkite.com"

  prop_accessor :project_url, :token

  validates :project_url, presence: true, public_url: true, if: :activated?
  validates :token, presence: true, if: :activated?

  after_save :compose_service_hook, if: :activated?

  def self.supported_events
    %w(push merge_request tag_push)
  end

  # Since SSL verification will always be enabled for Buildkite,
  # we no longer needs to store the boolean.
  # This is a stub method to work with deprecated API param.
  # TODO: remove enable_ssl_verification after 14.0
  # https://gitlab.com/gitlab-org/gitlab/-/issues/222808
  def enable_ssl_verification=(_value)
    self.properties.delete('enable_ssl_verification') # Remove unused key
  end

  def webhook_url
    "#{buildkite_endpoint('webhook')}/deliver/#{webhook_token}"
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = webhook_url
    hook.enable_ssl_verification = true
    hook.save
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    service_hook.execute(data)
  end

  def commit_status(sha, ref)
    with_reactive_cache(sha, ref) {|cached| cached[:commit_status] }
  end

  def commit_status_path(sha)
    "#{buildkite_endpoint('gitlab')}/status/#{status_token}.json?commit=#{sha}"
  end

  def build_page(sha, ref)
    "#{project_url}/builds?commit=#{sha}"
  end

  def title
    'Buildkite'
  end

  def description
    'Buildkite is a platform for running fast, secure, and scalable continuous integration pipelines on your own infrastructure'
  end

  def self.to_param
    'buildkite'
  end

  def fields
    [
      { type: 'text',
        name: 'token',
        title: 'Integration Token',
        help: 'This token will be provided when you create a Buildkite pipeline with a GitLab repository',
        required: true },

      { type: 'text',
        name: 'project_url',
        title: 'Pipeline URL',
        placeholder: "#{ENDPOINT}/acme-inc/test-pipeline",
        required: true }
    ]
  end

  def calculate_reactive_cache(sha, ref)
    response = Gitlab::HTTP.try_get(commit_status_path(sha), request_options)

    status =
      if response&.code == 200 && response['status']
        response['status']
      else
        :error
      end

    { commit_status: status }
  end

  private

  def webhook_token
    token_parts.first
  end

  def status_token
    token_parts.second
  end

  def token_parts
    if token.present?
      token.split(':')
    else
      []
    end
  end

  def buildkite_endpoint(subdomain = nil)
    if subdomain.present?
      uri = Addressable::URI.parse(ENDPOINT)
      new_endpoint = "#{uri.scheme || 'http'}://#{subdomain}.#{uri.host}"

      if uri.port.present?
        "#{new_endpoint}:#{uri.port}"
      else
        new_endpoint
      end
    else
      ENDPOINT
    end
  end

  def request_options
    { verify: false, extra_log_info: { project_id: project_id } }
  end
end
