import os
import json
import base64
import psycopg2  # Replacement with sqlite3
import requests
import os
import subprocess
from pathlib import Path
from contextlib import closing
from dotenv import load_dotenv  # Add this to load environment variables

# Load environment variables
load_dotenv()

BASE_URL = 'http://localhost:5000/api'
USERNAME = 'simulator'
PWD = 'super_safe!'
CREDENTIALS = ':'.join([USERNAME, PWD]).encode('ascii')
ENCODED_CREDENTIALS = base64.b64encode(CREDENTIALS).decode()
HEADERS = {'Connection': 'close',
           'Content-Type': 'application/json',
           f'Authorization': f'Basic {ENCODED_CREDENTIALS}'}

# # PostgreSQL connection parameters
# DB_PARAMS = {
#     'dbname': os.getenv('POSTGRES_DB', 'minitwit_development'),
#     'user': os.getenv('POSTGRES_USER', 'postgres'),
#     'password': os.getenv('POSTGRES_PASSWORD', 'placeholder'),
#     'host': os.getenv('POSTGRES_HOST', 'localhost'),
#     'port': os.getenv('POST_PORT', '5432')
# }

# # Set Rails environment to test
# os.environ["RAILS_ENV"] = "test"

# def init_db():
#     """Initialize the database using Rails' rake tasks."""
#     try:
#         subprocess.run(["rake", "db:reset"], check=True)
#         print("Database initialized successfully using Rails migrations.")
#     except subprocess.CalledProcessError as e:
#         print(f"Error initializing the database: {e}")
#         raise


# Initialize the database
# init_db()

def test_latest():
    # post something to update LATEST
    url = f"{BASE_URL}/register"
    data = {'username': 'test', 'email': 'test@test', 'pwd': 'foo'}
    params = {'latest': 1337}
    response = requests.post(url, data=json.dumps(data),
                             params=params, headers=HEADERS)
    assert response.ok

    # verify that latest was updated
    url = f'{BASE_URL}/latest'
    response = requests.get(url, headers=HEADERS)
    assert response.ok
    assert response.json()['latest'] == 1337


def test_register():
    username = 'a'
    email = 'a@a.a'
    pwd = 'a'
    data = {'username': username, 'email': email, 'pwd': pwd}
    params = {'latest': 1}
    response = requests.post(f'{BASE_URL}/register',
                             data=json.dumps(data), headers=HEADERS, params=params)
    assert response.ok
    # TODO: add another assertion that it is really there

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 1


def test_create_msg():
    username = 'a'
    data = {'content': 'Blub!'}
    url = f'{BASE_URL}/msgs/{username}'
    params = {'latest': 2}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 2


def test_get_latest_user_msgs():
    username = 'a'

    query = {'no': 20, 'latest': 3}
    url = f'{BASE_URL}/msgs/{username}'
    response = requests.get(url, headers=HEADERS, params=query)
    assert response.status_code == 200

    got_it_earlier = False
    for msg in response.json():
        if msg['content'] == 'Blub!' and msg['user'] == username:
            got_it_earlier = True

    assert got_it_earlier

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 3


def test_get_latest_msgs():
    username = 'a'
    query = {'no': 20, 'latest': 4}
    url = f'{BASE_URL}/msgs'
    response = requests.get(url, headers=HEADERS, params=query)
    assert response.status_code == 200

    got_it_earlier = False
    for msg in response.json():
        if msg['content'] == 'Blub!' and msg['user'] == username:
            got_it_earlier = True

    assert got_it_earlier

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 4


def test_register_b():
    username = 'b'
    email = 'b@b.b'
    pwd = 'b'
    data = {'username': username, 'email': email, 'pwd': pwd}
    params = {'latest': 5}
    response = requests.post(f'{BASE_URL}/register', data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok
    # TODO: add another assertion that it is really there

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 5


def test_register_c():
    username = 'c'
    email = 'c@c.c'
    pwd = 'c'
    data = {'username': username, 'email': email, 'pwd': pwd}
    params = {'latest': 6}
    response = requests.post(f'{BASE_URL}/register', data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 6


def test_follow_user():
    username = 'a'
    url = f'{BASE_URL}/fllws/{username}'
    data = {'follow': 'b'}
    params = {'latest': 7}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    data = {'follow': 'c'}
    params = {'latest': 8}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    query = {'no': 20, 'latest': 9}
    response = requests.get(url, headers=HEADERS, params=query)
    assert response.ok

    json_data = response.json()
    assert "b" in json_data["follows"]
    assert "c" in json_data["follows"]

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 9


def test_a_unfollows_b():
    username = 'a'
    url = f'{BASE_URL}/fllws/{username}'

    #  first send unfollow command
    data = {'unfollow': 'b'}
    params = {'latest': 10}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    # then verify that b is no longer in follows list
    query = {'no': 20, 'latest': 11}
    response = requests.get(url, params=query, headers=HEADERS)
    assert response.ok
    assert 'b' not in response.json()['follows']

    # verify that latest was updated
    response = requests.get(f'{BASE_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 11

# def test_deliberate_failure():
#     """This test is designed to fail to test the CI/CD pipeline"""
#     # This assertion will always fail
#     assert False, "This test is deliberately failing to test the CI pipeline"