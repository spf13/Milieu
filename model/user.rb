class User
  include MongoModule

  attr_accessor :_id, :name, :email, :email_hash, :salt, :hashed_password, :venues

  def init_collection
    @collection = 'users'
  end

  def email=(an_email = nil)
      if an_email == nil
          @email.downcase
      else
          @email = an_email.downcase
          @email_hash = Digest::MD5.hexdigest(@email)
      end
  end

  def password=(pass)
    @salt = random_string(10) unless @salt
    @hashed_password = User.encrypt(pass, @salt)
  end

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end

  def self.auth(email, pass)
    u = USERS.find_one("email" => email.downcase)
    return nil if u.nil?
    return User.new(u) if User.encrypt(pass, u['salt']) == u['hashed_password']
    nil
  end

  def self.new_from_email(email)
    u = USERS.find_one("email" => email.downcase)
    return nil if u.nil?
    return User.new(u)
    nil
  end

  def random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    str = ""
    1.upto(len) { |i| str << chars[rand(chars.size-1)] }
    return str
  end

end
