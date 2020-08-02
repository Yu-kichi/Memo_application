# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "pg"
# ファイルの読み込みと書き込み
class MemoDatebase
  def self.open
    settings = { dbname: "memo2" }
    conn = PG.connect(settings)
    yield conn
    rescue PG::Error => e
      puts e.message
  ensure
    conn.close if conn
  end
end

class MemoDbQuery
  def self.find_all
    MemoDatebase.open do |conn|
      conn.exec("SELECT * FROM Memo ORDER BY updated_at DESC")
    end
  end

  def self.find_id(id)
    MemoDatebase.open do |conn|
      conn.prepare("find", "SELECT * FROM memo WHERE memo_id=$1;")
      conn.exec_prepared("find", [id])
    end
  end

  def self.create(title, body, time)
    MemoDatebase.open do |conn|
      conn.prepare("new", "INSERT INTO Memo (memo_id,memo_title,memo_body,created_at,updated_at)values (DEFAULT, $1, $2,$3, $4)")
      conn.exec_prepared("new", [ title, body, time, time])
    end
  end

  def self.edit(title, body, time, id)
    MemoDatebase.open do |conn|
      conn.prepare("update", "UPDATE Memo SET memo_title = $1, memo_body = $2, updated_at = $3 WHERE memo_id = $4;")
      conn.exec_prepared("update", [title, body, time, id])
    end
  end

  def self.delete(id)
    MemoDatebase.open do |conn|
      conn.prepare("delete", "DELETE FROM memo WHERE memo_id = $1;")
      conn.exec_prepared("delete", [id])
    end
  end
end

helpers do
  def convert_to_br(body)
    body.gsub(/\r/, "<br>")
  end
end

get "/" do
  redirect "/memos"
end

get "/memos" do
  @results= MemoDbQuery.find_all
  erb :index
end

get "/memos/new" do
  erb :memo_new
end

get "/memos/:id" do |id|
  @id = id
  @result= MemoDbQuery.find_id(@id)
  erb :memo_show
end

post "/memos" do
  time = Time.now
  MemoDbQuery.create(params[:title], params[:body], time)
  redirect "/memos"
end

get "/memos/:id/edit" do |id|
  @id = id
  @result= MemoDbQuery.find_id(@id)
  erb :memo_edit
end

patch "/memos/:id" do |id|
  @id = id
  time = Time.now
  MemoDbQuery.edit(params[:title], params[:body], time, @id)
  redirect "/memos"
end

delete "/memos/:id" do |id|
  @id = id
  MemoDbQuery.delete(@id)
  redirect "/memos"
end
