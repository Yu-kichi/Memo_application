# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'

# ファイルの読み込みと書き込み
class MemoFile
  def self.open_json
    open('views/sample.json') do |io|
      JSON.load(io)
    end
  end

  def self.save_json(json_data)
    open('views/sample.json', 'w') do |io|
      JSON.dump(json_data, io)
    end
  end
end

get '/' do
  redirect '/memos'
end

get '/memos' do
  @title = 'トップページ'
  @date = Date.today
  @json_data = MemoFile.open_json
  erb :index
end

get '/memos/new' do
  erb :memo_new
end

get '/memos/:id' do |id|
  @id = id
  json_data = MemoFile.open_json

  json_data['memo'].each do |key|
    @data ||= key[@id]
  end

  erb :memo_show
end

post '/memos' do
  @title = params[:title]
  @body = params[:body]
  @date = Date.today
  json_data = MemoFile.open_json
  id = SecureRandom.uuid

  add_data = { id => { title: @title, body: @body, date: @date } }
  json_data['memo'].push(add_data)

  MemoFile.save_json(json_data)
  redirect '/memos'
end

get '/memos/:id/edit' do |id|
  @id = id
  @json_data = MemoFile.open_json

  @json_data['memo'].each do |key|
    @js ||= key[@id]
  end

  erb :memo_edit
end

patch '/memos/:id' do |id|
  @id = id
  @title = params[:title]
  @message = params[:message]
  @date = Date.today
  json_data = MemoFile.open_json
  edit_data = { @id => { title: @title, body: @message, date: @date } }

  json_data['memo'].each do |data|
    data.each do |key, _value| # ここのvalueはないとエラーになる
      next unless key == @id.to_s

      data.merge!(edit_data) do |_key, _old_value, new_value|
        new_value
      end
    end
  end

  MemoFile.save_json(json_data)

  redirect '/memos'
end

delete '/memos/:id' do |id|
  @id = id
  json_data = MemoFile.open_json

  json_data['memo'] = json_data['memo'].each do |n|
    n.delete_if { |key| key == @id }
  end

  MemoFile.save_json(json_data)

  redirect '/memos'
end
