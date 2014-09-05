require 'cinch'

module Cinch::Plugins
  class WordGame
    include Cinch::Plugin

    def initialize(*)
      super
      @dict = File.readlines('dict.txt').map(&:chomp)
    end

    match(/wordgame start/, method: :start)
    def start(m)
      unless @started
        @started = true
        @word = @dict.sample
        m.reply("#{m.user}: New word game started! I'm thinking of a word, use !guess (word) to guess.")
      end
    end

    match(/guess (\S+)/, method: :guess)
    def guess(m, guess)
      return unless @started

      if guess.downcase < @word.downcase
        m.reply("#{m.user.nick}: #{guess} comes before the word in the dictionary.")
      elsif guess.downcase > @word.downcase
        m.reply("#{m.user.nick}: #{guess} comes after the word in the dictionary.")
      else
        m.reply("#{m.user.nick}: #{guess} is correct! #{m.user.nick} is the winner! Congratulations!")
        @started = false
      end
    end
  end
end
