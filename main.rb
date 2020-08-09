# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'dotenv'

Dotenv.load

class MemoDatebase
  def self.open
    settings = { dbname: ENV['DB_NAME'], user: ENV['LOGIN_NAME'], password: ENV['LOGIN_PASSWORD'] }
    conn = PG.connect(settings)
    yield conn
  rescue PG::Error => e
    puts e.message
  ensure
    conn&.close
  end
end

class MemoDatebaseQuery
  def self.find_all
    MemoDatebase.open do |conn|
      conn.exec('SELECT * FROM memo ORDER BY updated_at DESC')
    end
  end

  def self.find_by_id(id)
    MemoDatebase.open do |conn|
      conn.prepare('find', 'SELECT * FROM memo WHERE memo_id=$1;')
      conn.exec_prepared('find', [id])
    end
  end

  def self.create(title, body)
    time = Time.now
    MemoDatebase.open do |conn|
      conn.prepare('new', 'INSERT INTO memo (memo_id,memo_title,memo_body,created_at,updated_at)values (DEFAULT, $1, $2, $3, $4)')
      conn.exec_prepared('new', [title, body, time, time])
    end
  end

  def self.update(title, body, id)
    time = Time.now
    MemoDatebase.open do |conn|
      conn.prepare('update', 'UPDATE memo SET memo_title = $1, memo_body = $2, updated_at = $3 WHERE memo_id = $4;')
      conn.exec_prepared('update', [title, body, time, id])
    end
  end

  def self.delete(id)
    MemoDatebase.open do |conn|
      conn.prepare('delete', 'DELETE FROM memo WHERE memo_id = $1;')
      conn.exec_prepared('delete', [id])
    end
  end
end

helpers do
  def convert_to_br(body)
    body.gsub(/\r\n|\n|\r/, '<br>')
  end
end

get '/' do
  redirect '/memos'
end

get '/memos' do
  @memos = MemoDatebaseQuery.find_all
  erb :index
end

get '/memos/new' do
  erb :memo_new
end

get '/memos/:id' do |id|
  @id = id
  @memo = MemoDatebaseQuery.find_by_id(@id)&.first
  pass if @memo.nil?
  erb(:memo_show)
end

post '/memos' do
  MemoDatebaseQuery.create(params[:title], params[:body])
  redirect '/memos'
end

get '/memos/:id/edit' do |id|
  @id = id
  @memo = MemoDatebaseQuery.find_by_id(@id)&.first
  pass if @memo.nil?
  erb(:memo_edit)
end

patch '/memos/:id' do |id|
  MemoDatebaseQuery.update(params[:title], params[:body], id)
  redirect '/memos'
end

delete '/memos/:id' do |id|
  MemoDatebaseQuery.delete(id)
  redirect '/memos'
end
