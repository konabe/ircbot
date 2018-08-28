#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'cinch'

$rooms = {}

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "aochd.jp"
    c.channels = ["#SHOBOT"]
    c.nick = "shobot"
    c.realname = "shobot"
    c.user = "shobot"
  end

  on :message, /@sho ping/ do |m|
    m.reply "pong"
  end

  on :message, /@sho help/ do |m|
    m.reply "create [name]: 部屋の作成, show: 部屋の一覧表示"
    m.reply "delete: 部屋の削除, force-delete: 部屋の強制削除"
  end

  on :message, /@sho create/ do |m|
    #TODO 他の部屋に入っている場合は弾く
    name = m.message.match(/@sho create (\w.*)/)
    if name.nil?
      m.reply "使用方法：@sho create [room name] (日本語未対応)"
      return
    end
    nick = m.user.nick
    room = {name: name[1], users: [m.user.nick]}
    $rooms[nick] = room
    m.reply "ホスト#{nick}が部屋[#{name[1]}] を建てました！"
  end
    
  on :message, /@sho show/ do |m|
    m.reply $rooms
  end

  on :message, /@sho delete/ do |m|
    nick = m.user.nick
    m.reply $rooms[nick]
    if $rooms.key?(nick)
      target_name = $rooms[nick][:name]
      $rooms.delete(nick)
      m.reply "ホスト #{nick}が部屋[#{target_name}]を消しました!"
    else
      m.reply "まだ部屋を立てていないのでコマンドが有効ではありません"
      return
    end
  end

  on :message, /@sho force-delete/ do |m|
    name = m.message.match(/@sho force-delete (\w.*)/)
    if name.nil?
      m.reply "使用方法：@sho force-delete [host name]"
      return
    end
    nick = m.user.nick
    name = name[1]
    target_name = $rooms[name][:name]
    $rooms.delete(name)
    m.reply "ユーザー#{nick}がホストが#{name}の部屋[#{target_name}]を消しました!"
  end

end

bot.start
