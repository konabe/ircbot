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

# 指定したユーザーがいる部屋のホスト名のリストを返却
# いなければ空
def find_rooms(t_user)
  hosts = []
  $rooms.each do |key, value|
    flag = false
    $rooms[key][:users].each do |user|
      flag = true if user == t_user
    end
    hosts << key if flag
  end
  return hosts
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "aochd.jp"
    c.channels = channel_list
    c.nick = "shobot"
    c.realname = "shobot"
    c.user = "shobot"
  end

  # 応答テスト
  on :message, /@sho ping/ do |m|
    bot_reply "pong"
  end

  # ヘルプ
  on :message, /@sho help/ do |m|
    str = "基本操作は @sho command (以下、コマンドリスト), "
    str += "create [roomname]: 部屋の作成, list: 部屋の一覧表示, "
    str += "status: ユーザーの現在の状況を表示, "
    str += "join [hostname]: 部屋の入場, exit: 部屋の退場, "
    str += "delete: 部屋の削除, force-delete [hostname]: 部屋の強制削除"
    bot_reply m, str
  end

  # 部屋の作成
  on :message, /@sho create/ do |m|
    nick = m.user.nick
    if $rooms.key?(nick) or find_rooms(nick).empty?
      bot_reply m, "すでにいずれかの部屋に参加しています"
      return
    end
    roomname = m.message.match(/@sho create (.*)/)
    if roomname.nil?
      bot_reply m, "command error -> @sho create [roomname]"
    else
      room = {name: roomname[1], users: []}
      $rooms[nick] = room
      bot_reply m, "ホスト#{nick}が部屋[#{name[1]}]を立てました"
    end
  end

  # 部屋の一覧表示
  on :message, /@sho list/ do |m|
    if $rooms.empty?
      bot_reply m, "現在部屋はありません"
    else
      $rooms.each do |key, value|
        bot_reply m, "#{value[:name]}[#{key}] 現在の人数[#{value[:users].length+1}]"
      end
    end
  end

  # 部屋の削除
  on :message, /@sho delete/ do |m|
    if $rooms.key?(nick)
      nick = m.user.nick
      roomname = $rooms[nick][:name]
      $rooms.delete(nick)
      bot_reply m, "ホスト#{nick}が部屋[]#{roomname}]を解散しました"
    else
      bot_reply m, "error -> 解散する部屋はありません"
      return
    end
  end

  # 部屋の強制削除
  on :message, /@sho force-delete/ do |m|
    hostname = m.message.match(/@sho force-delete (\w.*)/)
    if hostname.nil?
      bot_reply m, "command error -> @sho force-delete [*hostname]"
    else
      nick = m.user.nick
      targetname = $rooms[hostname[1]][:name]
      $rooms.delete(hostname[1])
      bot_reply m, "ユーザー#{nick}がホスト#{hostname[1]}の部屋[#{targetname}]を強制削除しました"
    end
  end

  # 部屋の参加
  on :message, /@sho join/ do |m|
    nick = m.user.nick
    if $rooms.key?(nick) or not find_rooms(nick).empty?
      bot_reply m, "すでにいずれかの部屋に参加しています"
      return
    end
    hostname = m.message.match(/@sho join (\w.*)/)
    if $rooms.key?(hostname[1])
      $rooms[hostname[1]][:users] << m.user.nick
      bot_reply m, "ユーザー#{nick}が部屋[#{$rooms[hostname[1][:name]]}]に入りました"
    else
      bot_reply m, "そのようなホストが立てている部屋は存在しません"
    end
  end

  # 部屋の退場
  on :message, /@sho exit/ do |m|
    nick = m.user.nick
    exit_hosts = find_rooms(nick)
    if exit_hosts.empty?
      bot_reply m, "どの部屋にも参加していません"
      return
    end
    str = "ユーザー#{nick}がホスト"
    exit_hosts.each do |host|
      str += host
      str += " "
    end
    str += "の部屋を退場しました"
    bot_reply m, str
  end

  # 現在の状況を表示
  on :message, /@sho status/ do |m|
    nick = m.user.nick
    # ホストの場合
    if $rooms.key?(nick)
      str = "#{nick}がホストの部屋[#{$rooms[nick][:name]}]の参加者は"
      $rooms[nick][:users].each do |user|
        str += user
        str += " "
      end
    # 参加者の場合
    else
      str = "ユーザー#{nick}は"
      roomnames = find_rooms(nick)
      if roomnames.empty?
        str += "どこにも所属していません"
        bot_reply m, str
        return
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
