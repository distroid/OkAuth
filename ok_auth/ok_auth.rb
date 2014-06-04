require 'net/http'

#
# Class for OAuth 2.0 on http://odnoklassniki.ru/
#
class OkAuth


	#
	# Class constructor
	#
	# auth_options - array aplication options
	#
	# return string
	#
	def initialize(auth_options)
		@options = {
			'auth_host'         => "www.odnoklassniki.ru",      # domain service
			'auth_page'         => "/oauth/authorize",          # auth page
			'api_host'          => "api.odnoklassniki.ru",      # domain API service
			'access_token_path' => "/oauth/token.do",           # page for getting access token
			'method_url_path'   => "/fb.do"                     # page for request api methods
		}
		@options = @options.merge(auth_options)
	end


	#
	# Getting user auth URL
	#
	# return string
	#
	def get_auth_url
		URI::HTTP.build(
			:host  => @options['auth_host'],
			:path  => @options['auth_page'],
			:query => {
				:client_id     => @options['client_id'],
				:scope         => @options['scope'],
				:response_type => "code",
				:redirect_uri  => @options['redirect_uri'],
			}.to_query
		).to_s
	end


	#
	# Getting SIG for request method "users.getCurrentUser"
	#
	# access_token - string access token for requests api methods
	#
	# return string
	#
	def get_sig(access_token)
		method_str = 'application_key=' + @options['application_key'] + 'method=users.getCurrentUser'
		Digest::MD5.hexdigest(method_str + Digest::MD5.hexdigest(access_token + @options['client_secret']))
	end


	#
	# Gettion user data
	#
	# code - string access code for getting user info
	#
	# return array
	#
	def get_user_data(code)
		access_uri = URI::HTTP.build(
			:host  => @options['api_host'],
			:path  => @options['access_token_path'],
			:query => {
				:code          => code,
				:redirect_uri  => @options['redirect_uri'],
				:grant_type    => "authorization_code",
				:client_id     => @options['client_id'],
				:client_secret => @options['client_secret'],
			}.to_query
		)

		access_request = JSON.parse Net::HTTP.post_form(access_uri, []).body

		current_user_uri = URI::HTTP.build(
			:host  => @options['api_host'],
			:path  => @options["method_url_path"],
			:query => {
				:access_token    => access_request['access_token'],
				:application_key => @options['application_key'],
				:method          => "users.getCurrentUser",
				:sig             => self.get_sig(access_request['access_token'])
			}.to_query
		)

		response = JSON.parse Net::HTTP.get_response(current_user_uri).body

		if response.nil?
			nil
		else 
			response
		end
	end


	public    :get_auth_url, :get_user_data
	protected :get_sig

end