<?php
/*! detail.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Interface for fetching detail view
include_once("../includes/db.inc.php");
$output = array("rows" => array());

function format_filesize($bytes) {
   $filesize = $bytes ."B";
   if ($bytes >= pow(1024, 3)) {
      $filesize = sprintf("%.2fGB", $bytes / pow(1024, 3));
   } else if ($bytes >= pow(1024, 2)) {
      $filesize = sprintf("%.2fMB", $bytes / pow(1024, 2));
   } else if ($bytes >= 1024) {
      $filesize = sprintf("%.2fKB", $bytes / 1024);
   }
   return $filesize;
}

$zipfile = "error" . intval($_GET[PARAM_REPORTID]) .".zip";

if (empty($_GET[PARAM_REPORTID]) || !is_numeric($_GET[PARAM_REPORTID])) {
   $output["rows"][] = array('<b>Bad report ID.</b>', "", "", "", "");
   die(json_encode($output));
}

$zip = @zip_open("../reports/". $zipfile);

if (!file_exists("../reports/". $zipfile) || !is_resource($zip)) {
   $output["rows"][] = array('<b>No detail found for this report.</b>', "", "", "", "");
   die(json_encode($output));
}

$output["rows"][] = array('-', '<a href="reports/'. $zipfile .'">Download</a>', '<div class="leftAlign">'. $zipfile .'</div>', '<div class="rightAlign"><b>'. format_filesize(filesize("../reports/". $zipfile)) .'</b></div>', '<div class="rightAlign"><b>'. format_filesize(filesize("../reports/". $zipfile)) .'</b></div>');

while($zipfile = zip_read($zip)) {
   $filename = zip_entry_name($zipfile);
   $rawFilesize = zip_entry_filesize($zipfile);
   $filesize = format_filesize($rawFilesize);
   $compressed = format_filesize(zip_entry_compressedsize($zipfile));
   $viewLink = '<a href="api/file.php?'. PARAM_FILE .'='. urlencode($filename) .'&amp;'. PARAM_REPORTID .'='. $_GET[PARAM_REPORTID] .'" target="_blank">View</a>';
   $downloadLink = '<a href="api/file.php?'. PARAM_DOWNLOAD .'=1&amp;'. PARAM_FILE .'='. urlencode($filename) .'&amp;'. PARAM_REPORTID .'='. $_GET[PARAM_REPORTID] .'">Download</a>';
   $output["rows"][] = array($viewLink, $downloadLink, '<div class="leftAlign">'. $filename .'</div>', '<div class="rightAlign">'. $filesize .'</div>', '<div class="rightAlign">'. $compressed .'</div>');
}

echo json_encode($output);