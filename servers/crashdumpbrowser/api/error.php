<?php
/*! error.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Interface for fetching records for a single error
include_once("../includes/db.inc.php");

// Sanity check - getReport would filter out these values, but this saves us a db call
if (empty($_GET[PARAM_ERRORID]) || !is_numeric($_GET[PARAM_ERRORID])) {
   die("{}");
}

$output = array("rows" => array());
$metadata = array();
$page = !empty($_GET[PARAM_PAGE]) ? intval($_GET[PARAM_PAGE]) : 0;
$rowsPerPage = ROWS_PER_PAGE;
$order = "";
$orderDir = "";
$params = array();
if (!empty($_GET[PARAM_SORT]) && in_array($_GET[PARAM_SORT], array(DB_COL_REPORTID, "firstTime", "lastTime", "firstVersion", "latestVersion"))) {
   $order = $_GET[PARAM_SORT];
}
if (!empty($_GET[PARAM_DIR]) && in_array(strtoupper($_GET[PARAM_DIR]), array("ASC", "DESC"))) {
   $orderDir = $_GET[PARAM_DIR];
} else {
   if (in_array($order, array(DB_COL_REPORTID, DB_COL_TIMESTAMP))) {
      $orderDir = "DESC";
   } else {
      $orderDir = "ASC";
   }
}
if (!empty($_GET[PARAM_MINVERSION])) {
   $version = unformatVersion($_GET[PARAM_MINVERSION]);
   if ($version > 0) {
      $params["r"][PARAM_MINVERSION] = unformatVersion($_GET[PARAM_MINVERSION]);
   }
}
if (!empty($_GET[PARAM_MAXVERSION])) {
   $version = unformatVersion($_GET[PARAM_MAXVERSION]);
   if ($version > 0) {
      $params["r"][PARAM_MAXVERSION] = $version;
   }
}

$reports = db::getErrorReports($_GET[PARAM_ERRORID], $params, $order, $orderDir, $page, $rowsPerPage);
$output["total"] = db::foundRows();
$output["page"] = $page;
$output["perPage"] = $rowsPerPage;

if (defined("METADATA") && METADATA) {
   $metadata = explode(",", METADATA);
}

foreach($reports as $r) {
   $row = array();
   $row[] = $r[DB_COL_REPORTID];
   $row[] = date(DATE_FORMAT, strtotime($r[DB_COL_TIMESTAMP]));
   $row[] = $r[DB_COL_VERSION];
   if (!empty($metadata)) {
      // Populate metadata columns
      $rowdata = array();
      if (!empty($r[DB_COL_METADATA])) {
         $rowdata = explode(METADATA_DELIMITER, $r[DB_COL_METADATA]);
      }
      foreach($metadata as $m) {
         $data = "";
         foreach($rowdata as $d) {
            if (strpos($d, $m ."=") === 0) {
               $data = substr($d, strlen($m) + 1);
            }
         }
         $row[] = $data;
      }
   }
   $output["rows"][] = $row;
}

echo json_encode($output);

function unformatVersion($version) {
   $versionNumbers = preg_replace('/(([0-9]+\\.)*[0-9]+)[A-Za-z\\s]+$/', '\\1', $version);
   $intVersion = 0;
   $parts = explode('.', $versionNumbers);
   foreach($parts as $part) {
      $intVersion *= 256;
      $intVersion += intval($part);
   }
   return $intVersion;
}
?>