module security

pub struct PrivateLink {
pub mut:
	link            string
	title           string
	style           string
	open_new_window bool
	target          string
	target_enabled  bool
	icon_name       string
	icon_enabled    bool
}

pub struct Realm {
pub mut:
	name  string
	label string
}

pub struct UIConfig {
pub mut:
	theme                     string
	templates                 map[string]string @[omitempty]
	allow_role_selection      bool              @[omitempty]
	title                     string            @[omitempty]
	logo_url                  string            @[omitempty]
	logo_description          string            @[omitempty]
	private_links             []PrivateLink     @[omitempty]
	auto_redirect_url         string            @[omitempty]
	realms                    []Realm           @[omitempty]
	password_recovery_enabled bool              @[omitempty]
	custom_css_path           string            @[omitempty]
	custom_js_path            string            @[omitempty]
}

pub struct UserRegistrationConfig {
pub mut:
	disabled              bool
	title                 string
	code                  string
	dropbox               string
	require_accept_terms  bool
	require_domain_mx     bool
	terms_conditions_link string
	privacy_policy_link   string
	email_provider        string
	admin_emails          []string
}

pub struct UserTransformerConfig {
pub mut:
	matchers []string
	actions  []string
}

pub struct DomainConfig {
pub mut:
	seq       int
	domain    string
	path      string
	lifetime  int
	insecure  bool
	same_site string
}

pub struct CookieConfig {
pub mut:
	domains   map[string]DomainConfig @[omitempty]
	path      string
	lifetime  int
	insecure  bool
	same_site string
}

pub struct AccessListConfig {
pub mut:
	comment    string
	conditions []string
	action     string
}

pub struct TokenValidatorOptions {
pub mut:
	validate_source_address         bool
	validate_bearer_header          bool
	validate_method_path            bool
	validate_access_list_path_claim bool
}

pub struct CryptoKeyConfig {
pub mut:
	seq               int
	id                string
	usage             string
	token_name        string
	source            string
	algorithm         string
	env_var_name      string
	env_var_type      string
	env_var_value     string
	file_path         string
	dir_path          string
	token_lifetime    int
	token_secret      string
	token_sign_method string
	token_eval_expr   []string
}

pub struct TokenGrantorOptions {
pub mut:
	enable_source_address bool
}

pub struct APIConfig {
pub mut:
	enabled bool @[skip]
}

pub struct AuthenticationPortal {
pub mut:
	name                     string
	ui                       UIConfig
	user_registration_config UserRegistrationConfig  @[omitempty]
	user_transformer_configs []UserTransformerConfig @[omitempty]
	cookie_config            CookieConfig            @[omitempty]
	identity_stores          []string                @[omitempty]
	identity_providers       []string                @[omitempty]
	access_list_configs      []AccessListConfig      @[omitempty]
	token_validator_options  TokenValidatorOptions   @[omitempty]
	crypto_key_configs       []CryptoKeyConfig
	crypto_key_store_config  map[string]string   @[omitempty]
	token_grantor_options    TokenGrantorOptions @[omitempty]
	api                      APIConfig           @[omitempty]
}

pub struct BypassConfig {
pub mut:
	match_type string
	uri        string
}

pub struct HeaderInjectionConfig {
pub mut:
	header string
	field  string
}

pub struct AuthorizationPolicy {
pub mut:
	name                            string
	auth_url_path                   string
	disable_auth_redirect           bool
	disable_auth_redirect_query     bool
	auth_redirect_query_param       string
	auth_redirect_status_code       int
	redirect_with_javascript        bool
	bypass_configs                  []BypassConfig             @[omitempty]
	header_injection_configs        []HeaderInjectionConfig    @[omitempty]
	access_list_rules               []AccessListConfig         @[omitempty]
	crypto_key_configs              []CryptoKeyConfig          @[omitempty]
	crypto_key_store_config         map[string]string          @[omitempty]
	auth_proxy_config               map[string]map[string]bool @[omitempty]
	allowed_token_sources           []string
	strip_token_enabled             bool
	forbidden_url                   string
	user_identity_field             string
	validate_bearer_header          bool
	validate_method_path            bool
	validate_access_list_path_claim bool
	validate_source_address         bool
	pass_claims_with_headers        bool
	login_hint_validators           []string
}

pub struct EmailProvider {
pub mut:
	name              string
	address           string
	protocol          string
	credentials       string
	sender_email      string
	sender_name       string
	templates         map[string]string
	passwordless      bool
	blind_carbon_copy []string
}

pub struct FileProvider {
pub mut:
	name      string
	root_dir  string
	templates map[string]string
}

pub struct MessagingConfig {
pub mut:
	email_providers []EmailProvider
	file_providers  []FileProvider
}

pub struct IdentityStore {
pub mut:
	name   string
	kind   string
	params map[string]string
}

pub struct IdentityProvider {
pub mut:
	name   string
	kind   string
	params Params @[omitempty]
}

pub struct Params {
	base_auth_url string   @[omitempty]
	client_id     string   @[omitempty]
	client_secret string   @[omitempty]
	domain_name   string   @[omitempty]
	driver        string   @[omitempty]
	metadata_url  string   @[omitempty]
	realm         string   @[omitempty]
	scopes        []string @[omitempty]
}

pub struct Security {
pub mut:
	config Config @[omitempty]
}

pub struct Config {
pub mut:
	credentials            map[string][]GenericCredential @[omitempty; skip]
	authentication_portals []AuthenticationPortal         @[omitempty]
	authorization_policies []AuthorizationPolicy          @[omitempty]
	messaging              MessagingConfig                @[omitempty]
	identity_stores        []IdentityStore                @[omitempty]
	identity_providers     []IdentityProvider             @[omitempty]
}

pub struct GenericCredential {
pub mut:
	name     string
	username string
	password string
	domain   string
}
