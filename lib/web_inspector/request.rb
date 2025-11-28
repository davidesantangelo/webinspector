# frozen_string_literal: true

require 'addressable/uri'

module WebInspector
  class Request
    def initialize(url)
      @url = url
    end

    def url
      normalized_uri
    end

    def host
      uri.host
    end

    def domain
      suffix_domain
    end

    def scheme
      uri.scheme
    end

    def port
      URI(normalized_uri).port
    end

    def valid?
      !uri.nil? && !uri.host.nil?
    rescue StandardError
      false
    end

    def ssl?
      scheme == 'https'
    end

    def error_message
      return nil if valid?

      'Invalid URL: Unable to parse the provided URL'
    end

    private

    def suffix_domain
      return @domain if @domain

      begin
        @domain = PublicSuffix.parse(host).domain
      rescue URI::InvalidURIError, PublicSuffix::DomainInvalid
        @domain = ''
      end
    end

    def uri
      Addressable::URI.parse(@url)
    rescue Addressable::URI::InvalidURIError
      nil
    end

    def normalized_uri
      return '' if uri.nil?

      uri.normalize.to_s
    rescue StandardError
      @url
    end
  end
end
