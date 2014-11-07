<?php
/*! index.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Renders initial page
// This is the only page directly accessed by the user; the rest of the rendering and heavy lifting is performed in the JS.
include_once("includes/db.inc.php");
include_once("includes/install.inc.php"); // attempt to install in case this is the first run

$projectSelect = "";
$metaColumns = "";
$messages = "";
$exceptions = array();
$files = array();
$functions = array();
$errorTypes = db::getErrorTypes();
foreach($errorTypes as $e) {
   if (empty($files[$e[DB_COL_PROJECTNAME]])) {
      $exceptions[$e[DB_COL_PROJECTNAME]] = array();
      $files[$e[DB_COL_PROJECTNAME]] = array();
      $functions[$e[DB_COL_PROJECTNAME]] = array();
   }
   $error = explode(ERROR_DELIMITER, $e[DB_COL_ERRORNAME]);
   $file = substr($error[1], 0, strrpos($error[1], ":"));
   if (!empty($error[0]) && !in_array($error[0], $exceptions[$e[DB_COL_PROJECTNAME]])) {
      $exceptions[$e[DB_COL_PROJECTNAME]][$e[DB_COL_ERRORID]] = $error[0];
   } else if (!empty($error[0])) {
      $key = array_search($error[0], $exceptions[$e[DB_COL_PROJECTNAME]]);
      $exceptions[$e[DB_COL_PROJECTNAME]][$key .",". $e[DB_COL_ERRORID]] = $error[0];
      unset($exceptions[$e[DB_COL_PROJECTNAME]][$key]);
   }
   if (!empty($file) && !in_array($file, $files[$e[DB_COL_PROJECTNAME]])) {
      $files[$e[DB_COL_PROJECTNAME]][$e[DB_COL_ERRORID]] = $file;
   } else if (!empty($file)) {
      $key = array_search($file, $files[$e[DB_COL_PROJECTNAME]]);
      $files[$e[DB_COL_PROJECTNAME]][$key .",". $e[DB_COL_ERRORID]] = $file;
      unset($files[$e[DB_COL_PROJECTNAME]][$key]);
   }
   if (!empty($error[2]) && !in_array($error[2], $functions[$e[DB_COL_PROJECTNAME]])) {
      $functions[$e[DB_COL_PROJECTNAME]][$e[DB_COL_ERRORID]] = $error[2];
   } else if (!empty($error[2])) {
      $key = array_search($error[2], $functions[$e[DB_COL_PROJECTNAME]]);
      $functions[$e[DB_COL_PROJECTNAME]][$key .",". $e[DB_COL_ERRORID]] = $error[2];
      unset($functions[$e[DB_COL_PROJECTNAME]][$key]);
   }
}
$exceptionSelect = createSelect($exceptions);
$fileSelect = createSelect($files);
$functionSelect = createSelect($functions);
if (defined("MULTIPROJECT") && MULTIPROJECT) {
   $projectSelect = '<option value="">All projects</option>';
   $projects = db::getProjects();
   foreach($projects as $project) {
      $projectSelect .= '<option value="'. htmlspecialchars($project[DB_COL_PROJECTID]) .'">'. htmlspecialchars($project[DB_COL_PROJECTNAME]) .'</option>';
   }
   $projectSelect = '<div id="currProj">Current Project: <select id="projSelect">'. $projectSelect .'</select></div>';
} else {
   $projectSelect = '<input type="hidden" id="projSelect" value=""/>';
}
if (defined("METADATA") && METADATA) {
   $metadata = explode(",", METADATA);
   foreach($metadata as $m) {
      $metaColumns .= '<th title="User-defined metadata">'. $m .'</th>';
   }
}
if (!file_exists(REPORT_DIR)) {
   $messages = 'Your reports directory is configured incorrectly! This will prevent you from receiving crash reports. Please see step 7 of the README for instructions on correcting this.';
}


function createSelect($selectData) {
   $select = "";
   ksort($selectData);
   foreach($selectData as $project => $projectData) {
      if (defined("MULTIPROJECT") && MULTIPROJECT && count($selectData) > 1) {
         $select .= '<optgroup label="'. htmlspecialchars($project) .'">';
      }
      ksort($projectData);
      foreach($projectData as $key => $data) {
         $select .= '<option value="'. $key .'">'. htmlspecialchars($data) .'</option>';
      }
      if (defined("MULTIPROJECT") && MULTIPROJECT && count($selectData) > 1) {
         $select .= '</optgroup>';
      }
   }
   return $select;
}

?><!DOCTYPE HTML>
<html lang="en">
<head>
   <title>Crashdump Browser</title>
   <link rel="stylesheet" type="text/css" href="media/<?php echo THEME; ?>"/>
   <script type="application/javascript" src="media/jquery.js"></script>
   <script type="application/javascript" src="media/crashdumpbrowser.js"></script>
</head>
<body>
   <?php echo $projectSelect; ?>
   <h1>Crashdump Browser</h1>
   <div id="messages"><?php echo $messages; ?></div>
   <div id="main">
      <div id="overview" class="view">
         <div class="pretable">
            <div class="filters">
               <div class="filter">
                  <label for="overviewMinVersion">Min version:</label> <input type="text" id="overviewMinVersion" data-sync="minversion"/>
                  <br/>
                  <label for="overviewMaxVersion">Max version:</label> <input type="text" id="overviewMaxVersion" data-sync="maxversion"/>
                  <br/>
                  <label for="minCount">Min count:</label> <input type="text" id="minCount"/>
                  <br/>
                  <label for="maxCount">Max count:</label> <input type="text" id="maxCount"/>
               </div>
               <div class="filter">
                  Status:
                  <br/>
                  <select name="status" multiple="multiple">
                     <option value="<?php echo STATUS_NEW; ?>" selected="selected">New</option>
                     <option value="<?php echo STATUS_REOPENED; ?>" selected="selected">Reopened</option>
                     <option value="<?php echo STATUS_INPROGRESS; ?>" selected="selected">In Progress</option>
                     <option value="<?php echo STATUS_FIXED; ?>">Fixed</option>
                     <option value="<?php echo STATUS_WONTFIX; ?>">Won't Fix</option>
                     <option value="<?php echo STATUS_DUPLICATE; ?>">Duplicate</option>
                  </select>
               </div>
               <div class="filter">
                  Error Type:
                  <br/>
                  <select name="exception" multiple="multiple">
                     <?php echo $exceptionSelect; ?>
                  </select>
               </div>
               <div class="filter">
                  File:
                  <br/>
                  <select name="file" multiple="multiple">
                     <?php echo $fileSelect; ?>
                  </select>
               </div>
               <div class="filter">
                  Function:
                  <br/>
                  <select name="function" multiple="multiple">
                     <?php echo $functionSelect; ?>
                  </select>
               </div>
               <div class="clear"></div>
               <input type="submit" id="filterGrid" value="Apply filters"/>
            </div>
            <div class="bulkActions">
               <label for="overviewBulk">Bulk actions:</label>
               <select id="overviewBulk">
                  <option value="">Select...</option>
                  <option value="<?php echo ACTION_STATUS_INPROGRESS; ?>">Move to In Progress</option>
                  <option value="<?php echo ACTION_STATUS_FIXED; ?>">Move to Fixed</option>
                  <option value="<?php echo ACTION_STATUS_WONTFIX; ?>">Move to Won't Fix</option>
                  <option value="<?php echo ACTION_STATUS_REOPENED; ?>">Move to Reopened</option>
                  <option value="<?php echo ACTION_STATUS_DUPLICATE; ?>">Mark as Duplicate...</option>
                  
               </select>
            </div>
            <p>
               Click on a row for more details on that error.
            </p>
         </div>
         <table id="overviewTable">
            <tbody>
               <tr class="head">
                  <th title="Invert selection"><input type="checkbox" class="topCheck"/></th>
                  <th title="Actions you can perform on this error">Actions</th>
                  <th title="Internal error ID number" class="sortable" data-sort="<?php echo DB_COL_ERRORID; ?>">Error ID</th>
                  <th title="Number of times this error has been reported" class="sortable" data-sort="count">Error Count</th>
                  <th title="Current working status of this error" class="sortable" data-sort="<?php echo DB_COL_STATUS; ?>">Status</th>
                  <?php if (MULTIPROJECT) { ?><th title="Project ID" class="sortable" data-sort="<?php echo DB_COL_PROJECTID; ?>">Project</th><?php } ?>
                  <th title="Exception class or other error identifier">Error Type</th>
                  <th title="File and line of code on which the error occurred">Line</th>
                  <th title="Function in which the error occurred">Function</th>
                  <th title="Date at which the error was first encountered" class="sortable" data-sort="firstTime">First encountered</th>
                  <th title="Date at which the error was most recently encountered" class="sortable sortDown" data-sort="lastTime">Last encountered</th>
                  <th title="Oldest version in which the error was encountered" class="sortable" data-sort="firstVersion">Earliest version</th>
                  <th title="Newest version in which the error was encountered" class="sortable" data-sort="latestVersion">Latest version</th>
               </tr>
            </tbody>
         </table>
         <div class="pagination"></div>
         <div id="testReport"><input type="submit" value="Generate test report"/></div>
         <form action="report.php" method="POST" enctype="multipart/form-data"><input type="file" name="report"/><input type="submit" value="Manually submit report"/></form>
      </div>
      <div id="errorView" class="view">
         <div class="pretable">
            <a href="#" data-show="overview">Back to Overview &gt;</a>
            <h2></h2>
            <div class="filters">
               <div class="filter">
                  <label for="errorMinVersion">Min version:</label> <input type="text" id="errorMinVersion" data-sync="minversion"/>
                  <br/>
                  <label for="errorMaxVersion">Max version:</label> <input type="text" id="errorMaxVersion" data-sync="maxversion"/>
               </div>
            </div>
            <div class="clear"></div>
            <input type="submit" id="filterError" value="Apply filters"/>
            <p>
               Click on a row for more details on that report.
            </p>
         </div>
         <table id="errorTable">
            <tbody>
               <tr class="head">
                  <th title="Internal report ID number, for reference only" class="sortable sortDown" data-sort="<?php echo DB_COL_REPORTID; ?>">Report ID</th>
                  <th title="Date at which the error was encountered" class="sortable" data-sort="<?php echo DB_COL_TIMESTAMP; ?>">Date</th>
                  <th title="Version in which the error was encountered" class="sortable" data-sort="<?php echo DB_COL_INTVERSION; ?>">Version</th>
                  <?php echo $metaColumns; ?>
               </tr>
            </tbody>
         </table>
         <div class="pagination"></div>
      </div>
      <div id="detailView" class="view">
         <div class="pretable">
            <a href="#" data-show="errorView">Back to Error View &gt;</a>
            <p>
               <b>Warning:</b> The files listed below are user-submitted. Be aware that files may be submitted by malicious users!
            </p>
         </div>
         <table id="detailTable">
            <tbody>
               <tr class="head">
                  <th title="See the contents of the file in your browser">View</th>
                  <th title="Download the file to your computer">Download</th>
                  <th title="The name of the file">Filename</th>
                  <th title="The uncompressed size of the file">Filesize</th>
                  <th title="The compressed size of the file">Compressed Filesize</th>
            </tbody>
         </table>
      </div>
   </div>
   <div id="similarContainer">
      <div id="similarBox">
         <h2>Mark as Duplicate: <span id="similarError"></span></h2>
         <p>
            Select the duplicated error from the suggested list below, or type the error ID into the box and click on the submit button.
         </p>
         <div id="similarList"></div>
         <p>
            Error ID: <input type="text" id="similarId"/> <input type="submit" id="similarSubmit" value="Use this error ID"/>
         </p>
         <input type="submit" id="similarCancel" value="Cancel"/>
      </div>
   </div>
</body>
</html>