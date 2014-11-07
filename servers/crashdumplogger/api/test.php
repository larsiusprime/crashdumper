<?php
/*! test.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Generate a test error
include_once("../includes/db.inc.php");
$meta = array();
$time = time();
$exception = "TestException";
$function = "generateTestError";
$file = "testfile:". rand(100, 110); // small spread to generate a small number of errortypes
$project = "Test Project";
$version = rand(0, 9) .".". rand(0, 9) .".". rand(1, 9);
$versionNumbers = preg_replace('/(([0-9]+\\.)*[0-9]+)[A-Za-z\\s]+$/', '\\1', $version);
$intVersion = 0;
$parts = explode('.', $versionNumbers);
foreach($parts as $part) {
   $intVersion *= 256;
   $intVersion += intval($part);
}

$metadata = array();
if (defined("METADATA") && METADATA) {
   $metadata = explode(",", METADATA);
}

foreach($metadata as $m) {
   $meta[] = $m ."=Test value ". rand(100, 999);
}

if ((strlen($exception) || strlen($file) || strlen($function)) && strlen($project)) {
   $error = $exception . ERROR_DELIMITER . $file . ERROR_DELIMITER . $function;
   $meta = implode(METADATA_DELIMITER, $meta);
   db::addReport($error, $time, $project, $version, $intVersion, $meta);
}