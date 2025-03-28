require 'selenium-webdriver'
require 'rspec'

URL = 'http://localhost:5000'.freeze

RSpec.configure do |config|
  config.before(:each) do
    options = Selenium::WebDriver::Firefox::Options.new
    # options.add_argument('-headless')

    @driver = Selenium::WebDriver.for :firefox, options: options
    @driver.manage.timeouts.implicit_wait = 10
    goto_home
  end

  config.after(:each) do
    # Teardown code for every test
    @driver.quit
  end
end

def goto(url)
  @driver.navigate.to(URL + url)
end

def goto_home
  goto ""
end

def goto_public
  goto "/public"
end

def goto_timeline(username)
  goto "/#{username}"
end

def link(text)
  @driver.find_element(partial_link_text: text)
end

def input_field(field_name, value)
  @driver.find_element(name: field_name).send_keys(value)
end

def submit(value)
  @driver.find_element(xpath: "//input[@value='#{value}']").click
end

def find_by_class(class_name)
  @driver.find_element(class: class_name)
end

def assert_success(message)
  text = find_by_class('success').text
  expect(text).to include(message)
end

def assert_error(message)
  text = find_by_class('error').text
  expect(text).to include(message)
end

def assert_message(message)
  text = find_by_class('messages').text
  expect(text).to include(message)
end

def assert_no_message(message)
  text = find_by_class('messages').text
  expect(text).not_to include(message)
end

def register(username, password, password2 = nil, email = nil)
  goto_home
  link('sign up').click

  password2 ||= password
  email ||= "#{username}@example.com"

  input_field('username', username)
  input_field('email', email)
  input_field('password', password)
  input_field('password2', password2)

  submit('Sign Up')
end

def login(username, password)
  goto_home
  link('sign in').click

  input_field('username', username)
  input_field('password', password)

  submit('Sign In')
end

def logout
  goto_home
  link('sign out').click
end

def register_and_login(username, password)
  register(username, password)
  login(username, password)
end

def add_message(message)
  input_field('text', message)
  submit('Share')
end

def follow_user(username)
  goto("/#{username}/follow")
end

def unfollow_user(username)
  goto("/#{username}/unfollow")
end

describe 'Homepage' do
  it 'includes MiniTwit in the title' do
    expect(@driver.title).to include('MiniTwit')
  end

  it 'has links to the public timeline, sign up, and sign in' do
    expect(link('public timeline')).not_to be_nil
    expect(link('sign up')).not_to be_nil
    expect(link('sign in')).not_to be_nil
  end
end

describe 'User Registration' do
  it 'registers a user successfully' do
    register("user1", "default")
    assert_success('successfully registered')
  end

  it 'prevents duplicate usernames' do
    register("user1", "default")
    assert_error('username is already taken')
  end

  it "requires a username" do
    register("", "default")
    assert_error("You have to enter a username")
  end

  it "requires a password" do
    register("meh", "")
    assert_error("You have to enter a password")
  end

  it "requires matching passwords" do
    register("meh", "x", "y")
    assert_error("The two passwords do not match")
  end

  it "requires a valid email" do
    register("meh", "foo", nil, "broken")
    assert_error("You have to enter a valid email address")
  end
end

describe "User Login & Logout" do
  it "logs in and logs out successfully" do
    login("user1", "default")
    assert_success("You were logged in")

    logout
    assert_success("You were logged out")
  end

  it "fails with wrong password" do
    login("user1", "wrongpassword")
    assert_error("Invalid password")
  end

  it "fails with non-existent username" do
    login("user2", "wrongpassword")
    assert_error("Invalid username")
  end
end

describe "Message Posting" do
  it "adds messages successfully" do
    register_and_login("foo", "default")
    add_message("test message 1")
    add_message("<test message 2>")

    assert_message("test message 1")
    assert_message("<test message 2>")
  end
end

describe "Login and register" do
  it "logs in and logs out successfully" do
    register_and_login("foo", "default")
    assert_success("You were logged in")

    logout
    assert_success("You were logged out")
  end
end

describe "Follow and unfollow" do
  it "follow works" do
    register("bar", "default")
    register_and_login("foo", "default")
    follow_user("bar")
    assert_success('You are now following "bar"')
  end

  it "unfollow works" do
    register("bar", "default")
    register_and_login("foo", "default")
    follow_user("bar")
    unfollow_user("bar")
    assert_success('You are no longer following "bar"')
  end
end

describe "Timeline" do
  it "tests timelines" do
    register_and_login("foo2", "default")
    add_message("the message by foo2")

    logout

    register_and_login("bar2", "default")
    add_message("the message by bar2")

    sleep 2

    goto_public

    assert_message("the message by foo2")
    assert_message("the message by bar2")

    follow_user("foo2")

    goto_home
    assert_message("the message by foo2")
    assert_message("the message by bar2")

    goto_timeline("bar2")
    assert_message("the message by bar2")
    assert_no_message("the message by foo2")

    goto_timeline("foo2")
    assert_message("the message by foo2")
    assert_no_message("the message by bar2")

    unfollow_user("foo2")

    goto_home
    assert_message("the message by bar2")
    assert_no_message("the message by foo2")
  end
end