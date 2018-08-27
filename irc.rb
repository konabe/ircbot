#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "aochd.jp"
    c.channels = ["#AOCHD"]
    c.nick = "shobot"
    c.realname = "shobot"
    c.user = "shobot"
  end

  on :message, /test/ do |m|
    m.reply "testdesune"
  end
    
end

bot.start
