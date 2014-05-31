#
# Класс для авторизации через http://odnoklassniki.ru/
#
class OkAuth

	require 'net/http'

	@options												# Массив с опциями для работы с API
	@@auth_url_options	= {
		'auth_host'			=> "www.odnoklassniki.ru",		# адресс для авторизации пользователя сайта
		'auth_page'			=> "/oauth/authorize",			# страница авторизации
		'api_host'			=> "api.odnoklassniki.ru",		# адресс API
		'access_token_path'	=> "/oauth/token.do",			# страница получешния access_token
		'method_url_path'	=> "/fb.do"						# страница обращения к методам API
	}


	#
	# Конструктор класса
	#
	# auth_options - array массив опций приложения
	#
	# return string
	#
	def initialize(auth_options)
		urlOptions	= OkAuth.getUrlOptions
		@options	= auth_options
		@options	= @options.merge(urlOptions)
	end


	#
	# Возвращает URL настройки
	#
	# return array
	#
	def OkAuth.getUrlOptions
		@@auth_url_options
	end


	#
	# Получение URL для авторизации
	#
	# return string
	#
	def getAuthUrl
		URI::HTTP.build(
			:host	=> @options['auth_host'],
			:path	=> @options['auth_page'],
			:query	=> {
				:client_id		=> @options['client_id'],
				:scope			=> @options['scope'],
				:response_type	=> "code",
				:redirect_uri	=> @options['redirect_uri'],
			}.to_query
		).to_s
	end


	#
	# Получение SIG для запроса метода "users.getCurrentUser"
	#
	# access_token - string access token для доступа к метода API
	#
	# return string
	#
	def getSig(access_token)
		methodStr = 'application_key=' + @options['application_key'] + 'method=users.getCurrentUser'
		Digest::MD5.hexdigest(methodStr + Digest::MD5.hexdigest(access_token + @options['client_secret']))
	end


	#
	# Получение данных пользователя
	#
	# code - string код доступа
	#
	# return array
	#
	def getUserData(code)
		accessUri = URI::HTTP.build(
			:host	=> @options['api_host'],
			:path	=> @options['access_token_path'],
			:query	=> {
				:code			=> code,
				:redirect_uri	=> @options['redirect_uri'],
				:grant_type		=> "authorization_code",
				:client_id		=> @options['client_id'],
				:client_secret	=> @options['client_secret'],
			}.to_query
		)

		accessRequest = JSON.parse Net::HTTP.post_form(accessUri, []).body

		getCurrentUserUri = URI::HTTP.build(
			:host	=> @options['api_host'],
			:path	=> @options["method_url_path"],
			:query	=> {
				:access_token		=> accessRequest['access_token'],
				:application_key	=> @options['application_key'],
				:method				=> "users.getCurrentUser",
				:sig				=> self.getSig(accessRequest['access_token'])
			}.to_query
		)

		JSON.parse Net::HTTP.get_response(getCurrentUserUri).body
	end

	public		:getAuthUrl, :getUserData
	protected	:getSig

end