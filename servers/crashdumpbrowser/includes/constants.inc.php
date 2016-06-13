<?php
/*! constants.inc.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */

// Directory where reports are stored - you MUST set this before you start processing reports
define("REPORT_DIR", "/var/www/crashdumpbrowser/reports");

// Configuration options
define("DATE_FORMAT", "H:i:s d M, Y"); // See http://us3.php.net/manual/en/function.date.php
define("DB_PREFIX", "cdbrowser_");
define("DEFAULT_PROJECT_ID", ""); // Defaults to all projects if left blank
define("METADATA", "OS,crashed"); // Comma-separated list of error report metadata to show on the error display
define("MULTIPROJECT", true); // Set to false if you want to disable multiproject support
define("ROWS_PER_PAGE", 50);
define("THEME", "light.css"); // Corresponds to a stylesheet file in the media directory

// Errordump identifiers (corresponding to lines in _error.txt)
define("ERROR_EXCEPTION", "error");
define("ERROR_PROJECTNAME", "sess. ID");
define("ERROR_STACK", "stack");
define("ERROR_TIMESTAMP", "crashed");
define("ERROR_VERSION", "version");


/**** Don't change anything below unless you know what you're doing ****/

// DB constants
// Tables
define("DB_TABLE_REPORTS", DB_PREFIX ."reports");
define("DB_TABLE_ERRORTYPES", DB_PREFIX ."errortypes");
define("DB_TABLE_PROJECTS", DB_PREFIX ."projects");

// Columns
define("DB_COL_DUPLICATEID", "DuplicateId");
define("DB_COL_ERRORID", "ErrorId");
define("DB_COL_ERRORNAME", "ErrorName");
define("DB_COL_INTVERSION", "IntVersion");
define("DB_COL_METADATA", "Metadata");
define("DB_COL_PROJECTID", "ProjectId");
define("DB_COL_PROJECTNAME", "ProjectName");
define("DB_COL_REPORTID", "ReportId");
define("DB_COL_STATUS", "Status");
define("DB_COL_TIMESTAMP", "Time");
define("DB_COL_VERSION", "Version");


// API constants -- note that these appear as literals in the JS
define("PARAM_DIR", "dir");
define("PARAM_DOWNLOAD", "dl");
define("PARAM_DUPLICATEID", "duplicateid");
define("PARAM_ERRORID", "id");
define("PARAM_EXCEPTION", "exception");
define("PARAM_FILE", "file");
define("PARAM_FUNCTION", "function");
define("PARAM_MAXCOUNT", "maxcount");
define("PARAM_MAXVERSION", "maxversion");
define("PARAM_MINCOUNT", "mincount");
define("PARAM_MINVERSION", "minversion");
define("PARAM_PAGE", "page");
define("PARAM_PROJECTID", "project");
define("PARAM_REPORTID", "id");
define("PARAM_SORT", "sort");
define("PARAM_STATUS", "status");


// Status code constants
define("STATUS_NEW", 0);
define("STATUS_INPROGRESS", 1);
define("STATUS_FIXED", 2);
define("STATUS_REOPENED", 3);
define("STATUS_WONTFIX", 4);
define("STATUS_DUPLICATE", 5);


// Action code constants
define("ACTION_STATUS_INPROGRESS", 1);
define("ACTION_STATUS_FIXED", 2);
define("ACTION_STATUS_REOPENED", 3);
define("ACTION_STATUS_WONTFIX", 4);
define("ACTION_STATUS_DUPLICATE", 5);


// Misc constants
define("ERROR_DELIMITER", "\t\t");
define("METADATA_DELIMITER", "\r\n");


?>
