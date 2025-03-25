require "rspec"
require "rest-client"
require "json"
require "simplecov"

SimpleCov.start do
  enable_coverage :branch            # Enable branch coverage (for deeper analysis)
  add_filter "/spec/"                # Exclude the spec files from coverage report
  coverage_dir("/app/coverage")      # Save coverage reports to a specific directory (e.g., inside Docker container)
  add_group "Test", "Test" # This adds the 'Test' folder to the coverage report
end
BASE_URL = "http://localhost:5000"


def register(username, password, password2 = nil, email = nil)
  password2 ||= password
  email ||= "#{username}@example.com"
  RestClient.post(
    "#{BASE_URL}/register",
    {username: username, password: password, password2: password2, email: email},
    {follow_redirects: true}
  )
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def login(username, password)
  response = RestClient::Request.execute(
    method: :post,
    url: "#{BASE_URL}/login",
    payload: {username: username, password: password},
    follow_redirects: true
  )
  cookies = response.cookies # Capture session cookies
  [response, cookies]
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def register_and_login(username, password)
  register(username, password)
  response, cookies = login(username, password) # Capture session cookies
  [response, cookies]
end

def logout
  RestClient.get("#{BASE_URL}/logout", {follow_redirects: true})
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def add_message(text, cookies)
  response = RestClient.post(
    "#{BASE_URL}/add_message",
    {text: text},
    {cookies: cookies, follow_redirects: true}
  )

  if text
    expect(response.body).to include("Your message was recorded")
  end

  response
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def follow_user(username, cookies)
  RestClient.get("#{BASE_URL}/#{username}/follow", {cookies: cookies, follow_redirects: true})
  # expect(response.body).to include("You are now following \"#{username}\"")
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def unfollow_user(username, cookies)
  RestClient.get("#{BASE_URL}/#{username}/unfollow", {cookies: cookies, follow_redirects: true})
  # expect(response.body).to include("You are no longer following \"#{username}\"")
rescue RestClient::ExceptionWithResponse => e
  e.response
end

describe "User Registration" do
  it "registers a user successfully" do
    response = register("user1", "default")
    expect(response.body).to include("You were successfully registered and can login now")
  end

  it "prevents duplicate usernames" do
    register("user1", "default")
    response = register("user1", "default")
    expect(response.body).to include("The username is already taken")
  end

  it "requires a username" do
    response = register("", "default")
    expect(response.body).to include("You have to enter a username")
  end

  it "requires a password" do
    response = register("meh", "")
    expect(response.body).to include("You have to enter a password")
  end

  it "requires matching passwords" do
    response = register("meh", "x", "y")
    expect(response.body).to include("The two passwords do not match")
  end

  it "requires a valid email" do
    response = register("meh", "foo", nil, "broken")
    expect(response.body).to include("You have to enter a valid email address")
  end
end

describe "User Login & Logout" do
  it "logs in and logs out successfully" do
    register("user1", "default")
    response, _ = login("user1", "default")
    expect(response.body).to include("You were logged in")
    response = logout
    expect(response.body).to include("You were logged out")
  end

  it "fails with wrong password" do
    register("user1", "default")
    response, _ = login("user1", "wrongpassword")
    expect(response.body).to include("Invalid password")
  end

  it "fails with non-existent username" do
    response, _ = login("user2", "wrongpassword")
    expect(response.body).to include("Invalid username")
  end
end

# this test fails because the add_message method does not work as intended
describe "Message Posting" do
  it "adds messages successfully" do
    _, cookies = register_and_login("foo", "default")
    add_message("test message 1", cookies)
    add_message("<test message 2>", cookies)

    response = RestClient.get(BASE_URL, {cookies: cookies}) # Ensure session is maintained

    expect(response.body).to include("test message 1")
    expect(response.body).to include("&lt;test message 2&gt;")
  end
end

describe "Login and register" do
  it "logs in and logs out successfully" do
    response, _ = register_and_login("foo", "default")

    expect(response.body).to include("You were logged in")
    response = logout
    expect(response.body).to include("You were logged out")
  end
end

describe "Follow and unfollow" do
  it "follow worls" do
    register("bar", "default")
    _, cookies = register_and_login("foo", "default")
    response = follow_user("bar", cookies)
    expect(response.body).to include('You are now following "bar"')
  end
  it "unfollow works" do
    register("bar", "default")
    _, cookies = register_and_login("foo", "default")
    follow_user("bar", cookies)
    response = unfollow_user("bar", cookies)
    expect(response.body).to include('You are no longer following "bar"')
  end
end

describe "Timeline" do
  it "tests timelines" do
    _, cookies = register_and_login("foo", "default")
    add_message("the message by foo", cookies)

    _, cookies = register_and_login("bar", "default")
    add_message("the message by bar", cookies)

    sleep 2

    response = RestClient.get("#{BASE_URL}/public", {cookies: cookies})

    expect(response.body).to include("the message by foo")
    expect(response.body).to include("the message by bar")

    # fails following the user dosent display tweets of whom you are following
    follow_user("foo", cookies)
    response = RestClient.get("#{BASE_URL}/", {cookies: cookies})
    expect(response.body).to include("the message by foo")
    expect(response.body).to include("the message by bar")

    response = RestClient.get("#{BASE_URL}/bar", {cookies: cookies})
    expect(response.body).to include("the message by bar")
    expect(response.body).not_to include("the message by foo")

    response = RestClient.get("#{BASE_URL}/foo", {cookies: cookies})
    expect(response.body).to include("the message by foo")
    expect(response.body).not_to include("the message by bar")

    unfollow_user("foo", cookies)
    response = RestClient.get("#{BASE_URL}/", {cookies: cookies})
    expect(response.body).to include("the message by bar")
    expect(response.body).not_to include("the message by foo")
  end
end
