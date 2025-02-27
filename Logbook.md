### This is a simple log
- The purpose of this log book is to keep track of changes to the program.
- It is required to list your initials and datetime of when the changes occurred.

### Changes Should be listed below here in descending order.

---

Author: (initials), <(mail)> <br>
Date: (year), (day of the week) (month) (day), (time) (timezone)

(header/one-line summary)

(changes)

---

Author: NALS, <nals@itu.dk> <br>
Date: 2025, wed Feb 27, 20:56:23 UTC+1

Had trouble sucessfully deploying using workflow. The issue was due to me not copying the private properly, to incldue the headers and footers also:

-----BEGIN RSA PRIVATE KEY-----
(Base64-encoded key content here)
-----END RSA PRIVATE KEY-----

The workflow now also runs tests by building and running the Dockerfile.test, which executes a shell script that runs the rspec and python tests.

---

Author: NALS, <nals@itu.dk> <br>
Date: 2025, wed Feb 26, 17:39:43 UTC+1

Modified vagrant- and dockerfiles which were based on tutorial from:
https://github.com/itu-devops/itu-minitwit-ci

Deployed by using SSH to access server and ran the deploy.sh script. A workflow is being added in another pull request separate from this, which will hopefully automate the running of the shell script.

Chose not to make a separate docker image for the SQL which the tutorial does as we use SQLite which stores the data in a .db file thus it is simply embedded into the image. The data should therefore also be persistent to crashes/restarts, as i assigned it a volume.

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, wed Feb 22, 21:46:43 UTC+1

added a check such that the user can't follow more than once

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, wed Feb 20, 17:40:43 UTC+1

Completly refactored the python test into ruby using rspec
Everything passes
Test include
- login
- register
- logout
- add_message
- follow
- unfollow
- timeline test ( for interaction)

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, wed Feb 20, 15:38:13 UTC+1

Refactored python test suite to ruby.
Everything passes

Missing unfollow and follow test aswell as the timeline test

---

Author: nals, <nals@itu.dk> <br>
Date: 2025, wed Feb 20, 15:27:13 UTC+1

Fixed displaying html tags in timeline. The issue arose when trying to input ex. `<hello>` as input for the message. The page would then just display a blank message instead of the text. Fixed using a function in Rack utils called escape_html().

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, wed Feb 20, 12:03:13 UTC+1

Started the refactor on the test suite
add_message is not working as intended and follow / unfollow and timeline test is missing

added Login, register and logout test working
setup the test as a rspec file for testing ruby files

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, wed Feb 19, 22:26:13 UTC+1

Fixed last two tests in the refactored test-suite
Had to change them since they expected
'&lt;test message 2&gt;' and '&#34foo&#34' to be returned
instead of the actual messages.
changed to '<test message 2>' and '"foo"' respectively

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, wed Feb 19, 20:31:13 UTC+1

Fixed two of the 4 tests passing in the refactored test-suite
---

Author: nals, <nals@itu.dk> <br>
Date: 2025, Mon Feb 19, 19:19:13 UTC+1

Fixed follow and unfollow

The issue arose from `def get_user_id(username)` where we had to specify the correct column name to actually retrieve the correct user. Fixed by adding `result.first['user_id']`

---

Author: nals, <nals@itu.dk> <br>
Date: 2025, Mon Feb 19, 16:18:28 UTC+1

Fixed displaying of user profiles

Moved username query to the bottom, as it could intepret other queries as user queries if it gets to them first. Also fixed such that we use the helper query_db instead of @db.execute.  Also fixed such that user profiles can now be displayed, this was due to use forgetting to put '@' in front of "profile_user" thus not using the instance variable from Sinatra.

Also discovered that follow and unfollow does not seem to work. Creating new branch to fix this.

---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, Tue Feb 18, 15:31:00 UTC+1

Conternerized the application

    1. setup the docker compose and docker file to create a working docker image


---

Author: mnla, <mnla@itu.dk> <br>
Date: 2025, Tue Feb 18, 11:40:00 UTC+1

Intialized docker setup

    1. Added the docker files that needs to be ajusted
    2. Added a gem file for easier setup of the application
    3. Fixed secret to be fixed and not generated new each time the program launches



---

Author: brka, <brka@itu.dk> <br>
Date: 2025, Mon Feb 17, 17:40:02 UTC+1

Fixed exceptions when querying /login /register / / public

Most of the errors were caused by either:
    1. an incorrect call to `query_db`, which should take a query and an array of arguments. The arguments were being passed individually.
    2. configuring the database to return records as a map. Getting values by their keys eg `user.["user_id]` then worked.

Other than that, `timeline.erb` is having issues with other profiles than the user's own.
`/public` was having similar issues because it was trying to access profile specific information, eg `followed?` on the public timeline.
That has been corrected to first check if the page is a user's timeline or the public one.  

---

Author: nals, <nals@itu.dk> <br>
Date: 2025, Mon Feb 17, 14:57:27 UTC+1

Fixed 404 response when trying to query /login /register

The issue stemmed from the `get '/:username'` which intercepted the request before login and register. In other words it meant that it treated the request to "/login" as a request to see the user "login", thus the fix was simply to move the route mappings above the dynamic routes.

---

Author: nals, <nals@itu.dk> <br>
Date: 2025, Sun Feb 16, 22:59:27 UTC+1

Refactored to ruby with help from GitHub copilot. Installed Sinatra, Sqlite3, Bcrypt using: 
- `gem install sinatra` 
- `gem install sqlite3`
- `gem install bcrypt`
- `gem install rackup puma`
---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Fri Feb 07, 14:13:27 UTC+1

Added the refactored, more general, test-suite made by Helge.

The tests try to access `localhost:5000` by default,
so I also modified `minitwit.py` to run on said url.
Another thing to note is, for the tests to work,
you need to be running the webserver, and also,
the tests make changes to the database,
which need to be reverted if you want
the tests to run successfully a 2nd time.

---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Fri Feb 07, 10:46:32 UTC+1

Corrected control.sh Shebang.

Was `#!/bin/sh`, is now `#!/usr/bin/env bash`

---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Sat Feb 01, 11:33:24 UTC+1

Refactored utf-8 decoding to be its own function.

I tried my hand at some basic python coding, 
and moved the `.data.decode('utf-8')` to its own function.

---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Fri Jan 31, 16:25:19 UTC+1

Adapted control.sh according to shellcheck.

I basically just ran `shellcheck` on the `control.sh` file,
made it automatically fix all that it could,
and manually did the rest of the changes it recommended.

---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Fri Jan 31, 16:23:23 UTC+1

Accounted for a relocated database and utf-8 encodings.

Since the database no longer existed in `/tmp/`,
we needed to update the reference string.

Also, there were several instances where the code
expected a different format but got utf-8.
To counteract this a simple `.decode('utf-8')`
was added where needed; which was once in the `minitwit.py`,
and a lot of times in the `minitwit_tests.py`.

---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Fri Jan 31, 16:18:46 UTC+1

Fixed `minitwit.py` werkzeug import statement.

Werkzeug was updated to the most recent version, in which,
password hashing was moved to a different module.
To correct for this, the import statement had to be changed accordingly;
from `werkzeug` to `werkzeug.security`.

---

Author: gafa, <gafa@itu.dk> <br>
Date: 2025, Fri Jan 31, 16:04:50 UTC+1

Updated old python2 files to python3.

Essentially just used `2to3` on all python files (`minitwit.py` and `minitwit_tests.py`).
This command only shows what needs to be changed, 
so used `2to3 -w` to directly override the files with the needed changes.

---