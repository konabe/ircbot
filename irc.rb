#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'cinch'

$rooms = {}

# 開発用のときは公開しない
channel_list = ["#SHOBOT", "#AOCHD"]
if ARGV.size == 1 and ARGV[0] == "d"
  channel_list = ["#SHOBOT"]
end

BOT_EMOJI = 0x1F320.chr("UTF-8")  # shooting star

# 返事をする
def bot_reply(m, str)
  m.reply("#{BOT_EMOJI} #{str}")
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "aochd.jp"
    c.channels = channel_list
    c.nick = "shobot"
    c.realname = "shobot"
    c.user = "shobot"
  end

  on :message, /@sho ping/ do |m|
    bot_reply "pong"
  end

  on :message, /@sho help/ do |m|
    str = "基本操作は @sho command (以下、コマンドリスト), "
    str += "create [roomname]: 部屋の作成, list: 部屋の一覧表示, "
    str += "status: ユーザーの現在の状況を表示, "
    str += "join [hostname]: 部屋の入場, exit: 部屋の退場, "
    str += "delete: 部屋の削除, force-delete [hostname]: 部屋の強制削除"
    bot_reply m, str
  end

  on :message, /@sho create/ do |m|
    #TODO 他の部屋に入っている場合は弾く
    name = m.message.match(/@sho create (.*)/)
    if name.nil?
      bot_reply m, "command error -> @sho create [roomname]"
    else
      nick = m.user.nick
      room = {name: name[1], users: []}
      $rooms[nick] = room
      bot_reply m, "ホスト\"#{nick}\"が部屋\"#{name[1]}\"を立てました"
    end
  end

  on :message, /@sho list/ do |m|
    if $rooms.empty?
      bot_reply m, "現在部屋はありません"
      return
    end
    $rooms.each do |key, value|
      bot_reply m, "#{value[:name]}[#{key}] 現在の人数[#{value[:users].length+1}]"
    end
  end

  on :message, /@sho delete/ do |m|
    nick = m.user.nick
    m.reply $rooms[nick]
    if $rooms.key?(nick)
      target_name = $rooms[nick][:name]
      $rooms.delete(nick)
      bot_reply m, "ホスト#{nick}が部屋[#{target_name}]を解散しました"
    else
      bot_reply m, "error -> you don't have any room yet."
      return
    end
  end

  on :message, /@sho force-delete/ do |m|
    name = m.message.match(/@sho force-delete (\w.*)/)
    if name.nil?
      bot_reply m, "command error -> @sho force-delete [*hostname]"
      return
    end
    nick = m.user.nick
    name = name[1]
    target_name = $rooms[name][:name]
    $rooms.delete(name)
    bot_reply m, "ユーザー#{nick}がホスト#{name}の部屋[#{target_name}]を強制削除しました"
  end

  on :message, /@sho join/ do |m|
    name = m.message.match(/@sho join (\w.*)/)
    $rooms[name[1]][:users] << m.user.nick
    bot_reply m, "ユーザー#{m.user.nick}がホスト#{name[1]}の部屋に入りました"
  end

  on :message, /@sho exit/ do |m|
    exit_hosts = []
    $rooms.each do |key, value|
      flag = false
      $rooms[key][:users].each do |user|
        if user == m.user.nick
          flag = true
        end
      end
      if flag
        $rooms[key][:users].delete(m.user.nick)
        exit_hosts << key
      end
    end
    str = "ユーザー#{m.user.nick}がホスト"
    exit_hosts.each do |host|
      str += host
      str += " "
    end
    str += "の部屋を退場しました"
    bot_reply m, str
  end

  on :message, /@sho status/ do |m|
    if $rooms.key?(m.user.nick)
      str = "#{$rooms[m.user.nick][:name]}[#{m.user.nick}] "
      $rooms[m.user.nick][:users].each do |user|
        str += user
        str += " "
      end
    else
      roomnames = []
      str = "ユーザー#{m.user.nick}は"
      $rooms.each do |key, value|
        flag = false
        $rooms[key][:users].each do |user|
          if user == m.user.nick
            flag = true
          end
        end
        if flag
          roomnames << $rooms[key][:name]
        end
      end
      roomnames.each do |host|
        str += host
        str += " "
      end
      str += "に入っています"
    end
    bot_reply m, str
  end

end

bot.start
