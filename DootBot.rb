# encoding: UTF-8
require 'cinch'
require 'httparty'
require 'timeout'
require 'pstore'
require_relative 'rubyfunge'
require_relative 'brainfuck'
require_relative 'word_game'
include Cinch
BOTS = %w(fungot DoofBot HackEgo YayBot idris-bot EgoBot lambdabot Doofbot)
BANS = %w(Disgurntledman)
messages = {}
tells = PStore.new('tells.pstore')
dootbot = Bot.new do
  configure do |c|
    c.server = 'orwell.freenode.net'
    c.nick = 'DootBot'
    c.plugins.plugins = [ Cinch::Plugins::WordGame ]
  end

  on :join do |m|
    if m.user.nick == 'DootBot'
      messages[m.channel] = []
      m.reply('DOOT DOOT!')
    elsif m.channel == '#tppleague'
      m.reply("HELLO #{m.user.nick.upcase}!")
    end
  end

  on :kick do |m|
    if m.params[1] == 'DootBot'
      dootbot.join(m.channel)
    else
      m.reply("RIP #{m.params[1]}")
    end
  end

  on :part do |m|
    if m.channel == '#tppleague'
      m.reply("BYE #{m.user.nick.upcase}!")
    end
  end

  on :message, /^!join [^ ]+$/ do |m|
    if m.user.authname == 'TieSoul'
      dootbot.join(m.message.split(' ')[-1], 'DOOT DOOT!')
    end
  end

  on :message, /^!leave$/ do |m|
    if m.user.authname == 'TieSoul'
      dootbot.part(m.channel, 'DOOT DOOT goodbye!')
    end
  end

  on :message, Regexp.new('^!log.*') do |m|
    paste = HTTParty.post('http://sprunge.us', body: { sprunge: File.open("#{m.channel.to_s[1..m.channel.to_s.length]}log.txt").read })
    m.reply("#{m.user}: Log: #{paste}")
  end

  on :message, Regexp.new('^!clearlogs$', true) do |m|
    if m.user.authname == 'TieSoul'
      File.open("#{m.channel.to_s[1..m.channel.to_s.length]}log.txt", 'w').close
      m.reply('Message logs successfully cleared.')
    end
  end

  on :message, /^s\/.+(?<!\\)\/.*(?<!\\)(\/[ig]*([1-9][0-9]*)?[ig]*)?$/ do |m|
    unless m.channel.users.keys.include? 'YayBot'
      begin
        timeout(1,TimeoutError) do
          insensitive = false
          global = false
          number = 1
          if m.message.split(/(?<!\\)\//).length == 4
            modifiers = m.message.split(/(?<!\\)\//)[-1]
          else
            modifiers = ''
          end
          if modifiers.include? 'i'
            insensitive = true
          end
          if modifiers.include? 'g'
            global = true
          end
          if modifiers.index(/[1-9][0-9]*/) != nil
            m.message.split('/')[-1].gsub(/[1-9][0-9]*/) do |num|
              number = num.to_i
            end
          end
          mes = ''
          mess = nil
          reg = Regexp.new m.message.split(/(?<!\\)\//)[1], insensitive
          msgs = messages[m.channel]
          msgs.reverse_each do |m2|
            if m2.message.index(reg) != nil
              mes = m2.message
              mess = m2
              break
            end
          end
          if mes == ''
            m.reply("#{m.user.nick}: Regex /#{reg.source}/ not found.")
          else
            replace = m.message.split(/(?<!\\)\//)[modifiers == '' ? -1 : -2]
            if global
              mes.gsub!(reg, replace.nil? ? '' : replace)
            else
              pos = 0
              i = 0
              until i == number
                i += 1
                pos = mes.index(reg, pos) + 1
              end
              mes.replace mes[0...pos-1] + mes[pos-1..mes.length].sub(reg, replace.nil? ? '' : replace)
            end
            if mes.length < 300
              m.reply("#{m.user.nick}: #{mess.user.nick} actually meant: #{mes}")
            else
              m.reply("#{m.user.nick}: Message too long.")
            end
          end
        end
      rescue TimeoutError
        m.reply("#{m.user.nick}: Timeout")
      end
    end
  end

  on :message, /^!toggleregex$/ do |m|
    if m.user.authname == 'TieSoul'
      $regex = !$regex
    end
  end

  on :message, // do |m|
    file = File.open("#{m.channel.to_s[1..m.channel.to_s.length]}log.txt", 'a')
    file.puts "#{m.time.to_s} <#{m.user.nick}>: #{m.message}"
    file.close
    file = File.open('babble.txt', 'a')
    file.puts m.message
    file.close
    puts m.user.authname
    unless m.message =~ /^s\/.+(?<!\\)\/.*(?<!\\)(\/[ig]*([1-9][0-9]*)?[ig]*)?$/
      messages[m.channel] << m
    end
    if tells.transaction { tells[m.user.nick] } != nil and tells.transaction { tells[m.user.nick] } != []
      tells.transaction { tells[m.user.nick] }.each do |mess|
        m.user.notice mess
      end
      tells.transaction do
        tells[m.user.nick] = nil
      end
    end
  end

  on :message, /!source/ do |m|
    m.reply("#{m.user.nick}: Source: https://gist.github.com/TieSoul/06fe15a20084430a8d12")
  end

  on :message, /.*Doot.*/i do |m|
    unless BOTS.include? m.user.nick or BANS.include? m.user.nick
      fnord = ''
      (1..3).to_a.sample.times do
        babble = File.open('babble.txt', 'r').read.split("\n")
        i = 0
        r = babble.sample.split(' ')
        while r.length > i
          fnord += "#{r[i]} "
          r = babble.sample.split(' ')
          i += 1
          j = 0
          while r.length <= i and j < 4
            r = babble.sample.split(' ')
            j += 1
          end
        end
        unless '!?.'.include? fnord[-2]
          fnord[-1] = '!?.'.split('').sample
          fnord += ' '
        end
      end
      if fnord.split(' ')[0].include?('ACTION')
        m.action_reply("#{fnord.split(' ')[1..fnord.split(' ').length].join(' ')}")
      else
        m.reply("#{m.user.nick}: #{fnord}")
      end
    end
  end

  on :message, /^!brainf... .+/ do |m|
    begin
      timeout(4,TimeoutError) { bfexecute(m.message[10..m.message.length])
                                m.reply(($outbuffer == '' ? 'No output.' : $outbuffer.gsub("\n",' '))) }
    rescue TimeoutError
      m.reply("#{$outbuffer.gsub("\n",' ')[0..200]}... (Execution timed out.)")
    rescue
      m.reply("#{$outbuffer.gsub("\n",' ')[0..200]} (An error occurred.)")
    end
  end

  on :message, /^!togglefunge$/ do |m|
    if m.user.authname == 'TieSoul'
      $disablefunge = !$disablefunge
      m.reply("Befunge-98 successfully toggled #{$disablefunge ? 'off' : 'on'}.")
    end
  end

  on :message, /^!command.*/i do |m|
    m.reply('Commands for me: http://pastebin.com/gs35MvVb')
  end

  on :message, /^!metronome.*/i do |m|
    if m.channel == '#tppleague' or m.channel == '#pokemon'
      move = File.open('moves.txt').read.split("\n").sample
      if move == 'Aerial Ace'
        m.reply("#{m.user.nick} used Metronome! Waggling a finger let him/her/it use #{move}! Kreygasm")
      else
        m.reply("#{m.user.nick} used Metronome! Waggling a finger let him/her/it use #{move}!")
      end
    end
  end

  on :message, /^!befunge98 .*|^!unefunge98 .*/ do |m|
    unless $disablefunge
      unless m.channel != nil and m.channel.users.keys.include? 'EgoBot'
        mess = m.message.split(' ')[1..m.message.length].join(' ').gsub('\n', (m.message.include?('!befunge98') ? "\n" : ''))
        begin
          timeout(4,TimeoutError){execute(mess)}
        rescue TimeoutError
          $outbuffer = "#{$outbuffer.gsub("\n",' ')[0..200]} (Execution timed out.)"
        end
        str = $outbuffer == '' ? 'No output.' : $outbuffer.gsub("\n",' ')
        m.reply("#{m.user.nick}: #{str}")
      end
    end
  end

  on :message, /^!tell .+ .+/ do |m|
    if User(m.message.split(' ')[1]).online?
      User(m.message.split(' ')[1]).notice("<#{m.user.nick}> #{m.message}")
      m.reply('Message sent successfully.')
    else
      if tells.transaction { tells.fetch(m.message.split(' ')[1].downcase,nil) }
        tells.transaction do
          tells[m.message.split(' ')[1].downcase] << "<#{m.user.nick}> #{m.message}"
        end
      else
        tells.transaction do
          tells[m.message.split(' ')[1].downcase] = ["<#{m.user.nick}> #{m.message}"]
        end
      end
      m.reply("A message has been sent to #{m.message.split(' ')[1]}. They will receive it when they come online.")
    end
  end

  on :nick do |m|
    if tells.transaction { tells[m.user.nick.downcase] } != nil and tells.transaction { tells[m.user.nick.downcase] } != []
      tells.transaction { tells[m.user.nick.downcase] }.each do |mess|
        m.user.notice mess
      end
      tells.transaction do
        tells[m.user.nick.downcase] = nil
      end
    end
  end

  on :join do |m|
    if tells.transaction { tells[m.user.nick.downcase] } != nil and tells.transaction { tells[m.user.nick.downcase] } != []
      tells.transaction { tells[m.user.nick.downcase] }.each do |mess|
        m.user.notice mess
      end
      tells.transaction do
        tells[m.user.nick.downcase] = nil
      end
    end
  end

  on :message, /.+riot$/i do |m|
    unless m.channel.users.keys.include? 'DoofBot'
      m.reply('ヽ༼ຈل͜ຈ༽ﾉ ' + m.message.upcase + ' ヽ༼ຈل͜ຈ༽ﾉ')
    end
  end

  on :message, /^impeach .+/i do |m|
    unless m.channel.users.keys.include? 'DoofBot'
      if m.message[8..m.message.length].downcase.include? 'dootbot'
        m.reply('ヽ༼ຈل͜ຈ༽ﾉ IMPEACH ' + m.user.nick.upcase + ' ヽ༼ຈل͜ຈ༽ﾉ')
      else
        m.reply('ヽ༼ຈل͜ຈ༽ﾉ ' + m.message.upcase + ' ヽ༼ຈل͜ຈ༽ﾉ')
      end
    end
  end

end

dootbot.start