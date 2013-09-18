require "play/api/error_delivery"
require "play/api/json_delivery"
require "play/api/api_response"
require "play/speaker"

module Play

  # Our connection to MPD.
  #
  # Returns an instance of MPD.
  def self.mpd
    @mpd ||= default_channel.mpd
  end

  def self.default_channel
    @default_channel ||= Channel.first
  end

  # mpd only really knows about the relative path to songs:
  # Justice/Cross/Stress.mp3, for example. We need to know the path before
  # that for a few things (reading in the MP3 tag data, for one). This method
  # reads the path from your config/mpd.conf and loads up the value you have
  # for `music_directory`.
  #
  # Returns a String.
  def self.music_path
    Play.config['mpd']['music_path']
  end

  # Directory where MPD config things will be stored, library database, etc.
  def self.global_mpd_config_path
    File.expand_path('~/.mpd')
  end

  # Directory where cached album art images will be stored.
  def self.album_art_cache_path
    'public/images/art'
  end

  # The config file of Play. Contains things like keys, database config, and
  # who shot JFK.
  #
  # Returns a Hash.
  def self.config
    @config ||= YAML::load(File.open('config/play.yml'))
  end

  # Local instances of Play Speakers found on the network
  #
  # Returns an array of Speaker objects.
  def self.speakers
    @speakers ||= []
  end

  # Starts a music server for each channel
  def self.start_servers
    Channel.all.each do |channel|
      channel.start

      if !Rails.env.test? && channel.mpd

        # Set up mpd to natively consume songs
        channel.mpd.repeat  = true
        channel.mpd.consume = true

        # Scan for new songs just in case
        channel.mpd.update

        # Play the tunes
        channel.mpd.play
      end
    end
  end

  # Stops all music servers
  def self.stop_servers
    Channel.all.each do |channel|
      channel.stop
    end
  end

  # Clears the queues of all Channels.
  #
  # Returns nothing.
  def self.clear_queues
    Channel.all.each do |channel|
      channel.clear
    end
  end

  #
  def self.queued?(song)
    Channel.all.collect(&:queue).flatten.include?(song)
  end

end
