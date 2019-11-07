<?php
/*! report.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Accepts crashdumps as zip files

// IMPORTANT: If you relocate this file, update the path to db.inc.php or you will be unable to process error reports
include_once("includes/db.inc.php");

if (empty($_FILES["report"])) {
   // Just tell the user that the db is configured correctly
   die("Ready to accept Crashdump reports!");
}

if (empty($_FILES["report"]["tmp_name"])) {
   // An empty file was "uploaded"
   die("Report not found");
}

$zip = zip_open($_FILES["report"]["tmp_name"]);

if (!is_resource($zip)) {
   die("Invalid Crashdump report");
}

$success = false;
$metadata = array();
if (defined("METADATA") && METADATA) {
   $metadata = explode(",", METADATA);
}

while($zipfile = zip_read($zip)) {
   $filename = zip_entry_name($zipfile);
   $filename = end(explode("/", $filename)); // zip_entry_name returns the full path, so get just the filename
   if (($filename == "_error" || $filename == "_error.txt") && zip_entry_open($zip, $zipfile)) {
      $exception = "";
      $file = "";
      $function = "";
      $project = "";
      $version = "";
      $intVersion = 0;
      $meta = array();
      $contents = "";
      $time = 0;
      $readStack = false;
      while ($buffer = zip_entry_read($zipfile)) {
         $contents .= $buffer;
      }
      $contents = str_replace("\r", "\n", $contents);
      $contents = explode("\n", $contents);
      foreach($contents as $line) {
         if ($readStack && strpos($line, " line ")) {
            $separator = strpos($line, "(");
            $function = trim(substr($line, 0, $separator - 1));
            $file = preg_replace('/.*\\(([^)]*)\\).*/', '\\1', $line);
            $file = str_replace(" line ", ":", $file);
            continue;
         }
         $separator = strpos($line, ":");
         if ($separator === false) continue;
         $key = trim(substr($line, 0, $separator));
         $val = trim(substr($line, $separator + 1));
         switch($key) {
            case ERROR_PROJECTNAME:
               $project = $val;
               break;
            case ERROR_EXCEPTION:
               $exception = $val;
               break;
            case ERROR_STACK:
               $readStack = true;
               break;
            case ERROR_TIMESTAMP:
               $time = strtotime($val);
               break;
            case ERROR_VERSION:
               $version = $val;
               // Strip alpha characters from the ends of otherwise-valid version numbers
               $versionNumbers = preg_replace('/(([0-9]+\\.)*[0-9]+)[A-Za-z\\s]+$/', '\\1', $version);
               $intVersion = 0;
               $parts = explode('.', $versionNumbers);
               foreach($parts as $part) {
                  $intVersion *= 256;
                  $intVersion += intval($part);
               }
               break;
            default:
               $meta[] = $key ."=". $val;
         }
      }
      if ((strlen($exception) || strlen($file) || strlen($function)) && strlen($project)) {
         $error = $exception . ERROR_DELIMITER . $file . ERROR_DELIMITER . $function;
         $meta = implode(METADATA_DELIMITER, $meta);
         $id = db::addReport($error, $time, $project, $version, $intVersion, $meta);
         move_uploaded_file($_FILES["report"]["tmp_name"], REPORT_DIR ."/error". $id .".zip");
         $success = true;
      }
      break;
   }
}
?>
<!DOCTYPE HTML>
<html>
<head>
   <title>Error Reporting</title>
</head>
<body>
<?php
if ($success) {
?>
<h1>Thank you!</h1>
<p>Your error report has been successfully processed.</p>
<?php
} else {
   // If we get here, there was a problem with crashdumper.
?>
<h1>Oops!</h1>
<p>There was an error with your error report, and we were unable to process it correctly. It was missing some important information, so resubmitting the report won't help. You should contact the developer for support with this problem.</p>
<?php
}
?>
</body>
</html>
