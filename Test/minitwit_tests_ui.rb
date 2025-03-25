require 'spec_helper'
require 'selenium-webdriver'
require 'pg'

GUI_URL = "http://localhost:5000/register"
DB_URL = "mongodb://localhost:27017/test"

describe "User Registration Tests" do
  def register_user_via_gui(driver, data)
    driver.navigate.to(GUI_URL)

    # Wait until elements with class 'actions' are present
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    wait.until { driver.find_elements(class: 'actions').any? }

    input_fields = driver.find_elements(tag_name: 'input')

    # Fill in input fields with provided data
    data.each_with_index do |value, index|
      input_fields[index].send_keys(value)
    end

    # Submit the form by sending RETURN to the 5th input field (index 4)
    input_fields[4].send_keys(:return)

    # Wait for flash messages to appear and return them
    wait.until { driver.find_elements(class: 'flashes').any? }
    driver.find_elements(class: 'flashes')
  end

  def get_user_by_name(db_client, name)
    db_client.exec_params("SELECT * FROM users WHERE username = $1", [name]).first
  end

  it 'registers user via GUI and verifies success message' do
    options = Selenium::WebDriver::Firefox::Options.new
    options.add_argument('-headless')

    driver = Selenium::WebDriver.for(:firefox, options: options)

    begin
      flash_elements = register_user_via_gui(driver, ["Me", "me@some.where", "secure123", "secure123"])
      expect(flash_elements.first.text).to eq("You were successfully registered and can login now")
    ensure
      driver.quit
    end

    # Database cleanup
    db_client = Mongo::Client.new(DB_URL, server_selection_timeout: 5)
    db_client[:user].delete_one(username: "Me")
  end

  it 'registers user and verifies database entry' do
    options = Selenium::WebDriver::Firefox::Options.new
    # options.add_argument('-headless')

    driver = Selenium::WebDriver.for(:firefox, options: options)
    db_client = PG.connect(
      host: 'localhost',
      dbname: 'test',
      user: 'your_user',
      password: 'your_password'
    )

    begin
      # Verify user doesn't exist initially
      expect(get_user_by_name(db_client, "Me")).to be_nil

      # Perform registration
      flash_elements = register_user_via_gui(driver, ["Me", "me@some.where", "secure123", "secure123"])
      expect(flash_elements.first.text).to eq("You were successfully registered and can login now")

      # Verify user exists in database
      user = get_user_by_name(db_client, "Me")
      expect(user[:username]).to eq("Me")
    ensure
      driver.quit
      # Database cleanup
      db_client.exec_params("DELETE FROM users WHERE username = $1", ["Me"])
      db_client.close
    end
  end
end