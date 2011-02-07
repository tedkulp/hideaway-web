class User

	include MongoMapper::Document

	key :username, String, :unique => true
	key :password, String

	timestamps!

	attr_accessor :password, :password_confirmation
	validates_presence_of :password, :allow_blank => true
	validates_confirmation_of :password

	scope :by_username,  lambda { |username| where(:username => username) }

	def password=(pass)
		pass = encrypt(pass)
		@password = pass
	end

	def self.authenticate(username, pass)
		current_user = by_username(username).first
		return nil if current_user.nil?
		return current_user if User.encrypt(pass) == current_user.password
		nil
	end

	def self.encrypt(pass)
		Digest::SHA1.hexdigest(pass)
	end

	protected

		def method_missing(m, *args)
			return false
		end

end
