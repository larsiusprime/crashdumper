<?php
/*! grid.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Interface for fetching top-level Crashdump data via AJAX
include_once("../includes/db.inc.php");

$actions = '<select>'
   .'<option value="">Select...</option>'
   .'<option value="'. ACTION_STATUS_INPROGRESS .'">Move to In Progress</option>'
   .'<option value="'. ACTION_STATUS_FIXED .'">Move to Fixed</option>'
   .'<option value="'. ACTION_STATUS_WONTFIX .'">Move to Won\'t Fix</option>'
   .'<option value="'. ACTION_STATUS_REOPENED .'">Move to Reopened</option>'
   .'<option value="'. ACTION_STATUS_DUPLICATE .'">Mark as Duplicate...</option>'
   .'</select>';
$output = array("col1" => '<input type="checkbox"/>', "col2" => $actions, "rows" => array());

$params = array();
if (MULTIPROJECT && isset($_GET[PARAM_PROJECTID]) && $_GET[PARAM_PROJECTID] != "") {
   $params["e"][DB_COL_PROJECTID] = intval($_GET[PARAM_PROJECTID]);
}
if (!empty($_GET[PARAM_STATUS]) && is_array($_GET[PARAM_STATUS])) {
   $status = array_filter($_GET[PARAM_STATUS], "isStatus");
   if (!empty($status)) {
      $params["e"][DB_COL_STATUS] = $status;
   }
}
if (!empty($_GET[PARAM_FILE]) && is_array($_GET[PARAM_FILE])) {
   $params["e"][DB_COL_ERRORID] = $_GET[PARAM_FILE];
}
if (!empty($_GET[PARAM_MINCOUNT]) && intval($_GET[PARAM_MINCOUNT]) > 0) {
   $params["e"][PARAM_MINCOUNT] = intval($_GET[PARAM_MINCOUNT]);
}
if (!empty($_GET[PARAM_MAXCOUNT]) && intval($_GET[PARAM_MAXCOUNT]) > 0) {
   $params["e"][PARAM_MAXCOUNT] = intval($_GET[PARAM_MAXCOUNT]);
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

$order = "";
$orderDir = "";
if (!empty($_GET[PARAM_SORT])) {
   // Validation is performed downstream
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

$status = array(STATUS_NEW => "New", STATUS_INPROGRESS => "In Progress", STATUS_FIXED => "Fixed", STATUS_REOPENED => "Reopened", STATUS_WONTFIX => "Won't Fix", STATUS_DUPLICATE => "Duplicate");
$page = !empty($_GET[PARAM_PAGE]) ? intval($_GET[PARAM_PAGE]) : 0;
$rowsPerPage = ROWS_PER_PAGE;
$reports = array();

$reports = db::getReports($params, $order, $orderDir, $page, ROWS_PER_PAGE);
$output["total"] = db::foundRows();
$output["page"] = $page;
$output["perPage"] = $rowsPerPage;

if (is_array($reports)) {
   foreach($reports as $report) {
      $row = array($report[DB_COL_DUPLICATEID]);
      if (isset($params["e"]) && isset($params["e"][DB_COL_STATUS]) && is_array($params["e"][DB_COL_STATUS]) && in_array(STATUS_DUPLICATE, $params["e"][DB_COL_STATUS])) {
         // Use error ID when displaying duplicates
         $row[0] = $report[DB_COL_ERRORID];
      }
      $row[] = $report['count'];
      if (array_key_exists($report[DB_COL_STATUS], $status)) {
         $row[] = $status[$report[DB_COL_STATUS]];
      }
      if (MULTIPROJECT) {
         $row[] = $report[DB_COL_PROJECTNAME];
      }
      $row = array_merge($row, explode(ERROR_DELIMITER, $report[DB_COL_ERRORNAME]));
      $row[] = date(DATE_FORMAT, strtotime($report["firstTime"]));
      $row[] = date(DATE_FORMAT, strtotime($report["lastTime"]));
      $row[] = formatVersion($report["firstVersion"], $report[DB_COL_VERSION]);
      $row[] = formatVersion($report["latestVersion"], $report[DB_COL_VERSION]);
      $output["rows"][] = $row;
   }
}

echo json_encode($output);

// INET_NTOA doesn't preserve the number of digits, so try to turn the number into something resembling a user-defined version number
function formatVersion($versionNumber, $template) {
   if ($versionNumber == 0 && !preg_match('/(([0-9]+\\.)*[0-9]+)[A-Za-z]*$/', $template)) {
      return $template;
   }
   $split = explode(".", $template);
   $version = $versionNumber % 256;
   for($i = 1; $i < count($split) || $versionNumber >= 256; ++$i) {
      $versionNumber = floor($versionNumber / 256);
      $version = ($versionNumber % 256) .".". $version;
   }
   return $version;
}

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

function isStatus($n) {
   return in_array($n, array(STATUS_NEW, STATUS_INPROGRESS, STATUS_FIXED, STATUS_REOPENED, STATUS_WONTFIX, STATUS_DUPLICATE));
}
?>