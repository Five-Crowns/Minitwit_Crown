require 'rspec'
require 'rest-client'
require 'json'

BASE_URL = 'http://localhost:5000'

def register(username, password, password2 = nil, email = nil)
  password2 ||= password
  email ||= "#{username}@example.com"
  RestClient.post(
    "#{BASE_URL}/register",
    { username: username, password: password, password2: password2, email: email },
    { follow_redirects: true }
  )
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def login(username, password)
  session = RestClient::Request.execute(
    method: :post,
    url: "#{BASE_URL}/login",
    payload: { username: username, password: password },
    follow_redirects: true
  )
  return session
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def register_and_login(username, password)
  register(username, password)
  login(username, password) # Print session data after login

end

def logout
  RestClient.get("#{BASE_URL}/logout", { follow_redirects: true })
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def add_message(text)
  response = RestClient.post("#{BASE_URL}/add_message", { text: text }, { follow_redirects: true })

  if text
    # Check that the message was recorded successfully
    expect(response.body).to include('Your message was recorded')
  end

  response
rescue RestClient::ExceptionWithResponse => e
  e.response
end



describe 'User Registration' do
  it 'registers a user successfully' do
    response = register('user1', 'default')
    expect(response.body).to include('You were successfully registered and can login now')
  end

  it 'prevents duplicate usernames' do
    register('user1', 'default')
    response = register('user1', 'default')
    expect(response.body).to include('The username is already taken')
  end

  it 'requires a username' do
    response = register('', 'default')
    expect(response.body).to include('You have to enter a username')
  end

  it 'requires a password' do
    response = register('meh', '')
    expect(response.body).to include('You have to enter a password')
  end

  it 'requires matching passwords' do
    response = register('meh', 'x', 'y')
    expect(response.body).to include('The two passwords do not match')
  end

  it 'requires a valid email' do
    response = register('meh', 'foo', nil, 'broken')
    expect(response.body).to include('You have to enter a valid email address')
  end
end

describe 'User Login & Logout' do
  it 'logs in and logs out successfully' do
    register('user1', 'default')
    response = login('user1', 'default')
    expect(response.body).to include('You were logged in')
    response = logout
    expect(response.body).to include('You were logged out')
  end

  it 'fails with wrong password' do
    register('user1', 'default')
    response = login('user1', 'wrongpassword')
    expect(response.body).to include('Invalid password')
  end

  it 'fails with non-existent username' do
    response = login('user2', 'wrongpassword')
    expect(response.body).to include('Invalid username')
  end
end


# this test fails because the add_message method does not work as intended
describe 'Message Posting' do
  it 'adds messages successfully' do
    register_and_login('foo', 'default')
    # Add messages but add message method does not work as intended
    add_message('test message 1')
    add_message('<test message 2>')
    response = RestClient.get(BASE_URL)
    puts "Add message response: #{response.body}"
    expect(response.body).to include('test message 1')
    expect(response.body).to include('<test message 2>')
  end
end

describe 'Login and register' do
  it 'logs in and logs out successfully' do
    response = register_and_login('user1', 'default')
    puts "Register and login response: #{response.body}"
    expect(response.body).to include('You were logged in')
    response = logout
    expect(response.body).to include('You were logged out')
    end
end
