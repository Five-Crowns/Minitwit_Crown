require 'selenium-webdriver'
require 'rspec'

URL = 'http://localhost:5000'.freeze

RSpec.configure do |config|
  config.before(:each) do
    options = Selenium::WebDriver::Firefox::Options.new
    # options.add_argument('-headless')

    @driver = Selenium::WebDriver.for :firefox, options: options
    @driver.manage.timeouts.implicit_wait = 10
    @driver.navigate.to URL
  end

  config.after(:each) do
    # Teardown code for every test
    @driver.quit
  end
end

def register(username, password, password2 = nil, email = nil)
  password2 ||= password
  email ||= "#{username}@example.com"

  @driver.find_element(name: 'username').send_keys(username)
  @driver.find_element(name: 'email').send_keys(email)
  @driver.find_element(name: 'password').send_keys(password)
  @driver.find_element(name: 'password2').send_keys(password2)

  @driver.find_element(xpath: "//input[@value='Sign Up']").click
end

describe 'Homepage' do
  it 'includes MiniTwit in the title' do
    title = @driver.title
    expect(title).to include('MiniTwit')
  end
  it 'has links to the public timeline, sign up, and sign in' do
    timeline_btn = @driver.find_element(partial_link_text: 'public timeline')
    expect(timeline_btn).not_to be_nil

    signup_btn = @driver.find_element(partial_link_text: 'sign up')
    expect(signup_btn).not_to be_nil

    signin_btn = @driver.find_element(partial_link_text: 'sign in')
    expect(signin_btn).not_to be_nil
  end
end

describe 'Sign Up' do
  before do
    signup_btn = @driver.find_element(partial_link_text: 'sign up')
    signup_btn.click
  end
  it "let's you log in normally" do
    register('normal-user', 'Pa$$w0rd')
    text = @driver.find_element(class: 'success').text
    expect(text).not_to include('successfully registered')
  end
end