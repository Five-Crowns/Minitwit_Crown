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