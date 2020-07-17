SamlIdp.configure do |config|
  base = "http://localhost:5000"

  config.x509_certificate = <<-CERT
-----BEGIN CERTIFICATE-----
#{SamlIdp::Default::X509_CERTIFICATE}
-----END CERTIFICATE-----
  CERT

  config.attributes = {
    "emailAddress" => {
      "name" => 'urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress',                                                # required (ex "urn:oid:1.3.6.1.4.1.5923.1.1.1.1")
      "getter" => ->(principal) {                                         # not required
        principal.email
      },
    },
    "firstName" => {
      "name" => 'urn:oasis:names:tc:SAML:2.0:nameid-format:firstName',
      "getter" => ->(principal) { 'John' }
    },
    "lastName" => {
      "name" => 'urn:oasis:names:tc:SAML:2.0:nameid-format:lastName',
      "getter" => ->(principal) { 'Doe' }
    },
    "persistent" => {
      "name" => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
      "getter" => ->(principal) { principal.id }
    },
    "transient" => {
      "name" => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
      "getter" => ->(principal) { principal.id }
    }
  }

  config.secret_key = SamlIdp::Default::SECRET_KEY

  config.password = "secret_key_password"
  config.algorithm = :sha256

  service_providers = {
    "http://localhost:3000" => {
      fingerprint: SamlIdp::Default::FINGERPRINT,
      metadata_url: "http://localhost:3000/saml/metadata",
      response_hosts: ["localhost"]
    },
  }

  # `identifier` is the entity_id or issuer of the Service Provider,
  # settings is an IncomingMetadata object which has a to_h method that needs to be persisted
  config.service_provider.metadata_persister = ->(identifier, settings) {
    fname = identifier.to_s.gsub(/\/|:/,"_")
    FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
    File.open Rails.root.join("cache/saml/metadata/#{fname}"), "r+b" do |f|
      Marshal.dump settings.to_h, f
    end
  }

  # `identifier` is the entity_id or issuer of the Service Provider,
  # `service_provider` is a ServiceProvider object. Based on the `identifier` or the
  # `service_provider` you should return the settings.to_h from above
  config.service_provider.persisted_metadata_getter = ->(identifier, service_provider){
    fname = identifier.to_s.gsub(/\/|:/,"_")
    FileUtils.mkdir_p(Rails.root.join('cache', 'saml', 'metadata').to_s)
    full_filename = Rails.root.join("cache/saml/metadata/#{fname}")
    if File.file?(full_filename)
      File.open full_filename, "rb" do |f|
        Marshal.load f
      end
    end
  }

  # Find ServiceProvider metadata_url and fingerprint based on our settings
  config.service_provider.finder = ->(issuer_or_entity_id) do
    service_providers[issuer_or_entity_id]
  end
end
