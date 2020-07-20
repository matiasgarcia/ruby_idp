class SamlIdpController < SamlIdp::IdpController
  class User
    def initialize(email:, password:, id:)
      @email = email
      @password = password
      @id = id
    end

    attr_reader :email, :password, :id

    def persistent
      id
    end
  end

  def idp_authenticate(email, password)
    User.new(email: email, password: password, id: SecureRandom.uuid)
  end

  def idp_make_saml_response(user)
    begin
      opts = if saml_request.service_provider.cert
                     {
                       encryption: {
                         cert: saml_request.service_provider.cert,
                         block_encryption: 'aes256-cbc',
                         key_transport: 'rsa-oaep-mgf1p'
                       }
                     }
                   else
                     {}
                   end
      encode_response(user, )
    rescue e
      pp e.backtrace
      raise
    end
  end
end
