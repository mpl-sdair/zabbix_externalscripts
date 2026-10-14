#!/usr/bin/php
<?php

$countURL = "http://localhost:9200/beacon_log.*/_count?pretty";
$baseCountQuery = '{"query": { "bool":{"must":[{"terms": { "_index": ["%s", "%s"]}},{"term": { "eid" : "e"}},{"range": { "tm": {"gte": %d,"lt": %d}}}]}}}';
$baseIndex = 'beacon_log.%s';

$date = date("Y/m/d");
$hour = date("H");

$workcurrentDay = strtotime($date);
$workprivDay = strtotime('- 1day' , $workcurrentDay);
	
$to = strtotime($date . " " . $hour . ":00:00");
$from = strtotime('- 1 hour' , $to);

//echo $workcurrentDay.PHP_EOL;
//echo $workprivDay.PHP_EOL;
//echo $from.PHP_EOL;
//echo $to.PHP_EOL;

$index1 = sprintf($baseIndex, date('Ymd', $workprivDay));
$index2 = sprintf($baseIndex, date('Ymd', $workcurrentDay));


$countQuery = sprintf($baseCountQuery, $index1, $index2, $from, $to);

//echo $countQuery.PHP_EOL;


$contextData = array (
                      'method' => 'GET',
                      'header' => "Content-Type: application/json\r\n",
                      'content'=> $countQuery
                      );
$context = stream_context_create (array ( 'http' => $contextData ));
	
$result = file_get_contents($countURL, false, $context);
	
$resultArray = json_decode($result,true);
$count = $resultArray["count"];


echo $count;

?>

