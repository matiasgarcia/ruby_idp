SamlIdp.configure do |config|
  base = "http://localhost:5000"

  PAYLOAD_CERT = <<~CERT
MIIDbzCCAlagAwIBAgIBADANBgkqhkiG9w0BAQsFADBRMQswCQYDVQQGEwJ1czEL
MAkGA1UECAwCTlkxFzAVBgNVBAoMDkx1bWludFBhcmFsbGVsMRwwGgYDVQQDDBNw
YXJhbGxlbC5sdW1pbnQuY29tMB4XDTIwMDcyMDE1NTU0NloXDTIyMDcyMDE1NTU0
NlowUTELMAkGA1UEBhMCdXMxCzAJBgNVBAgMAk5ZMRcwFQYDVQQKDA5MdW1pbnRQ
YXJhbGxlbDEcMBoGA1UEAwwTcGFyYWxsZWwubHVtaW50LmNvbTCCASMwDQYJKoZI
hvcNAQEBBQADggEQADCCAQsCggECAOLaixJ8ky1Brv0F+H4/dPjrY0obVOeZb8p2
xzExk/Z9V6ob4DuIATQTqbff/3FuwIzWsH0Nx88gS1AJTryw/MyMRCH4RgatPhVZ
900nbnMjJej509+bNISvKLjBXmklOovIT4baI1fLSJX7KLr4W98BgeXM+wF6pfcF
KxaW7e0Oj42vMOZh0ctms0tc3zgfX2iaopayX2kHZq7oVokb/w9Fs59fnjL3kkh8
XxGOJsXMBFj5JR3ZzGe7ax/q/ynEjN4o41h2Nrn0KJqC/tRog30gVp9sHmeHGMTL
XHX4XMBmVv2rRMPu9QGWdMidegmwf4pk4OOSOMBqq9hvSfxAu9IPAgMBAAGjUDBO
MB0GA1UdDgQWBBSF4lwg/GWXBeeKBjUR0LD23voS4zAfBgNVHSMEGDAWgBSF4lwg
/GWXBeeKBjUR0LD23voS4zAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IB
AgAI677T4V7ZiMiTAgxaFaPebljCwrrfmlDNvxjSqaqFQ/TzAzqwY9yH/FpBHzAm
qh8R/lNYhSHYt2DwMXrDRf7WNOhalu/BRRe7the2xYzVMiMSqXzQskZyPmoJfUAk
Z+DTrDIGaWJDlcfO9TcFhEUMQ62Vecz2+SMmaslZrgtJWR9h3hQavURkDUmpj3dH
GYyRLkdovQ94BWzpNQ6snVyiE6TcR/AkfZrFpSWEf/k6opZaEOn5fYGKVT2+QOwv
O+p6VFPsh44aWQtjTWMWjSP15cBXJQVbKDzW2Lhn0yihL6rw1Ko5udn5bpwmRLHg
jvGKSB8PJXoQRL6zDRK3tjFfCA==
  CERT
  CERT = <<~CERT
-----BEGIN CERTIFICATE-----
#{PAYLOAD_CERT}
-----END CERTIFICATE-----
  CERT
  config.x509_certificate = CERT

  #config.secret_key = SamlIdp::Default::SECRET_KEY

  #config.password = "secret_key_password"
  config.algorithm = :sha256

  service_providers = {
    "http://localhost:3000" => {
      fingerprint: 'EB:8E:05:0B:B4:E9:22:6D:5C:9C:9B:2F:CA:2A:91:60:22:1B:0D:EB:07:6E:9D:F2:CA:CA:D3:74:24:B7:3C:4C',
      metadata_url: "http://localhost:3000/saml/metadata",
      response_hosts: ["localhost"],
      cert: nil
    },
  }

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
