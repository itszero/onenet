#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'rack/coffee'
require 'json'

DATA = {}

class Onenet < Sinatra::Base
  set :public_folder, 'public'

  use Rack::Coffee,
    :root => 'public',
    :urls => ['/js']

  get '/css/app.css' do
    less :app
  end

  get '/' do
    haml :index
  end

  post '/deploy' do
    topo = JSON.parse(params[:data])
    (topo['nodes'] + topo['switches']).each_with_index do |e, i|
      e['ip'] = "10.0.1.#{i + 1}"
    end

    DATA[0xff] = { :status => 'running', :logs => [] }
    Thread.new {
      File.open("../control/topo.js", 'w') { |f| f.write topo.to_json }
      f = IO.popen("cd ../control; cat topo.js | python -u oversee.py")

      id = 0
      loop do
        line = f.readline() rescue break
        break if line.nil?
        print line
        if line =~ /^>> log:/
          log = JSON.parse(line[8..-1])
          log['id'] = id
          DATA[0xff][:logs].push(log)
        else
          DATA[0xff][:logs].push({
            :host => 'system',
            :id => id,
            :log => line
          })
        end
        id += 1
      end
      DATA[0xff][:status] = 'done'
    }

    {:deploy_id => 0xff}.to_json
  end

  get '/status/:id' do
    DATA[params[:id].to_i].to_json
  end
end
