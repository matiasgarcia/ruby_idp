class SamlIdpController < SamlIdp::IdpController
  def idp_authenticate(email, password)
    true
  end

  def idp_make_saml_response(user)
    encode_response("you@example.com")
  end
end
