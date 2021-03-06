require 'spec_helper'

include R509::Cert::Extensions

shared_examples_for "a correctly implemented wrap_openssl_extensions" do
  before :each do
    @r509_extensions = R509::Cert::Extensions.wrap_openssl_extensions( @openssl_extensions )

    @r509_classes = [ BasicConstraints, KeyUsage, ExtendedKeyUsage,
            SubjectKeyIdentifier, AuthorityKeyIdentifier,
            SubjectAlternativeName, AuthorityInfoAccess,
            CRLDistributionPoints, OCSPNoCheck ]
  end

  it "should not have returned values that aren't R509 extensions" do
    classes = @r509_extensions.values.map { |ext| ext.class }
    non_r509_classes = classes.reject { |ext_class| @r509_classes.include?(ext_class) }
    non_r509_classes.should == []
  end

  it "should have returned the right number of extensions" do
    @r509_extensions.count.should == @wrappable_extensions.count
  end

  it "should not have returned keys improperly mapped to values" do
    incorrect_mappings = @r509_extensions.select { |key_class,ext| ext.class != key_class }
    incorrect_mappings = {} if incorrect_mappings == [] # compatibility for old versions of Ruby
    incorrect_mappings.should == {}
  end

  it "should not have failed to map an implemented extension" do
    missing_extensions = []
    @wrappable_extensions.each do |openssl_ext|
      if (@r509_extensions.select {|r509_class,r509_ext| r509_ext.oid == openssl_ext.oid}) == {}
        missing_extensions << openssl_ext.oid
      end
    end

    missing_extensions.should == []
  end
end

shared_examples_for "a correctly implemented get_unknown_extensions" do
  it "should not have returned values that are R509 extensions" do
    R509::Cert::Extensions.get_unknown_extensions( @openssl_extensions ).should == @unknown_extensions
  end
end

shared_examples_for "a correct R509 BasicConstraints object" do |critical|
  before :all do
    extension_name = "basicConstraints"
    klass = BasicConstraints
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @extension_value , critical)
    @r509_ext = klass.new( openssl_ext )
  end

  it "is_ca? should correctly report whether it's a CA certificate (critical:#{critical})" do
    @r509_ext.is_ca?.should == @is_ca
  end

  it "the path length should be correct (critical:#{critical})" do
    @r509_ext.path_length.should == @pathlen
  end

  it "allows_sub_ca? should correctly report whether its path length allows it to issue CA certs (critical:#{critical})" do
    @r509_ext.allows_sub_ca?.should == @allows_sub_ca
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 KeyUsage object" do |critical|
  before :each do
    extension_name = "keyUsage"
    klass = KeyUsage
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @extension_value, critical )
    @r509_ext = klass.new( openssl_ext )
  end

  it "allowed_uses should be non-nil critical:#{critical}" do
    @r509_ext.allowed_uses.should_not == nil
  end

  it "allowed_uses should be correct critical:#{critical}" do
    @r509_ext.allowed_uses.should == @allowed_uses
  end

  it "the individual allowed-use functions should be correct critical:#{critical}" do
    @r509_ext.digital_signature?.should == @allowed_uses.include?( KeyUsage::AU_DIGITAL_SIGNATURE )
    @r509_ext.non_repudiation?.should == @allowed_uses.include?( KeyUsage::AU_NON_REPUDIATION )
    @r509_ext.key_encipherment?.should == @allowed_uses.include?( KeyUsage::AU_KEY_ENCIPHERMENT )
    @r509_ext.data_encipherment?.should == @allowed_uses.include?( KeyUsage::AU_DATA_ENCIPHERMENT )
    @r509_ext.key_agreement?.should == @allowed_uses.include?( KeyUsage::AU_KEY_AGREEMENT )
    @r509_ext.key_cert_sign?.should == @allowed_uses.include?( KeyUsage::AU_KEY_CERT_SIGN )
    @r509_ext.crl_sign?.should == @allowed_uses.include?( KeyUsage::AU_CRL_SIGN )
    @r509_ext.encipher_only?.should == @allowed_uses.include?( KeyUsage::AU_ENCIPHER_ONLY )
    @r509_ext.decipher_only?.should == @allowed_uses.include?( KeyUsage::AU_DECIPHER_ONLY )
  end

  it "the #allows? method should work critical:#{critical}" do
    @allowed_uses.each do |au|
      @r509_ext.allows?(au).should == true
    end
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 ExtendedKeyUsage object" do |critical|
  before :all do
    extension_name = "extendedKeyUsage"
    klass = ExtendedKeyUsage
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @extension_value , critical )
    @r509_ext = klass.new( openssl_ext )
  end

  it "allowed_uses should be non-nil critical:#{critical}" do
    @r509_ext.allowed_uses.should_not == nil
  end

  it "allowed_uses should be correct critical:#{critical}" do
    @r509_ext.allowed_uses.should == @allowed_uses
  end

  it "the individual allowed-use functions should be correct critical:#{critical}" do
    @r509_ext.web_server_authentication?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_WEB_SERVER_AUTH )
    @r509_ext.web_client_authentication?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_WEB_CLIENT_AUTH )
    @r509_ext.code_signing?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_CODE_SIGNING )
    @r509_ext.email_protection?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_EMAIL_PROTECTION )
    @r509_ext.ocsp_signing?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_OCSP_SIGNING )
    @r509_ext.time_stamping?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_TIME_STAMPING )
    @r509_ext.any_extended_key_usage?.should == @allowed_uses.include?( ExtendedKeyUsage::AU_ANY_EXTENDED_KEY_USAGE )
  end

  it "the #allows? method should work critical:#{critical}" do
    @allowed_uses.each do |au|
      @r509_ext.allows?(au).should == true
    end
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 SubjectKeyIdentifier object" do
  before :all do
    extension_name = "subjectKeyIdentifier"
    klass = SubjectKeyIdentifier
    openssl_ext = OpenSSL::X509::Extension.new( extension_name, @extension_value )
    @r509_ext = klass.new( openssl_ext )
  end

  it "key should be correct" do
    @r509_ext.key.should == @key
  end
end

shared_examples_for "a correct R509 AuthorityKeyIdentifier object" do
  before :all do
    extension_name = "authorityKeyIdentifier"
    klass = AuthorityKeyIdentifier
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.issuer_certificate = OpenSSL::X509::Certificate.new TestFixtures::TEST_CA_CERT
    openssl_ext = ef.create_extension( "authorityKeyIdentifier", @extension_value )
    @r509_ext = klass.new( openssl_ext )
  end

  it "has the expected type" do
    @r509_ext.oid.should == "authorityKeyIdentifier"
  end

  it "contains the key identifier" do
    @r509_ext.key_identifier.should == "79:75:BB:84:3A:CB:2C:DE:7A:09:BE:31:1B:43:BC:1C:2A:4D:53:58"
  end
  it "parses the authority cert issuer and serial number" do
    @r509_ext.authority_cert_issuer.value.to_s.should == "/C=US/ST=Illinois/L=Chicago/O=Ruby CA Project/CN=Test CA"
    @r509_ext.authority_cert_serial_number.should == 'FF:D9:C7:0B:87:37:D1:94'
  end
end

shared_examples_for "a correct R509 SubjectAlternativeName object" do |critical|
  before :all do
    extension_name = "subjectAltName"
    klass = SubjectAlternativeName
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.config = OpenSSL::Config.parse(@conf)
    openssl_ext = ef.create_extension( extension_name, @extension_value , critical )
    @r509_ext = klass.new( openssl_ext )
  end

  it "dns_names should be correct critical:#{critical}" do
    @r509_ext.dns_names.should == @dns_names
  end

  it "ip_addresses should be correct critical:#{critical}" do
    @r509_ext.ip_addresses.should == @ip_addresses
  end

  it "rfc_822names should be correct critical:#{critical}" do
    @r509_ext.rfc_822_names.should == @rfc_822_names
  end

  it "uris should be correct critical:#{critical}" do
    @r509_ext.uris.should == @uris
  end

  it "dirNames should be correct critical:#{critical}" do
    @r509_ext.directory_names.size.should == @directory_names.size
  end

  it "ordered should be correct critical:#{critical}" do
    @r509_ext.names.size.should == @dns_names.size + @ip_addresses.size + @rfc_822_names.size + @uris.size + @directory_names.size
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 AuthorityInfoAccess object" do |critical|
  before :all do
    extension_name = "authorityInfoAccess"
    klass = AuthorityInfoAccess
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @extension_value, critical )
    @r509_ext = klass.new( openssl_ext )
  end

  it "ca_issuers_uri should be correct critical:#{critical}" do
    @r509_ext.ca_issuers.uris.should == @ca_issuers_uris
  end

  it "ocsp_uri should be correct critical:#{critical}" do
    @r509_ext.ocsp.uris.should == @ocsp_uris
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 CRLDistributionPoints object" do |critical|
  before :all do
    extension_name = "crlDistributionPoints"
    klass = CRLDistributionPoints
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @extension_value , critical )
    @r509_ext = klass.new( openssl_ext )
  end

  it "crl_uri should be correct critical:#{critical}" do
    @r509_ext.crl.uris.should == @crl_uris
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 OCSPNoCheck object" do |critical|
  before :all do
    extension_name = "noCheck"
    klass = OCSPNoCheck
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, "irrelevant", critical)
    @r509_ext = klass.new( openssl_ext )
  end

  it "has the expected type" do
    @r509_ext.oid.should == "noCheck"
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 CertificatePolicies object" do
  before :all do
    klass = CertificatePolicies
    openssl_ext = OpenSSL::X509::Extension.new @policy_data
    @r509_ext = klass.new( openssl_ext )
  end

  it "should correctly parse the data" do
    @r509_ext.policies.count.should == 1
    @r509_ext.policies[0].policy_identifier.should == "2.16.840.1.12345.1.2.3.4.1"
    @r509_ext.policies[0].policy_qualifiers.cps_uris.should == ["http://example.com/cps", "http://other.com/cps"]
  end
end

shared_examples_for "a correct R509 InhibitAnyPolicy object" do |critical|
  before :all do
    extension_name = "inhibitAnyPolicy"
    klass = InhibitAnyPolicy
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @skip_certs.to_s,critical)
    @r509_ext = klass.new( openssl_ext )
  end

  it "should parse the integer value out of the extension" do
    @r509_ext.skip_certs.should == @skip_certs
  end

  it "reports #critical? properly" do
    @r509_ext.critical?.should == critical
  end
end

shared_examples_for "a correct R509 PolicyConstraints object" do |critical|
  before :all do
    extension_name = "policyConstraints"
    klass = PolicyConstraints
    ef = OpenSSL::X509::ExtensionFactory.new
    openssl_ext = ef.create_extension( extension_name, @extension_value, critical)
    @r509_ext = klass.new( openssl_ext )
  end

  it "should have the expected require policy" do
    @r509_ext.require_explicit_policy.should == @require_explicit_policy
  end
  it "should have the expected inhibit mapping" do
    @r509_ext.inhibit_policy_mapping.should == @inhibit_policy_mapping
  end
end

shared_examples_for "a correct R509 NameConstraints object" do |critical|
  before :all do
    extension_name = "nameConstraints"
    klass = NameConstraints
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.config = OpenSSL::Config.parse(@conf)
    openssl_ext = ef.create_extension( extension_name, @extension_value, critical)
    @r509_ext = klass.new( openssl_ext )
  end

  it "should have the permitted names" do
    @permitted_names.each_with_index do |name,index|
      @r509_ext.permitted_names[index].tag.should == name[:tag]
      @r509_ext.permitted_names[index].value.should == name[:value]
    end
  end
  it "should have the excluded names" do
    @excluded_names.each_with_index do |name,index|
      @r509_ext.excluded_names[index].tag.should == name[:tag]
      @r509_ext.excluded_names[index].value.should == name[:value]
    end
  end
end

describe R509::Cert::Extensions do
  include R509::Cert::Extensions

  context "Class functions" do
    context "#wrap_openssl_extensions and #get_unknown_extensions" do
      context "with no extensions" do
        before :each do
          @wrappable_extensions = []
          @unknown_extensions = []

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it_should_behave_like "a correctly implemented wrap_openssl_extensions"
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end

      context "with one implemented extension" do
        before :each do
          @wrappable_extensions = []
          ef = OpenSSL::X509::ExtensionFactory.new
          @wrappable_extensions << ef.create_extension( "basicConstraints", "CA:TRUE,pathlen:0" )

          @unknown_extensions = []

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it_should_behave_like "a correctly implemented wrap_openssl_extensions"
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end

      context "with all implemented extensions" do
        before :each do
          @wrappable_extensions = []
          ef = OpenSSL::X509::ExtensionFactory.new
          ef.issuer_certificate = OpenSSL::X509::Certificate.new TestFixtures::TEST_CA_CERT
          ef.subject_certificate = OpenSSL::X509::Certificate.new TestFixtures::TEST_CA_CERT
          @wrappable_extensions << ef.create_extension( "basicConstraints", "CA:TRUE,pathlen:0", true )
          @wrappable_extensions << ef.create_extension( "keyUsage", KeyUsage::AU_DIGITAL_SIGNATURE )
          @wrappable_extensions << ef.create_extension( "extendedKeyUsage", ExtendedKeyUsage::AU_WEB_SERVER_AUTH )
          @wrappable_extensions << ef.create_extension( "subjectKeyIdentifier", "hash" )
          @wrappable_extensions << ef.create_extension( "authorityKeyIdentifier", "keyid:always" )
          @wrappable_extensions << ef.create_extension( "subjectAltName", "DNS:www.test.local" )
          @wrappable_extensions << ef.create_extension( "authorityInfoAccess", "caIssuers;URI:http://www.test.local" )
          @wrappable_extensions << ef.create_extension( "crlDistributionPoints", "URI:http://www.test.local" )

          @unknown_extensions = []

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it_should_behave_like "a correctly implemented wrap_openssl_extensions"
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end

      context "with an unimplemented extension" do
        before :each do
          @wrappable_extensions = []

          @unknown_extensions = []
          @unknown_extensions << OpenSSL::X509::Extension.new( "issuerAltName", "DNS:www.test.local" )

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it_should_behave_like "a correctly implemented wrap_openssl_extensions"
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end

      context "with implemented and unimplemented extensions" do
        before :each do
          @wrappable_extensions = []
          ef = OpenSSL::X509::ExtensionFactory.new
          @wrappable_extensions << ef.create_extension( "basicConstraints", "CA:TRUE,pathlen:0" )

          @unknown_extensions = []
          @unknown_extensions << OpenSSL::X509::Extension.new( "issuerAltName", "DNS:www.test.local" )

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it_should_behave_like "a correctly implemented wrap_openssl_extensions"
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end

      context "with multiple extensions of an implemented type" do
        before :each do
          @wrappable_extensions = []
          ef = OpenSSL::X509::ExtensionFactory.new
          @wrappable_extensions << ef.create_extension( "basicConstraints", "CA:TRUE,pathlen:0" )
          @wrappable_extensions << ef.create_extension( "basicConstraints", "CA:TRUE,pathlen:1" )

          @unknown_extensions = []
          @unknown_extensions << OpenSSL::X509::Extension.new( "issuerAltName", "DNS:www.test.local" )

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it "should raise an ArgumentError for #wrap_openssl_extensions" do
          expect {
            R509::Cert::Extensions.wrap_openssl_extensions( @openssl_extensions )
          }.to raise_error(ArgumentError)
        end
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end

      context "with multiple extensions of an unimplemented type" do
        before :each do
          @wrappable_extensions = []
          ef = OpenSSL::X509::ExtensionFactory.new
          @wrappable_extensions << ef.create_extension( "basicConstraints", "CA:TRUE,pathlen:0" )

          @unknown_extensions = []
          @unknown_extensions << OpenSSL::X509::Extension.new( "issuerAltName", "DNS:www.test.local" )
          @unknown_extensions << OpenSSL::X509::Extension.new( "issuerAltName", "DNS:www2.test.local" )

          @openssl_extensions = @wrappable_extensions + @unknown_extensions
        end

        it_should_behave_like "a correctly implemented wrap_openssl_extensions"
        it_should_behave_like "a correctly implemented get_unknown_extensions"
      end
    end
  end

  context "BasicConstraints" do
    context "with constraints for a CA certificate" do
      before :all do
        @extension_value = "CA:TRUE,pathlen:3"
        @is_ca = true
        @pathlen = 3
        @allows_sub_ca = true
      end

      it_should_behave_like "a correct R509 BasicConstraints object", false
      it_should_behave_like "a correct R509 BasicConstraints object", true
    end

    context "with constraints for a sub-CA certificate" do
      before :all do
        @extension_value = "CA:TRUE,pathlen:0"
        @is_ca = true
        @pathlen = 0
        @allows_sub_ca = false
      end

      it_should_behave_like "a correct R509 BasicConstraints object", false
      it_should_behave_like "a correct R509 BasicConstraints object", true
    end

    context "with constraints for a non-CA certificate" do
      before :all do
        @extension_value = "CA:FALSE"
        @is_ca = false
        @pathlen = nil
        @allows_sub_ca = false
      end

      it_should_behave_like "a correct R509 BasicConstraints object", false
      it_should_behave_like "a correct R509 BasicConstraints object", true
    end
  end

  context "KeyUsage" do
    context "with one allowed use" do
      before :all do
        @allowed_uses = [ KeyUsage::AU_DIGITAL_SIGNATURE ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 KeyUsage object", false
      it_should_behave_like "a correct R509 KeyUsage object", true
    end

    context "with some allowed uses" do
      before :all do
        # this spec and the one below alternate the uses
        @allowed_uses = [ KeyUsage::AU_DIGITAL_SIGNATURE, KeyUsage::AU_KEY_ENCIPHERMENT, KeyUsage::AU_KEY_AGREEMENT, KeyUsage::AU_CRL_SIGN, KeyUsage::AU_DECIPHER_ONLY ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 KeyUsage object", false
      it_should_behave_like "a correct R509 KeyUsage object", true
    end

    context "with some different allowed uses" do
      before :all do
        @allowed_uses = [ KeyUsage::AU_NON_REPUDIATION, KeyUsage::AU_DATA_ENCIPHERMENT, KeyUsage::AU_KEY_CERT_SIGN, KeyUsage::AU_ENCIPHER_ONLY ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 KeyUsage object", false
      it_should_behave_like "a correct R509 KeyUsage object", true
    end

    context "with all allowed uses" do
      before :all do
        @allowed_uses = [ KeyUsage::AU_DIGITAL_SIGNATURE, KeyUsage::AU_NON_REPUDIATION,
                 KeyUsage::AU_KEY_ENCIPHERMENT, KeyUsage::AU_DATA_ENCIPHERMENT,
                 KeyUsage::AU_KEY_AGREEMENT, KeyUsage::AU_KEY_CERT_SIGN,
                 KeyUsage::AU_CRL_SIGN, KeyUsage::AU_ENCIPHER_ONLY,
                 KeyUsage::AU_DECIPHER_ONLY ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 KeyUsage object", false
      it_should_behave_like "a correct R509 KeyUsage object", true
    end
  end

  context "ExtendedKeyUsage" do
    context "with one allowed use" do
      before :all do
        @allowed_uses = [ ExtendedKeyUsage::AU_WEB_SERVER_AUTH ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 ExtendedKeyUsage object", false
      it_should_behave_like "a correct R509 ExtendedKeyUsage object", true
    end

    context "with some allowed uses" do
      before :all do
        # this spec and the one below alternate the uses
        @allowed_uses = [ ExtendedKeyUsage::AU_WEB_SERVER_AUTH, ExtendedKeyUsage::AU_CODE_SIGNING ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 ExtendedKeyUsage object", false
      it_should_behave_like "a correct R509 ExtendedKeyUsage object", true
    end

    context "with some different allowed uses" do
      before :all do
        @allowed_uses = [ ExtendedKeyUsage::AU_WEB_CLIENT_AUTH, ExtendedKeyUsage::AU_EMAIL_PROTECTION ]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 ExtendedKeyUsage object", false
      it_should_behave_like "a correct R509 ExtendedKeyUsage object", true
    end

    context "with all allowed uses" do
      before :all do
        @allowed_uses = [ ExtendedKeyUsage::AU_WEB_SERVER_AUTH, ExtendedKeyUsage::AU_CODE_SIGNING,
                  ExtendedKeyUsage::AU_WEB_CLIENT_AUTH, ExtendedKeyUsage::AU_EMAIL_PROTECTION,
                  ExtendedKeyUsage::AU_TIME_STAMPING, ExtendedKeyUsage::AU_OCSP_SIGNING,
                  ExtendedKeyUsage::AU_ANY_EXTENDED_KEY_USAGE]
        @extension_value = @allowed_uses.join( ", " )
      end

      it_should_behave_like "a correct R509 ExtendedKeyUsage object", false
      it_should_behave_like "a correct R509 ExtendedKeyUsage object", true
    end
  end

  context "SubjectKeyIdentifier" do
    before :all do
      @extension_value = "00:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD:EE:FF:00:11:22"
      @key = @extension_value
    end

    it_should_behave_like "a correct R509 SubjectKeyIdentifier object"
  end

  context "AuthorityKeyIdentifier" do
    before :all do
      @extension_value = "keyid:always,issuer:always"
    end

    it_should_behave_like "a correct R509 AuthorityKeyIdentifier object"
  end

  context "SubjectAlternativeName" do
    context "with an unimplemented GeneralName type" do
      it "errors as expected" do
        ef = OpenSSL::X509::ExtensionFactory.new
        ext = ef.create_extension("subjectAltName","otherName:1.2.3.4;IA5STRING:Hello World")
        expect { R509::Cert::Extensions::SubjectAlternativeName.new ext }.to raise_error(R509::R509Error, 'Unimplemented GeneralName tag: 0. At this time R509 does not support GeneralName types other than rfc822Name, dNSName, uniformResourceIdentifier, iPAddress, and directoryName')
      end
    end
    context "with a DNS alternative name only" do
      before :all do
        @dns_names = ["www.test.local"]
        @ip_addresses = []
        @uris = []
        @rfc_822_names = []
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with multiple DNS alternative names only" do
      before :all do
        @dns_names = ["www.test.local", "www2.test.local"]
        @ip_addresses = []
        @uris = []
        @rfc_822_names = []
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with an IP address alternative name only" do
      before :all do
        @dns_names = []
        @ip_addresses = ["203.1.2.3"]
        @rfc_822_names = []
        @uris = []
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with multiple IP address alternative names only" do
      before :all do
        @dns_names = []
        @ip_addresses = ["10.1.2.3", "10.1.2.4"]
        @uris = []
        @rfc_822_names = []
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with an rfc822Name alternative name only" do
      before :all do
        @dns_names = []
        @ip_addresses = []
        @rfc_822_names = ["some@guy.com"]
        @uris = []
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with multiple rfc822Name alternative names only" do
      before :all do
        @dns_names = []
        @ip_addresses = []
        @rfc_822_names = ["some@guy.com","other@guy.com"]
        @uris = []
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with a URI alternative name only" do
      before :all do
        @dns_names = []
        @ip_addresses = []
        @rfc_822_names = []
        @uris = ["http://www.test.local"]
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with multiple URI alternative names only" do
      before :all do
        @dns_names = []
        @ip_addresses = []
        @rfc_822_names = []
        @uris = ["http://www.test.local","http://www2.test.local"]
        @directory_names = []
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with a directoryName alternative name only" do
      before :all do
        @dns_names = []
        @ip_addresses = []
        @rfc_822_names = []
        @uris = []
        @directory_names = [
          [['CN','langui.sh'],['O','org'],['L','locality']]
        ]
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with multiple directoryName alternative names only" do
      before :all do
        @dns_names = []
        @ip_addresses = []
        @rfc_822_names = []
        @uris = []
        @directory_names = [
          [['CN','langui.sh'],['O','org'],['L','locality']],
          [['CN','otherdomain.com'],['O','org-like']]
        ]
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end

    context "with multiple different alternative names" do
      before :all do
        @dns_names = ["www.test.local"]
        @ip_addresses = ["10.1.2.3"]
        @rfc_822_names = ["myemail@email.com"]
        @uris = ["http://www.test.local"]
        @directory_names = [
          [['CN','langui.sh'],['O','org'],['L','locality']]
        ]
        total = [@dns_names,@ip_addresses,@uris,@rfc_822_names,@directory_names].flatten(1)
        gns = R509::ASN1.general_name_parser(total)
        serialized = gns.serialize_names
        @conf = serialized[:conf]
        @extension_value = serialized[:extension_string]
      end

      it_should_behave_like "a correct R509 SubjectAlternativeName object", false
      it_should_behave_like "a correct R509 SubjectAlternativeName object", true
    end
  end
  context "AuthorityInfoAccess" do
    context "with a CA Issuers URI only" do
      before :all do
        @ca_issuers_uris = ["http://www.test.local/ca.cert"]
        @ocsp_uris = []
        @extension_value = "caIssuers;URI:#{@ca_issuers_uris.join(",caIssuers;URI:")}"
      end

      it_should_behave_like "a correct R509 AuthorityInfoAccess object", false
      it_should_behave_like "a correct R509 AuthorityInfoAccess object", true
    end

    context "with multiple CA Issuers URIs only" do
      before :all do
        @ca_issuers_uris = ["http://www.test.local/ca.cert", "http://www.test.local/subca.cert"]
        @ocsp_uris = []
        @extension_value = "caIssuers;URI:#{@ca_issuers_uris.join(",caIssuers;URI:")}"
      end

      it_should_behave_like "a correct R509 AuthorityInfoAccess object", false
      it_should_behave_like "a correct R509 AuthorityInfoAccess object", true
    end

    context "with an OCSP URI only" do
      before :all do
        @ca_issuers_uris = []
        @ocsp_uris = ["http://www.test.local"]
        @extension_value = "OCSP;URI:#{@ocsp_uris.join(",OCSP;URI:")}"
      end

      it_should_behave_like "a correct R509 AuthorityInfoAccess object", false
      it_should_behave_like "a correct R509 AuthorityInfoAccess object", true
    end

    context "with multiple OCSP URIs only" do
      before :all do
        @ca_issuers_uris = []
        @ocsp_uris = ["http://www.test.local", "http://www2.test.local"]
        @extension_value = "OCSP;URI:#{@ocsp_uris.join(",OCSP;URI:")}"
      end

      it_should_behave_like "a correct R509 AuthorityInfoAccess object", false
      it_should_behave_like "a correct R509 AuthorityInfoAccess object", true
    end

    context "with both a CA Issuers URI and an OCSP URI" do
      before :all do
        @ca_issuers_uris = ["http://www.test.local/ca.cert"]
        @ocsp_uris = ["http://www.test.local"]
        @extension_value = "caIssuers;URI:#{@ca_issuers_uris.join(",caIssuers;URI:")},OCSP;URI:#{@ocsp_uris.join(",OCSP;URI:")}"
      end

      it_should_behave_like "a correct R509 AuthorityInfoAccess object", false
      it_should_behave_like "a correct R509 AuthorityInfoAccess object", true
    end
  end

  context "CRLDistributionPoints" do
    context "with a single CRL URI" do
      before :all do
        @crl_uris = ["http://www.test.local/ca.crl"]
        @extension_value = "URI:#{@crl_uris.join(",URI:")}"
      end

      it_should_behave_like "a correct R509 CRLDistributionPoints object", false
      it_should_behave_like "a correct R509 CRLDistributionPoints object", true
    end

    context "with multiple CRL URIs" do
      before :all do
        @crl_uris = ["http://www.test.local/ca.crl", "http://www.test.local/subca.crl"]
        @extension_value = "URI:#{@crl_uris.join(",URI:")}"
      end

      it_should_behave_like "a correct R509 CRLDistributionPoints object", false
      it_should_behave_like "a correct R509 CRLDistributionPoints object", true
    end
  end

  context "OCSPNoCheck" do
    it_should_behave_like "a correct R509 OCSPNoCheck object", false
    it_should_behave_like "a correct R509 OCSPNoCheck object", true
  end

  context "CertificatePolicies" do
    before :all do
      @policy_data = "0\x81\x90\x06\x03U\x1D \x04\x81\x880\x81\x850\x81\x82\x06\v`\x86H\x01\xE09\x01\x02\x03\x04\x010s0\"\x06\b+\x06\x01\x05\x05\a\x02\x01\x16\x16http://example.com/cps0 \x06\b+\x06\x01\x05\x05\a\x02\x01\x16\x14http://other.com/cps0+\x06\b+\x06\x01\x05\x05\a\x02\x020\x1F0\x16\x16\x06my org0\f\x02\x01\x01\x02\x01\x02\x02\x01\x03\x02\x01\x04\x1A\x05thing"
    end

    it_should_behave_like "a correct R509 CertificatePolicies object"
  end

  context "InhibitAnyPolicy" do
    before :all do
      @skip_certs = 3
    end

    it_should_behave_like "a correct R509 InhibitAnyPolicy object", false
    it_should_behave_like "a correct R509 InhibitAnyPolicy object", true
  end

  context "PolicyConstraints" do
    context "with just require" do
      before :all do
        @require_explicit_policy = 2
        @inhibit_policy_mapping = nil
        @extension_value = "requireExplicitPolicy:#{@require_explicit_policy}"
      end
      it_should_behave_like "a correct R509 PolicyConstraints object", false
      it_should_behave_like "a correct R509 PolicyConstraints object", true
    end
    context "with just inhibit" do
      before :all do
        @require_explicit_policy = nil
        @inhibit_policy_mapping = 3
        @extension_value = "inhibitPolicyMapping:#{@inhibit_policy_mapping}"
      end
      it_should_behave_like "a correct R509 PolicyConstraints object", false
      it_should_behave_like "a correct R509 PolicyConstraints object", true
    end
    context "with both require and inhibit" do
      before :all do
        @require_explicit_policy = 2
        @inhibit_policy_mapping = 3
        @extension_value = "requireExplicitPolicy:#{@require_explicit_policy},inhibitPolicyMapping:#{@inhibit_policy_mapping}"
      end
      it_should_behave_like "a correct R509 PolicyConstraints object", false
      it_should_behave_like "a correct R509 PolicyConstraints object", true
    end

  end

  context "NameConstraints" do
    context "with one permitted name" do
      before :all do
        @excluded_names = []
        @permitted_names = [{:tag => 2, :value => ".whatever.com"}]
        gns = R509::ASN1::GeneralNames.new
        @permitted_names.each do |name|
          gns.add_item(name)
        end
        @conf = []
        permitted = gns.names.map { |name|
          serialized = name.serialize_name
          @conf << serialized[:conf]
          "permitted;" + serialized[:extension_string]
        }.join(",")
        @extension_value = permitted
        @conf = @conf.join("\n")
      end

      it_should_behave_like "a correct R509 NameConstraints object", false
      it_should_behave_like "a correct R509 NameConstraints object", true
    end
    context "with multiple permitted names" do
      before :all do
        @excluded_names = []
        @permitted_names = [{:tag => 2, :value => ".whatever.com"}, {:tag => 1, :value => "user@emaildomain.com" } ]
        gns = R509::ASN1::GeneralNames.new
        @permitted_names.each do |name|
          gns.add_item(name)
        end
        @conf = []
        permitted = gns.names.map { |name|
          serialized = name.serialize_name
          @conf << serialized[:conf]
          "permitted;" + serialized[:extension_string]
        }.join(",")
        @extension_value = permitted
        @conf = @conf.join("\n")
      end

      it_should_behave_like "a correct R509 NameConstraints object", false
      it_should_behave_like "a correct R509 NameConstraints object", true
    end
    context "with one excluded name" do
      before :all do
        @permitted_names = []
        @excluded_names = [{:tag => 7, :value => "127.0.0.1/255.255.255.255"}]
        egns = R509::ASN1::GeneralNames.new
        @excluded_names.each do |name|
          egns.add_item(name)
        end
        @conf = []
        excluded = egns.names.map { |name|
          serialized = name.serialize_name
          @conf << serialized[:conf]
          "excluded;" + serialized[:extension_string]
        }.join(",")
        @extension_value = excluded
        @conf = @conf.join("\n")
      end

      it_should_behave_like "a correct R509 NameConstraints object", false
      it_should_behave_like "a correct R509 NameConstraints object", true
    end
    context "with multiple excluded names" do
      before :all do
        @permitted_names = []
        @excluded_names = [{:tag => 7, :value => "127.0.0.1/255.255.255.255"}, {:tag => 1, :value => "emaildomain.com" } ]
        @permitted_names = []
        egns = R509::ASN1::GeneralNames.new
        @excluded_names.each do |name|
          egns.add_item(name)
        end
        @conf = []
        excluded = egns.names.map { |name|
          serialized = name.serialize_name
          @conf << serialized[:conf]
          "excluded;" + serialized[:extension_string]
        }.join(",")
        @extension_value = excluded
        @conf = @conf.join("\n")
      end

      it_should_behave_like "a correct R509 NameConstraints object", false
      it_should_behave_like "a correct R509 NameConstraints object", true
    end
    context "with both permitted and excluded names" do
      before :all do
        @excluded_names = [{:tag => 7, :value => "127.0.0.1/255.255.255.255"}, {:tag => 1, :value => "emaildomain.com" } ]
        @permitted_names = [{:tag => 2, :value => ".whatever.com"}, {:tag => 1, :value => "user@emaildomain.com"} ]
        gns = R509::ASN1::GeneralNames.new
        @permitted_names.each do |name|
          gns.add_item(name)
        end
        @conf = []
        permitted = gns.names.map { |name|
          serialized = name.serialize_name
          @conf << serialized[:conf]
          "permitted;" + serialized[:extension_string]
        }.join(",")
        egns = R509::ASN1::GeneralNames.new
        @excluded_names.each do |name|
          egns.add_item(name)
        end
        excluded = egns.names.map { |name|
          serialized = name.serialize_name
          @conf << serialized[:conf]
          "excluded;" + serialized[:extension_string]
        }.join(",")
        @extension_value = permitted + "," + excluded
        @conf = @conf.join("\n")
      end

      it_should_behave_like "a correct R509 NameConstraints object", false
      it_should_behave_like "a correct R509 NameConstraints object", true
    end
  end
end
