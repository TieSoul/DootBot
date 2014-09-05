require 'cinch'
require 'set'

module Cinch::Plugins
  class WordGame
    include Cinch::Plugin

    def initialize(*)
      super
      @words_dict = File.readlines('dict.txt').map(&:chomp).to_set
      @words_to_guess_dict = File.readlines('words_to_guess.txt').map(&:chomp)
    end

    match(/wordgame start/, method: :start)
    def start(m)
      unless @started
        @started = true
        @word = @words_to_guess_dict.sample
        m.reply("#{m.user}: New word game started! I'm thinking of a word, use !guess (word) to guess.")
      end
    end

    match(/guess (\S+)/, method: :guess)
    def guess(m, guess)
      return unless @started

      lowercase_guess = guess.downcase
      lowercase_word = @word.downcase

      unless @words_dict.include?(lowercase_guess)
        m.reply("#{m.user.nick}: #{guess} is not in my dictionary.")
        return
      end

      if lowercase_guess < lowercase_word
        m.reply("#{m.user.nick}: #{guess} comes before the word in the dictionary.")
      elsif lowercase_guess > lowercase_word
        m.reply("#{m.user.nick}: #{guess} comes after the word in the dictionary.")
      else
        m.reply("#{m.user.nick}: #{guess} is correct! #{m.user.nick} is the winner! Congratulations!")
        @started = false
      end
    end
  end
end
