#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/token_store'
require "google/cloud/firestore"
require 'sinatra'

class FirestoreTokenStore < Google::Auth::TokenStore
  def initialize
    @firestore = Google::Cloud::Firestore.new
    @doc = @firestore.doc('google/auth')
  end

  def load(id)
    a = @doc.get
    if a.exists?
      a[id]
    else
      nil
    end
  end

  def store(id, token)
    @doc.set(id => token)
  end

  def delete(id)
    raise NotImplementedError
  end
end

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Drive API Ruby Quickstart'
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE

def user_id
  'default'
end

def create_authorizer
  client_id = Google::Auth::ClientId.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'])
  token_store = FirestoreTokenStore.new
  Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
end

get '/' do
  authorizer = create_authorizer
  credentials = authorizer.get_credentials(user_id)

  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
<<HTML
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Hello Google Drive</title>
</head>
<body>
  <a href="#{url}" target="_blank">認証</a>を行って、表示されたコードを送信してください
  <form action="/code" method="POST">
    <label for="code">Code:</label>
    <input type="text" name="code">
    <input type="submit">
  </form>
</body>
</html>
HTML
  else
    drive = Google::Apis::DriveV3::DriveService.new
    drive.client_options.application_name = APPLICATION_NAME
    drive.authorization = credentials
    drive.list_files.files.map(&:name).to_s
<<HTML
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Hello Google Drive</title>
</head>
<body>
  <ul>
    #{drive.list_files.files.map { |f| '<li>' + f.name + '</li>' }.join}
  </ul>
</body>
</html>
HTML
  end
end

post '/code' do
  code = params['code']
  create_authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
  redirect to('/')
end
