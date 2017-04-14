require 'net/ftp'

class FTPSession
  RESPAWN_INTERVAL = 60 # in seconds

  def initialize(host, port, user, password)
    @ftp = Net::FTP.new
    @host = host
    @port = port
    @user = user
    @password = password
    @last_accessed = Time.now

    connect
  end

  def upload!(local, remote)
    remote { ftp.putbinaryfile(local, remote) }
  end

  def mkdir!(dir)
    remote { ftp.mkdir(dir) }
  end

  def remove!(remote)
    remote { ftp.delete(remote) }
  end

  def rmdir!(dir)
    remote { ftp.rmdir(dir) }
  end

  private

    attr_reader :ftp, :host, :port, :user, :password, :last_accessed

    def connect
      ftp.passive = true
      ftp.connect(host, port)
      ftp.login(user, password)
      last_accessed = Time.now
    end

    def reconnect
      return unless timeout?
      ftp.close
      connect
    end

    def timeout?
      (Time.now - last_accessed) > RESPAWN_INTERVAL
    end

    def remote
      reconnect
      yield.tap do
        @last_accessed = Time.now
      end
    end
end
