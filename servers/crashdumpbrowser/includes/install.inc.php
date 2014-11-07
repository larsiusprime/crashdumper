<?php
/*! install.inc.php | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
// Checks if installation needs to be performed, and performs it if so
include_once("db.inc.php");

if (!file_exists("reports")) {
   mkdir("reports");
}

if (db::checkSetup()) {
?>
<!DOCTYPE HTML>
<html>
<head>
   <title>Crashdump Browser</title>
</head>
<body>
   <h1>Installation complete!</h1>
   <p>You can refresh this page to start browsing crash reports (or rather, you could if you had any).</p>
</body>
</html>
<?php
   die();
}