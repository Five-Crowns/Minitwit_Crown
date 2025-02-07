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