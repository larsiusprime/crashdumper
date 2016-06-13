<?php
/*! db.inc.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Database connection and queries; also instantiates the static DB object
include_once("constants.inc.php");

class db {
   private static $mysqli;
   static function connect() {
      if (!self::$mysqli) {
         self::$mysqli = new mysqli('HOSTNAME', 'USERNAME', 'PASSWORD', 'DATABASE');
         if (mysqli_connect_errno()) {
            throw new Exception(mysqli_connect_error());
         }
      }
   }
   
   private static function query($stmt) {
      if (!$stmt) return false;
      $stmt->execute();
      if (self::$mysqli->errno) {
         throw new Exception(self::$mysqli->error);
      }
      if ($id = $stmt->insert_id) {
         $stmt->close();
         return $id;
      }
      // Return associative array
      $rv = array();
      $row = array();
      $refs = array();
      $meta = $stmt->result_metadata();
      if ($meta == null) {
         $rows = $stmt->affected_rows;
         $stmt->close();
         return $rows;
      }
      while($col = $meta->fetch_field()) {
         $refs[] = &$row[str_replace(' ', '_', $col->name)];
      }
      call_user_func_array(array($stmt, "bind_result"), $refs);
      while($stmt->fetch()) {
         $newrow = array();
         foreach($row as $k => $v) {
            $newrow[$k] = $v;
         }
         $rv[] = $newrow;
      }
      $stmt->close();
      return $rv;
   }
   
   static function addFilters($filters, &$params, &$types, &$where = array(), &$having = null) {
      $matches = array();
      $havingTypes = "";
      $havingParams = array();
      foreach($filters as $table => $filter) {
         if ($table != "e" && $table != "r") continue;
         foreach($filter as $col => &$val) {
            // Validate
            if (preg_match('/\w+/', $col, $matches) && $matches[0] == $col) {
               if ($col == PARAM_MINCOUNT && is_array($having)) {
                  $having[] = "COUNT(DISTINCT `". DB_COL_REPORTID ."`) >= ?";
                  $havingTypes .= "i";
                  $havingParams[] = &$val;
               } else if ($col == PARAM_MAXCOUNT && is_array($having)) {
                  $having[] = "COUNT(DISTINCT `". DB_COL_REPORTID ."`) <= ?";
                  $havingTypes .= "i";
                  $havingParams[] = &$val;
               } else if ($col == PARAM_MINVERSION) {
                  $where[] = $table .".`". DB_COL_INTVERSION ."` >= ?";
                  $types .= "i";
                  $params[] = &$val;
               } else if ($col == PARAM_MAXVERSION) {
                  $where[] = $table .".`". DB_COL_INTVERSION ."` <= ?";
                  $types .= "i";
                  $params[] = &$val;
               } else if(is_array($val)) {
                  $clause = $table .".`$col` IN (";
                  $array = array();
                  foreach($val as &$v) {
                     $array[] = "?";
                     if (is_numeric($v)) {
                        $types .= "i";
                     } else {
                        $types .= "s";
                     }
                     $params[] = &$v;
                  }
                  $clause .= implode(",", $array) .")";
                  $where[] = $clause;
               } else if(is_numeric($val)) {
                  $where[] = $table .".`$col` = ?";
                  $types .= "i";
                  $val = intval($val);
                  $params[] = &$val;
               } else {
                  $where[] = $table .".`$col` LIKE ?";
                  $types .= "s";
                  $params[] = &$val;
               }
            }
         }
      }
      $types .= $havingTypes;
      $params = array_merge($params, $havingParams);
   }
   
   static function foundRows() {
      $sql = "SELECT FOUND_ROWS() AS total";
      if ($stmt = self::$mysqli->prepare($sql)) {
         if ($stmt = self::$mysqli->prepare($sql)) {
            $result = self::query($stmt);
         } else {
            throw new Exception(self::$mysqli->error);
         }
         return $result[0]["total"];
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   // Prepared database procedures, alphabetically by direct object
   static function addError($error, $projectId) {
      self::connect();
      $sql = "INSERT INTO `". DB_TABLE_ERRORTYPES ."` (`". DB_COL_PROJECTID ."`, `". DB_COL_ERRORNAME ."`) VALUES (?, ?)";
      if ($stmt = self::$mysqli->prepare($sql)) {
         $stmt->bind_param("is", $projectId, $error);
         $id = self::query($stmt);
         $sql = "UPDATE `". DB_TABLE_ERRORTYPES ."` SET `". DB_COL_DUPLICATEID ."` = ? WHERE `". DB_COL_ERRORID ."` = ?";
         if ($stmt = self::$mysqli->prepare($sql)) {
            $stmt->bind_param("ii", $id, $id);
            self::query($stmt);
         } else {
            throw new Exception(self::$mysqli->error);
         }
         return $id;
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function getErrorReports($id, $filters, $order = DB_COL_REPORTID, $orderDir = "DESC", $page = 0, $perPage = ROWS_PER_PAGE) {
      self::connect();
      $sql = "SELECT * FROM `". DB_TABLE_REPORTS ."` AS r LEFT JOIN `". DB_TABLE_ERRORTYPES ."` USING (`". DB_COL_ERRORID ."`)";
      $where = array("`". DB_COL_DUPLICATEID ."` = ?");
      $params = array("", &$id);
      $types = "i";
      self::addFilters($filters, $params, $types, $where);
      if (!empty($where)) {
         $sql .= " WHERE ". implode(" AND ", $where);
      }
      if (!empty($order) && preg_match('/\w+/', $order, $matches) && $matches[0] == $order && in_array(strtoupper($orderDir), array("ASC", "DESC"))) {
         $sql .= " ORDER BY `$order` $orderDir";
      } else {
         $sql .= " ORDER BY `". DB_COL_REPORTID ."` DESC";
      }
      $sql .= " LIMIT ?, ?";
      $start = $page * $perPage;
      $types .= "ii";
      $params[] = &$start;
      $params[] = &$perPage;
      $params[0] = &$types;
      if ($stmt = self::$mysqli->prepare($sql)) {
         call_user_func_array(array($stmt, "bind_param"), $params);
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function getErrorType($id) {
      self::connect();
      $sql = "SELECT * FROM `". DB_TABLE_ERRORTYPES ."` LEFT JOIN `". DB_TABLE_PROJECTS ."` USING (`". DB_COL_PROJECTID ."`) WHERE `". DB_COL_ERRORID ."` = ?";
      $id = intval($id);
      if ($stmt = self::$mysqli->prepare($sql)) {
         $stmt->bind_param("i", $id);
         $result = self::query($stmt);
         if (count($result)) {
            return $result[0];
         } else {
            return false;
         }
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function getErrorTypes($project = 0) {
      self::connect();
      $sql = "SELECT * FROM `". DB_TABLE_ERRORTYPES ."` LEFT JOIN `". DB_TABLE_PROJECTS ."` USING (`". DB_COL_PROJECTID ."`)";
      $project = intval($project);
      if (!empty($project)) {
         $sql .= " WHERE `". DB_COL_PROJECTID ."` = ?";
      }
      if ($stmt = self::$mysqli->prepare($sql)) {
         if (!empty($project)) {
            $stmt->bind_param("i", $project);
         }
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function updateErrorTypeStatus($id, $status, $duplicateId = -1) {
      self::connect();
      if ($status == STATUS_DUPLICATE) {
         if ($duplicateId < 0 || $duplicateId == $id) {
            return false;
         }
         $sql = "UPDATE `". DB_TABLE_ERRORTYPES ."` SET `". DB_COL_STATUS ."` = ?, `". DB_COL_DUPLICATEID ."` = ? WHERE `". DB_COL_DUPLICATEID ."` = ?";
         if ($stmt = self::$mysqli->prepare($sql)) {
            $stmt->bind_param("iii", $status, $duplicateId, $id);
         }
         return self::query($stmt);
      } else {
         $sql = "UPDATE `". DB_TABLE_ERRORTYPES ."` SET `". DB_COL_STATUS ."` = ?, `". DB_COL_DUPLICATEID. "` = ? WHERE `". DB_COL_ERRORID ."` = ? OR `". DB_COL_DUPLICATEID ."` = ?";
         if ($stmt = self::$mysqli->prepare($sql)) {
            $stmt->bind_param("iiii", $status, $id, $id, $id);
         }
         return self::query($stmt);
      }
      throw new Exception(self::$mysqli->error);
   }
   
   static function addProject($project) {
      self::connect();
      $sql = "INSERT INTO `". DB_TABLE_PROJECTS ."` (`". DB_COL_PROJECTNAME ."`) VALUES (?)";
      if ($stmt = self::$mysqli->prepare($sql)) {
         $stmt->bind_param("s", $project);
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function getProjects() {
      self::connect();
      if ($stmt = self::$mysqli->prepare("SELECT `". DB_COL_PROJECTID ."`, `". DB_COL_PROJECTNAME ."` FROM `". DB_TABLE_PROJECTS ."` ORDER BY `". DB_COL_PROJECTNAME ."`")) {
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function addReport($error, $time, $project, $version, $intVersion, $metadata) {
      self::connect();
      $sql = "SELECT `". DB_COL_PROJECTID ."` FROM `". DB_TABLE_PROJECTS ."` WHERE `". DB_COL_PROJECTNAME ."` = ?";
      if ($stmt = self::$mysqli->prepare($sql)) {
         $stmt->bind_param("s", $project);
         $result = self::query($stmt);
         $projectId = -1;
         $errorId = -1;
         if (!empty($result)) {
            $projectId = $result[0][DB_COL_PROJECTID];
         } else {
            $projectId = self::addProject($project);
         }
         $sql = "SELECT `". DB_COL_ERRORID ."` FROM `". DB_TABLE_ERRORTYPES ."` WHERE `". DB_COL_ERRORNAME ."` = ? AND `". DB_COL_PROJECTID ."` = ?";
         if ($stmt = self::$mysqli->prepare($sql)) {
            $stmt->bind_param("si", $error, $projectId);
            $result = self::query($stmt);
            if (!empty($result) && is_array($result)) {
               $errorId = $result[0][DB_COL_ERRORID];
            } else {
               $errorId = self::addError($error, $projectId);
            }
            $sql = "INSERT INTO `". DB_TABLE_REPORTS ."` (`". DB_COL_ERRORID ."`, `". DB_COL_TIMESTAMP ."`, `". DB_COL_VERSION ."`, `". DB_COL_INTVERSION ."`, `". DB_COL_METADATA ."`) VALUES (?, ?, ?, ?, ?)";
            if ($stmt = self::$mysqli->prepare($sql)) {
               $date = date("Y-m-d H:i:s", $time);
               $stmt->bind_param("issis", $errorId, $date, $version, $intVersion, $metadata);
               return self::query($stmt);
            }
         } else {
            throw new Exception(self::$mysqli->error);
         }
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function getReport($id) {
      self::connect();
      $sql = "SELECT * FROM `". DB_TABLE_REPORTS ."` LEFT JOIN `". DB_TABLE_ERRORTYPES ."` USING (`". DB_COL_ERRORID ."`) WHERE `". DB_COL_REPORTID ."` = ?";
      if ($stmt = self::$mysqli->prepare($sql)) {
         $stmt->bind_param("i", $id);
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
      $sql .= " GROUP BY e.`". DB_COL_ERRORID ."`";
   }
   
   static function getReports($filters = array(), $order = "", $orderDir = "ASC", $page = 0, $perPage = ROWS_PER_PAGE) {
      self::connect();
      $sql = "SELECT SQL_CALC_FOUND_ROWS *, COUNT(DISTINCT `". DB_COL_REPORTID ."`) AS count, r.`". DB_COL_ERRORID
         ."`, r.`". DB_COL_VERSION
         ."`, e.`". DB_COL_ERRORNAME
         ."`, e.`". DB_COL_STATUS
         ."`, e.`". DB_COL_DUPLICATEID
         ."`, `". DB_COL_PROJECTNAME
         ."`, MIN(`". DB_COL_TIMESTAMP
         ."`) AS firstTime, MAX(`". DB_COL_TIMESTAMP
         ."`) AS lastTime, MIN(`". DB_COL_INTVERSION
         ."`) AS firstVersion, MAX(`". DB_COL_INTVERSION
         ."`) AS latestVersion FROM `". DB_TABLE_REPORTS
         ."` r, `". DB_TABLE_ERRORTYPES ."` e, `". DB_TABLE_ERRORTYPES ."` e2"
         ." LEFT JOIN `". DB_TABLE_PROJECTS ."` USING (`". DB_COL_PROJECTID ."`)";
      $where = array("r.`". DB_COL_ERRORID ."` = e2.`". DB_COL_ERRORID ."` AND e2.`". DB_COL_DUPLICATEID ."` = e.`". DB_COL_ERRORID ."`");
      $having = array();
      $params = array("");
      $types = "";
      $groupBy = DB_COL_DUPLICATEID;
      self::addFilters($filters, $params, $types, $where, $having);
      if (isset($filters["e"]) && isset($filters["e"][DB_COL_STATUS]) && is_array($filters["e"][DB_COL_STATUS]) && in_array(STATUS_DUPLICATE, $filters["e"][DB_COL_STATUS])) {
         // When Duplicate status is explicitly displayed, show duplicates as line items instead of grouped
         $where[0] = "r.`". DB_COL_ERRORID ."` = e.`". DB_COL_ERRORID ."`";
         $groupBy = DB_COL_ERRORID;
      }
      if (!empty($where)) {
         $sql .= " WHERE ". implode(" AND ", $where);
      }
      $sql .= " GROUP BY e.`$groupBy`";
      if (!empty($having)) {
         $sql .= " HAVING ". implode(" AND ", $having);
      }
      if (!empty($order) && in_array($order, array(DB_COL_STATUS, DB_COL_VERSION, DB_COL_REPORTID, DB_COL_PROJECTID, DB_COL_ERRORID, "firstTime", "lastTime", "firstVersion", "latestVersion", "count")) && in_array(strtoupper($orderDir), array("ASC", "DESC"))) {
         if (!in_array($order, array("firstTime", "lastTime", "firstVersion", "latestVersion", "count"))) {
            $order = "e.`". $order ."`";
         } else {
            $order = "`". $order ."`";
         }
         $sql .= " ORDER BY $order $orderDir";
      } else {
         $sql .= " ORDER BY lastTime DESC";
      }
      $sql .= " LIMIT ?, ?";
      $start = $page * $perPage;
      $params[] = &$start;
      $params[] = &$perPage;
      $types .= "ii";
      $params[0] = &$types;
      if ($stmt = self::$mysqli->prepare($sql)) {
         call_user_func_array(array($stmt, "bind_param"), $params);
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   static function getTables() {
      self::connect();
      if ($stmt = self::$mysqli->prepare("SHOW TABLES")) {
         return self::query($stmt);
      } else {
         throw new Exception(self::$mysqli->error);
      }
   }
   
   // Setup function: check for existing table, and set it up if it's not there
   
   static function checkSetup() {
      $tables = self::getTables();
      foreach($tables as $table) {
         if (current($table) == DB_TABLE_REPORTS) {
            return false;
         }
      }
      // Perform setup
      $sql = "CREATE TABLE IF NOT EXISTS `". DB_TABLE_PROJECTS ."` (`". DB_COL_PROJECTID ."` smallint(5) unsigned NOT NULL, `". DB_COL_PROJECTNAME ."` varchar(255) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      $sql = "ALTER TABLE `". DB_TABLE_PROJECTS ."` ADD PRIMARY KEY (`". DB_COL_PROJECTID ."`)";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      $sql = "ALTER TABLE `". DB_TABLE_PROJECTS ."` MODIFY `". DB_COL_PROJECTID ."` smallint(5) unsigned NOT NULL AUTO_INCREMENT";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      
      $sql = "CREATE TABLE IF NOT EXISTS `". DB_TABLE_ERRORTYPES ."` (`". DB_COL_ERRORID ."` int(10) unsigned NOT NULL, `". DB_COL_PROJECTID ."` smallint(5) unsigned NOT NULL, `". DB_COL_ERRORNAME ."` varchar(255) NOT NULL, `". DB_COL_STATUS ."` tinyint(1) unsigned NOT NULL, `". DB_COL_DUPLICATEID ."` int(10) unsigned NOT NULL, FOREIGN KEY (`". DB_COL_PROJECTID ."`) REFERENCES `". DB_TABLE_PROJECTS ."`(`". DB_COL_PROJECTID ."`) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      $sql = "ALTER TABLE `". DB_TABLE_ERRORTYPES ."` ADD PRIMARY KEY (`". DB_COL_ERRORID ."`), ADD KEY `". DB_COL_PROJECTID ."` (`". DB_COL_PROJECTID ."`)";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      $sql = "ALTER TABLE `". DB_TABLE_ERRORTYPES ."` MODIFY `". DB_COL_ERRORID ."` int(10) unsigned NOT NULL AUTO_INCREMENT";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      
      $sql = "CREATE TABLE IF NOT EXISTS `". DB_TABLE_REPORTS ."` (`". DB_COL_REPORTID ."` int(10) unsigned NOT NULL, `". DB_COL_ERRORID ."` int(10) unsigned NOT NULL, `". DB_COL_TIMESTAMP ."` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, `". DB_COL_VERSION ."` varchar(255) NOT NULL, `". DB_COL_INTVERSION ."` int(10) unsigned NOT NULL, `". DB_COL_METADATA ."` text NOT NULL, FOREIGN KEY (`". DB_COL_ERRORID ."`) REFERENCES `". DB_TABLE_ERRORTYPES ."`(`". DB_COL_ERRORID ."`) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      $sql = "ALTER TABLE `". DB_TABLE_REPORTS ."` ADD PRIMARY KEY (`". DB_COL_REPORTID ."`), ADD KEY `". DB_COL_ERRORID ."` (`". DB_COL_ERRORID ."`)";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      $sql = "ALTER TABLE `". DB_TABLE_REPORTS ."` MODIFY `". DB_COL_REPORTID ."` int(10) unsigned NOT NULL AUTO_INCREMENT";
      $stmt = self::$mysqli->prepare($sql);
      self::query($stmt);
      
      return true;
   }
}
?>
