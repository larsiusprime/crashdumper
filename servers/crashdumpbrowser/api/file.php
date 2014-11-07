<?php
/*! file.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// View or download a file from an error report
include_once("../includes/db.inc.php");

if (empty($_GET[PARAM_REPORTID])) {
   die("No report number specified.");
}

if (empty($_GET[PARAM_FILE])) {
   die("No file specified.");
}

$zipfile = "error" . intval($_GET[PARAM_REPORTID]) .".zip";

if (empty($_GET[PARAM_REPORTID]) || !is_numeric($_GET[PARAM_REPORTID]) || !file_exists("../reports/". $zipfile)) {
   die("Crash report not found.");
}

$zip = zip_open("../reports/". $zipfile);

if (!is_resource($zip)) {
   die("Invalid crash report.");
}

while($zipfile = zip_read($zip)) {
   $filename = zip_entry_name($zipfile);
   if ($filename == $_GET[PARAM_FILE]) {
      // In order to get the MIME type, the file needs to be extracted
      // We'll delete the temp file when we finish
      $tmpfile = tempnam(sys_get_temp_dir(), "cdb");
      $tmp = fopen($tmpfile, "r+");
      while ($buffer = zip_entry_read($zipfile)) {
         fwrite($tmp, $buffer);
      }
      $mimetype = "";
      if (function_exists("finfo_open")) {
         $finfo = new finfo(FILEINFO_MIME);
         $mimetype = $finfo->file($tmpfile);
      } else if (function_exists("mime_content_type")) {
         $mimetype = mime_content_type($tmpfile);
      }

      if (!is_string($mimetype) || empty($mimetype)) {
         $mimetype = "application/octet-stream"; // fallback
      }

      if (!empty($_GET[PARAM_DOWNLOAD])) {
         header('Content-Disposition: attachment; filename="'. $baseFilename .'"');
      }

      header('Content-Type: '. $mimetype);
      rewind($tmp);
      while (!feof($tmp)) {
         echo fread($tmp, 8192);
      }
      fclose($tmp);
      unlink($tmpfile);
      die();
   }
}

die("Specified file not found in crash report.");