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
    encode_response(user)
  end
end
