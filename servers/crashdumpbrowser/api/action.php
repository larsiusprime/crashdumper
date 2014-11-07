<?php
/*! action.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Interface for performing row actions
include_once("../includes/db.inc.php");

$output = array();

if (empty($_GET[PARAM_ERRORID]) || (!is_numeric($_GET[PARAM_ERRORID]) && !is_array($_GET[PARAM_ERRORID])) || !isset($_GET[PARAM_STATUS]) || !is_numeric($_GET[PARAM_STATUS])) {
   // Abort on bad input
} else if ($_GET[PARAM_STATUS] == STATUS_DUPLICATE && (empty($_GET[PARAM_DUPLICATEID]) || !is_numeric($_GET[PARAM_DUPLICATEID]))) {
   // Return similar errors
   $ids = $_GET[PARAM_ERRORID];
   $output["id"] = $ids;
   $similar = array();
   if (!is_array($ids)) {
      $ids = array($ids);
   }
   foreach($ids as $id) {
      $error = db::getErrorType(intval($id));
      if ($error === false) {
         continue;
      }
      $errors = db::getErrorTypes($error[DB_COL_PROJECTID]);
      list($exception, $file, $function) = explode(ERROR_DELIMITER, $error[DB_COL_ERRORNAME]);
      $filename = substr($file, 0, strrpos($file, ":"));
      foreach($errors as $e) {
         $score = 0;
         if ($e[DB_COL_DUPLICATEID] == $error[DB_COL_DUPLICATEID] || $e[DB_COL_DUPLICATEID] != $e[DB_COL_ERRORID]) {
            continue;
         }
         list($exception2, $file2, $function2) = explode(ERROR_DELIMITER, $e[DB_COL_ERRORNAME]);
         if ($exception == $exception2) {
            $score += 200;
         }
         if ($function == $function2) {
            $score += 500;
         }
         if ($file == $file2) {
            $score += 600;
         } else if ($filename == substr($file2, 0, strrpos($file2, ":"))) {
            // Score based on distance
            $score += 600;
            $score -= min(abs(intval(substr($file, strpos($file, ":") + 1)) - intval(substr($file2, strpos($file2, ":") + 1))), 300);
         }
         if ($score > 0) {
            $similar[] = array("exception" => $exception2, "file" => $file2, "function" => $function2, "id" => $e[DB_COL_ERRORID], "score" => $score);
         }
      }
   }
   usort($similar, "scoreSort");
   $output["similar"] = $similar;
} else {
   $duplicateId = -1;
   if (!empty($_GET[PARAM_DUPLICATEID])) {
      $duplicateId = intval($_GET[PARAM_DUPLICATEID]);
   }
   if (is_array($_GET[PARAM_ERRORID])) {
      $output["success"] = 0;
      foreach($_GET[PARAM_ERRORID] as $id) {
         if (is_numeric($id)) {
            $output["success"] += db::updateErrorTypeStatus(intval($_GET[PARAM_ERRORID]), intval($_GET[PARAM_STATUS]), $duplicateId);
         }
      }
   } else {
      $output["success"] = db::updateErrorTypeStatus(intval($_GET[PARAM_ERRORID]), intval($_GET[PARAM_STATUS]), $duplicateId);
   }
}

echo json_encode($output);

function scoreSort($a, $b) {
   if ($a["score"] == $b["score"]) return 0;
   return $a["score"] > $b["score"] ? -1 : 1;
}