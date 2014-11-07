Getting Started
===========

In most cases, installing Crashdump Browser is very simple.

1. If your server doesn't already have them, install PHP and MySQL. Most hosting solutions have them out of the box; try "php" and "mysql" on the command line to check if they're available.
2. Move all of the files into your destination directory (e.g. /var/www/crashdumpbrowser). Depending on your setup, it may be necessary to change permissions on the files. In a default Linux Apache environment, this is accomplished by navigating to the parent directory and using the following command:
   ````
   chown -R www-data:www-data crashdumpbrowser
   ````
   If you get an "Operation not permitted" error, you will need to run the command with sudo. On many hosting providers, this step is unnecessary.
3. Edit line 10 of includes/db.inc.php with your database credentials. If you don't know your database credentials, contact your webhost support. If you want to use a new database, you will need to create it at this time. The installation script assumes that your credentials and database are valid.
4. In your Internet browser, hit the URL of your new directory (e.g. http://www.example.org/crashdumpbrowser/). You should see a message indicating that the database tables were set up. If you get an error or a blank page, then check steps 2 and 3 again.
5. _[Optional, but highly suggested]_ Alter your server config to prevent unwanted access to the logging utility. Be warned that mistakes in your configuration file can take your entire website offline! If you aren't sure what you're doing, you may want to talk to support about this step, too. Instructions on this step are outside the scope of this document, and I really don't want people blaming me for crashing their site. **WARNING:** If you skip this step, then anyone and everyone will be able to access your Crashdump Browser instance!
6. _[Optional]_ Customize the report submission page (starting on line 100 of report.php). By default, it is an unstyled HTML page that gives a brief success or error message. You may want to add CSS to make this page match the rest of your site.
7. _[Optional]_ You may want to copy report.php to another location. This will be the URL to which users send their crashdumps. If you do, then update line 6 of the copied report.php to point to the correct location. (You should leave an unaltered copy of report.php in the default directory; if you don't, then the "Manually submit report" option won't work.) Note that if you used .htaccess to restrict access to the entire directory in step 5, then you will need to perform this step, or users will be unable to submit error reports. You can check if you performed this step correctly by hitting report.php in your Internet browser. If you get a blank page or error message, then either you skipped step 4 or you performed this step incorrectly. 
8. After step 4, a new directory called "reports" will appear in your working directory. Edit line 5 of includes/constants.inc.php with the path to the reports directory. If you must make this a relative path for some reason, the path should be relative to wherever you put report.php in step 6. If you didn't move report.php, then the relative path is simply "reports".
9. _[Optional]_ Check the other config options in includes/constants.inc.php and change them as desired.
10. Configure Crashdumper to send error reports to report.php (in whatever location you put it in step 6).

Congratulations! You are done. You can browse reports at the same URL you hit
in step 4.


On Versioning
=============

Crashdump Browser assumes that your version numbers look something like
w.x.y.z, where w is the major version number, x, y, and z are increasingly
minor version numbers, and all of them are between 0 and 255. It's okay if you
have more or fewer digits, as long as you follow the general pattern. In the
event that you find yourself using a "cleverer" versioning scheme, the onus is
on you to sort out the version comparison.

Crashdump Browser also accepts versions that contain alphabetical or whitespace
characters at the end of what would otherwise be a valid version number. This
is useful if you have version numbers like "0.1a"; the ordering will be
preserved. However, only the numeric portion will be available on the top-level
view.

These version numbers are OK:
* 0.1
* 0.01
* 0.0000001.2
* 1.2.3.4.5
* 101
* 1.0.1abc
* 123 Sesame St

These version numbers are not supported:
* 0.256 (It's time for a major version bump)
* 0.1-2 (It's not clear what you're trying to do with this)
* Ice Cream Sandwich (That is not a number)
* 123 Sesame St. (Only letters and whitespace are OK after the number)
* 1101 4th St (Please reconsider your version numbering scheme)

Finally, changing your numbering scheme mid-project can be very confusing to
Crashdump Browser. For example, if you go from version 1.1.0 to version 1.2,
the second will be parsed as 0.1.2, with undesirable results. If you really
must change your numbering scheme and you want to preserve the functionality,
the easiest methodology is probably to mass-update your version numbers within
your SQL database. Crashdump Browser offers no support for this.


Using Crashdump Browser
=======================

Error reports are grouped together in Crashdump Browser according to the
exception type and line in which it occurred. From the main view, you can see
how many of each error have been reported. Click on an error to browse
individual error reports. Click on an individual report to see the details
of that report. If your error reports contain additional information or files,
then you will be able to examine them from the detailed view.

Once you have fixed an error, you can mark it as fixed from the top-level view.
If you do, then the error will be hidden by default, and further reports of the
same error will be ignored unless they originate from a version more recent
than your fix version. (Oops! Maybe it wasn't so fixed after all.) If you
accidentally mark an error as fixed, you can reopen it by changing the filters
to display fixed errors, then finding your error and selecting the "Reopened"
status. If you no longer wish to be reminded of an error, you can mark it as
"Won't Fix." Do this at your own risk!

Sometimes, an error from an earlier version will appear on a different line in
a later version. When this happens, Crashdump Browser will play it safe and
report it as a new, distinct error. You can mark an error as a duplicate of
another error to group them together. If you do, reports from the duplicate
error will appear under the designated error, and the duplicate error will no
longer appear unless you choose to display errors with the "Duplicate" status.
Displaying "Duplicate" errors will suspend this behavior, causing each error
to show up individually. This is the only way to separate an error that you
marked as a duplicate by mistake. Change its status to "Reopened" to split
them up.

All views
---------

* **Current Project:** If MULTIPROJECT is not disabled, this will let you narrow the
selection to a single project. This setting is remembered if you leave and come
back, so if you think you're missing something, check the project dropdown.

Filters
-------

After changing a filter, click "Apply filters" to see the updated view.

* **Min/max version:** Allows you to filter errors by the version in which they were reported. Click "Apply filters" after making changes to see the updated view.
* **Min/max count:** View only errors with a certain number of reports.
* **Status:** View only errors in the selected status(es). Ctrl+Click to select or deselect a status without deselecting the others. If "Duplicate" is not selected here, then errors marked as duplicates will be rolled into their parent errors.
* **Error Type/File/Function:** View only errors of the designated type. This is broken down by project, so in order to see all Null Pointer Exceptions, for example, you must select "Null Pointer Exception" separately for each project.

Overview view
-------------

* **Error ID:** When a new error is received, Crashdump Browser assigns it an internal ID. For your purposes, this is used when marking an error as a duplicate (see Actions).
* **Error Count:** How many times this error has been reported.
* **Status:** All errors start in "New" status. You can change an error's status with the Actions menu.
* **Error Type:** What kind of exception was reported.
* **Line:** The file and line number where the exception occurred.
* **Function:** The function where the exception originated.
* **First encountered:** The timestamp of the first occurrence of this error. This is when the error was encountered, not necessarily when it was reported.
* **Last encountered:** The timestamp of the most recent occurrence of this error. Again, this refers to when the error was encountered.
* **Earliest version:** The lowest version number that generated a report for this error. This might be different from the version number of the first report received for this error.
* **Latest version:** The highest version number that generated a report for this error. This might be different from the version number of the most recent report received for this error.
* **Actions:** Allows you to change an error's status. By clicking on the checkboxes, you can change multiple statuses with the "Bulk Actions" dropdown.

Actions
-------

* **Move to In Progress:** This is for your reference only; this status is indistinct from "New" as far as the application is concerned.
* **Move to Fixed:** The default view will no longer show this error. If the error is reported again in a version more recent than the error's current "Latest Version," the error will automatically change its status to "Reopened."
* **Move to Won't Fix:** As with Fixed, the default view will no longer show this error. Unlike Fixed, the error will never enter "Reopened" automatically.
* **Move to Reopened:** If you want to reopen an error manually, you can do so. Internally, this status is treated no differently from "In Progress" or "New."
* **Mark as Duplicate...:** This will open a menu suggesting similar errors. You can select one of these to mark your error as a duplicate of that error, or you can manually enter the desired Error ID. An error marked as a duplicate will add its reports to the Error Count of the duplicated error. To separate an error that you have marked as a duplicate, you must select "Duplicate" status in the status filter. You can then change the error's status to anything besides "Duplicate," and the error will be unlinked.

Error view
----------

By clicking on one of the error rows in Overview view, you can see the Error
view. This gives you a list of reports for that error. Click "Back to Overview"
to return.

* **Report ID:** When a report is received, Crashdump Browser assigns it an internal ID. This is for your reference; it may be helpful if you wish to find a report that you saw earlier.
* **Date:** The timestamp when the error occurred (not necessarily when it was reported).
* **Version:** The version of the software in which the error occurred.
* **Other fields:** You can customize what other error metadata appears in this table using the METADATA configuration in constants.inc.php.

Detail view
-----------

By clicking on one of the report rows in Error view, you can see the files that were submitted in that error report. You can view or download any of the individual files, or you can download the entire zip archive. Click "Back to
Error View" to return.


Good luck, and may all your errors be reproducible!
