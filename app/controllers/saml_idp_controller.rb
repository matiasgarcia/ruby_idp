class SamlIdpController < SamlIdp::IdpController
  prepend_before_action :setup

  def idp_authenticate(email, password)
    true
  end

  def idp_make_saml_response(user)
    encode_SAMLResponse("you@example.com")
  end

  private

  def setup
    config = SamlIdp.config
    config.x509_certificate = Default::X509_CERTIFICATE # Base64
    config.secret_key = Default::SECRET_KEY
    config.algorithm = :sha1
  end
end
