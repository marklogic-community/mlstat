xquery version "1.0-ml";
declare namespace an="http://marklogic.com/xdmp/assignments";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace xh="http://www.w3.org/1999/xhtml";

declare variable $SUPPORT := (
    for $i in ('databases', 'assignments') return xdmp:read-cluster-config-file(concat($i, '.xml')));

declare variable $ASSIGNMENTS as element(an:assignment)* :=
  ($SUPPORT/an:assignments)[1]/an:assignment
;

declare variable $DATABASES as element(db:database)* :=
  ($SUPPORT/db:databases)[1]/db:database
;


declare variable $HOSTS as element (ho:host)*  := (xdmp:read-cluster-config-file("hosts.xml")/ho:hosts/ho:host);


declare function local:hm-ratio($hits as xs:unsignedLong,
         $misses as xs:unsignedLong)
as xs:string?
{
  try {
    if(empty($hits) or empty($misses)) then
      "0 0"
    else if($hits ne 0 and $misses eq 0) then
      "100 0"
    else if($hits eq 0 and $misses eq 0) then
      "0 0"
    else
      let $x := ($hits*100) div ($hits + $misses)
      let $y := ($misses*100) div ($hits + $misses)
      return string(concat (round-half-to-even($x,0),' ',round-half-to-even($y,0)))
  } catch($e) { "0 0" }
};


let $dbname:= normalize-space(xdmp:get-request-field("dbname",""))
let $hostname:= normalize-space(xdmp:get-request-field("hostname",""))
let $replica:= normalize-space(xdmp:get-request-field("replica","no"))



for $database in $DATABASES [db:database-name eq $dbname ] 
let $hostid as xs:unsignedLong* :=  if ($hostname ne "" ) 
      then $HOSTS [ ho:host-name = $hostname ]/ho:host-id
      else 0


let $all-node-assignments := if ($hostname ne "" )
     then $ASSIGNMENTS [ an:host = $hostid  ]
     else $ASSIGNMENTS 
      
  
let $all-forest-ids  as xs:unsignedLong* := $all-node-assignments/an:forest-id


let $forest-status := if ($replica eq "no" )
      then for $f in $all-forest-ids
         let $fs := xdmp:forest-status($f)
         return ( if (($fs/fs:database-id = $database/db:database-id) and ($fs/fs:state eq "open")) then $fs else () )
      else for $f in $all-forest-ids
         let $fs := xdmp:forest-status($f)
         return ( if (($fs/fs:database-id = $database/db:database-id) and (($fs/fs:state eq "sync replicating") or ($fs/fs:state eq "async replicating") or ($fs/fs:state eq "wait replication"))) then $fs else () )


let $forest-ids  as xs:unsignedLong* := for $fs in $forest-status
            return $fs/fs:forest-id


let $forest-counts := for $f in $forest-ids return xdmp:forest-counts($f)


let $forest-open-count := sum(
  for $f in $forest-status return
 if ($f/fs:state eq "open")
  then 1
  else 0
)

let $journal-write-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:journal-write-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:journal-write-time
)
let $save-write-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:save-write-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:save-write-time
)
let $merge-write-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:merge-write-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:merge-write-time
)
let $merge-read-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:merge-read-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:merge-read-time
)
let $query-read-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:query-read-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:query-read-time
)
let $backup-read-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:backup-read-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:backup-read-time
)
let $backup-write-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:backup-write-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:backup-write-time
)
let $restore-read-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:restore-read-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:restore-read-time
)
let $restore-write-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:restore-write-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:restore-write-time
)
let $large-read-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:large-read-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:large-read-time
)
let $large-write-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:large-write-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:large-write-time
)
let $replication-receive-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:replication-receive-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:replication-receive-time
)
let $replication-send-time := sum(
  for $f in $forest-status return
 if (empty($f/fs:replication-send-time))
  then xs:dayTimeDuration("PT0.00S")
  else $f/fs:replication-send-time
)

let $docs := sum($forest-counts/fs:document-count)

let $merge-read-bytes := sum($forest-status/fs:merge-read-bytes)
let $query-read-bytes := sum($forest-status/fs:query-read-bytes)
let $backup-read-bytes := sum($forest-status/fs:backup-read-bytes)
let $restore-read-bytes := sum($forest-status/fs:restore-read-bytes)
let $replication-receive-bytes := sum($forest-status/fs:replication-receive-bytes)
let $large-read-bytes := sum($forest-status/fs:large-read-bytes)

let $merge-write-bytes := sum($forest-status/fs:merge-write-bytes)
let $journal-write-bytes := sum($forest-status/fs:journal-write-bytes)
let $save-write-bytes := sum($forest-status/fs:save-write-bytes)
let $backup-write-bytes := sum($forest-status/fs:backup-write-bytes)
let $restore-write-bytes := sum($forest-status/fs:restore-write-bytes)
let $replication-send-bytes := sum($forest-status/fs:replication-send-bytes)
let $large-write-bytes := sum($forest-status/fs:large-write-bytes)

let $query-read-rate := sum($forest-status/fs:query-read-rate)
let $merge-read-rate := sum($forest-status/fs:merge-read-rate)
let $backup-read-rate := sum($forest-status/fs:backup-read-rate)
let $restore-read-rate := sum($forest-status/fs:restore-read-rate)
let $replication-receive-rate := sum($forest-status/fs:replication-receive-rate)
let $large-read-rate := sum($forest-status/fs:large-read-rate)

let $journal-write-rate := sum($forest-status/fs:journal-write-rate)
let $merge-write-rate := sum($forest-status/fs:merge-write-rate)
let $save-write-rate := sum($forest-status/fs:save-write-rate)
let $backup-write-rate := sum($forest-status/fs:backup-write-rate)
let $restore-write-rate := sum($forest-status/fs:restore-write-rate)
let $replication-send-rate := sum($forest-status/fs:replication-send-rate)
let $large-write-rate := sum($forest-status/fs:large-write-rate)

let $stand-count := count($forest-status/fs:stands/fs:stand)
let $del-frag-count := count($forest-status/fs:stands/fs:stand)
let $merge-count := count($forest-status/fs:merges/fs:merge)
let $total-forests:= count($forest-counts)
let $in-memory-mb := sum($forest-status/fs:stands/fs:stand/fs:memory-size)
let $disk-size := sum($forest-status/fs:stands/fs:stand/fs:disk-size)
let $list-cache-hits := sum($forest-status/fs:stands/fs:stand/fs:list-cache-hits)
let $list-cache-misses := sum($forest-status/fs:stands/fs:stand/fs:list-cache-misses)
let $compressed-tree-cache-hits := sum($forest-status/fs:stands/fs:stand/fs:compressed-tree-cache-hits)
let $compressed-tree-cache-misses := sum($forest-status/fs:stands/fs:stand/fs:compressed-tree-cache-misses)

let $query-read-load := sum($forest-status/fs:query-read-load)
let $backup-read-load := sum($forest-status/fs:backup-read-load)
let $restore-read-load := sum($forest-status/fs:restore-read-load)
let $replication-receive-load := sum($forest-status/fs:replication-receive-load)
let $large-read-load := sum($forest-status/fs:large-read-load)
let $merge-read-load := sum($forest-status/fs:merge-read-load)

let $journal-write-load := sum($forest-status/fs:journal-write-load)
let $save-write-load := sum($forest-status/fs:save-write-load)
let $merge-write-load := sum($forest-status/fs:merge-write-load)
let $backup-write-load := sum($forest-status/fs:backup-write-load)
let $restore-write-load := sum($forest-status/fs:restore-write-load)
let $replication-send-load := sum($forest-status/fs:replication-send-load)
let $large-write-load := sum($forest-status/fs:large-write-load)

let $merge-read-ms :=  xs:dayTimeDuration($merge-read-time) div xs:dayTimeDuration("PT0.001S")  
let $query-read-ms :=  xs:dayTimeDuration($restore-read-time) div xs:dayTimeDuration("PT0.001S")
let $backup-read-ms := xs:dayTimeDuration($backup-read-time) div xs:dayTimeDuration("PT0.001S") 
let $restore-read-ms := xs:dayTimeDuration($restore-read-time) div xs:dayTimeDuration("PT0.001S")
let $large-read-ms :=  xs:dayTimeDuration($large-read-time) div xs:dayTimeDuration("PT0.001S") 
let $replication-receive-ms := xs:dayTimeDuration($replication-receive-time) div xs:dayTimeDuration("PT0.001S") 

let $journal-write-ms := xs:dayTimeDuration($journal-write-time) div xs:dayTimeDuration("PT0.001S")
let $save-write-ms :=  xs:dayTimeDuration($save-write-time) div xs:dayTimeDuration("PT0.001S") 
let $merge-write-ms := xs:dayTimeDuration($merge-write-time) div xs:dayTimeDuration("PT0.001S")
let $backup-write-ms := xs:dayTimeDuration($backup-write-time) div xs:dayTimeDuration("PT0.001S") 
let $restore-write-ms := xs:dayTimeDuration($restore-write-time) div xs:dayTimeDuration("PT0.001S")
let $large-write-ms := xs:dayTimeDuration($large-write-time) div xs:dayTimeDuration("PT0.001S")
let $replication-send-ms := xs:dayTimeDuration($replication-send-time) div xs:dayTimeDuration("PT0.001S") 
let $reindex := (xdmp:get-request-field("reindex", "") eq "show")
let $rebalance := (xdmp:get-request-field("rebalance", "") eq "show")
let $fcounts :=
      for $f in $forest-ids
      where ($forest-status[fs:forest-id eq $f]/fs:state =
              ("open", "sync replicating",
               "async replicating", "wait replication",
               "open replica", "syncing replica"))
      return xdmp:forest-counts($f, (), (( 
	(if ($reindex) then "preview-reindexer" else ()),
	(if ($rebalance) then "preview-rebalancer" else () )))
     )
let $active-frags := sum($fcounts/fs:stands-counts/fs:stand-counts/fs:active-fragment-count)
let $deleted-frags := sum($fcounts/fs:stands-counts/fs:stand-counts/fs:deleted-fragment-count)
let $reindex-frag-count  := sum($fcounts/fs:reindex-refragment-fragment-count)


return concat ($database/db:database-name ,' ',$docs, ' ',$total-forests,' ',$stand-count,' ',
$merge-count,' ',$merge-read-bytes,' ',$merge-write-bytes,' ',$journal-write-bytes, ' ',
$journal-write-rate,' ',$save-write-rate, ' ',$save-write-bytes,' ',$query-read-bytes,' ',$in-memory-mb,' ',$disk-size,' ',
$list-cache-hits,' ',$list-cache-misses,' ',local:hm-ratio($list-cache-hits, $list-cache-misses),' ',$compressed-tree-cache-hits,' ',$compressed-tree-cache-misses,' ',local:hm-ratio($compressed-tree-cache-hits, $compressed-tree-cache-misses),
' ',$journal-write-ms,' ',$save-write-ms,' ',$merge-write-ms,' ',$merge-read-ms, ' ',$query-read-ms,
' ',$query-read-rate,' ',$merge-read-rate,' ',$merge-write-rate,' ',$query-read-load,' ',$journal-write-load,' ',$save-write-load,' ',$merge-read-load,' ',$merge-write-load,' ',$forest-open-count,' ',
$backup-read-bytes,' ',$backup-write-bytes,' ',$backup-read-rate,' ',$backup-write-rate,' ',$backup-write-ms,' ',$backup-read-ms,' ',$backup-read-load,' ',$backup-write-load,' ',
$restore-read-bytes,' ',$restore-write-bytes,' ',$restore-read-rate,' ',$restore-write-rate,' ',$restore-write-ms,' ',$restore-read-ms,' ',$restore-read-load,' ',$restore-write-load,' ',
$large-read-bytes,' ',$large-write-bytes,' ',$large-read-rate,' ',$large-write-rate,' ',$large-write-ms,' ',$large-read-ms,' ',$large-read-load,' ',$large-write-load,' ',
$replication-receive-bytes,' ',$replication-receive-rate,' ',$replication-receive-ms,' ',$replication-receive-load,' ',
$replication-send-bytes,' ',$replication-send-rate,' ',$replication-send-ms,' ',$replication-send-load,' ',$active-frags,' ',$deleted-frags,' ',$reindex-frag-count,codepoints-to-string(10));
