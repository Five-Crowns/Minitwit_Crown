### This is a simple log
- The purpose of this log book is to keep track of changes to the program.
- It is required to list your initials and datetime of when the changes occurred.




### Changes Should be listed below here in decending order.

---

Author: (initials) <(mail)> <br>
Date: (year), (day of the week) (date & month), (time) (timezone)

(header/one-line summary)

(changes)

---

Author: Noah <gafa@itu.dk> <br>
Date: 2025, Fri Jan 31, 16:18:46 UTC+1

Fixed `minitwit.py` Werkzeug import statement.

Werkzeug was updated to the most recent version, in which,
password hashing was moved to a different module.
To correct for this, the import statement had to be changed accordingly;
from `werkzeug` to `werkzeug.security`.

---

Author: Noah <gafa@itu.dk> <br>
Date: 2025, Fri Jan 31, 16:04:50 UTC+1

Updated old python2 files to python3.

Essentially just used `2to3` on all python files (`minitwit.py` and `minitwit_tests.py`).
This command only shows what needs to be changed, 
so used `2to3 -w` to directly override the files with the needed changes.

---