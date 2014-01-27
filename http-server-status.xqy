xquery version "1.0-ml";

(: Copyright 2002-2012 MarkLogic Corporation.  All Rights Reserved. :)


declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
declare namespace admin="http://marklogic.com/xdmp/admin";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace ss="http://marklogic.com/xdmp/status/server";



declare variable $HOSTS as element (ho:host)*  := (xdmp:read-cluster-config-file("hosts.xml")/ho:hosts/ho:host);


declare function local:hm-ratio($hits,
         $misses)
as xs:string
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


let $http-servername := normalize-space(xdmp:get-request-field("http-servername",""))
let $xdbc-servername := normalize-space(xdmp:get-request-field("xdbc-servername",""))
let $hostname:= normalize-space(xdmp:get-request-field("hostname",""))

let $hostid as xs:unsignedLong* :=  if ($hostname ne "" ) 
      then $HOSTS [ ho:host-name = $hostname ]/ho:host-id
      else 0


let       $type :=
        if($http-servername ne "") then "http"
        else if($xdbc-servername ne "") then "xdbc"
        else "http"


let $group := xs:unsignedLong(xdmp:get-request-field("group","0")),
    $gid := if ($group eq 0) then xs:unsignedLong(xdmp:host-status(xdmp:host())/hs:group-id)
            else $group

let $gs := xdmp:read-cluster-config-file("groups.xml")

let $id := if($type = "http") then xs:unsignedLong($gs/gr:groups/gr:group/gr:http-servers/gr:http-server[gr:http-server-name eq $http-servername ]/gr:http-server-id)
     else if ($type = "xdbc") then xs:unsignedLong($gs/gr:groups/gr:group/gr:xdbc-servers/gr:xdbc-server[gr:xdbc-server-name eq $xdbc-servername]/gr:xdbc-server-id)
        else xs:unsignedLong(0)


let $http-status := xdmp:server-status($hostid,$id)
let $req-count:= count($http-status/ss:request-statuses/ss:request-status)
let $up-count := count($http-status/ss:request-statuses/ss:request-status[ss:update eq true()])

let $th := $http-status/ss:expanded-tree-cache-hits
let $tm := $http-status/ss:expanded-tree-cache-misses
let $ph := $http-status/ss:fs-program-cache-hits
let $pm := $http-status/ss:fs-program-cache-misses
let $dh := $http-status/ss:db-program-cache-hit
let $dm := $http-status/ss:db-program-cache-misses
let $eh := $http-status/ss:env-program-cache-hits
let $em := $http-status/ss:env-program-cache-misses
let $mh := $http-status/ss:fs-main-module-seq-cache-hits
let $mm := $http-status/ss:fs-main-module-seq-cache-misses
let $dsh := $http-status/ss:db-main-module-seq-cache-hits
let $dsm := $http-status/ss:db-main-module-seq-cache-hits
let $lh := $http-status/ss:fs-lib-module-cache-hits
let $lm := $http-status/ss:fs-lib-module-cache-misses
let $xh := $http-status/ss:db-lib-module-cache-hits
let $xm := $http-status/ss:db-lib-module-cache-misses


return if ($type = "http") then concat ($http-status/ss:server-name ,' ',$req-count,' ',$up-count,' ',$http-status/ss:backlog,' ',$http-status/ss:threads,' ', $http-status/ss:request-rate,' ', local:hm-ratio($th, $tm),' ',  $http-status/ss:expanded-tree-cache-hits,' ',$http-status/ss:expanded-tree-cache-misses,' ',local:hm-ratio($ph, $pm),' ',$http-status/ss:fs-program-cache-hits, ' ',$http-status/ss:fs-program-cache-misses, ' ',local:hm-ratio($dh, $dm),' ',$http-status/ss:db-program-cache-hits, ' ',$http-status/ss:db-program-cache-misses, ' ',local:hm-ratio($eh, $em),' ',$http-status/ss:env-program-cache-hits, ' ',$http-status/ss:env-program-cache-misses, ' ',local:hm-ratio($mh, $mm),' ',$http-status/ss:fs-main-module-seq-cache-hits, ' ',$http-status/ss:fs-main-module-seq-cache-misses, ' ',local:hm-ratio($dsh, $dsm),' ',$http-status/ss:db-main-module-seq-cache-hits, ' ',$http-status/ss:db-main-module-seq-cache-misses, ' ',local:hm-ratio($lh, $lm),' ',$http-status/ss:fs-lib-module-cache-hits, ' ',$http-status/ss:fs-lib-module-cache-misses, ' ',local:hm-ratio($xh, $xm),' ',$http-status/ss:db-lib-module-cache-hits, ' ',$http-status/ss:db-lib-module-cache-misses,codepoints-to-string(10))
else concat ($http-status/ss:server-name ,' ',$req-count,' ',$up-count,' ',$http-status/ss:backlog,' ',$http-status/ss:threads,' ', $http-status/ss:request-rate,' ',local:hm-ratio($th, $tm),' ', $http-status/ss:expanded-tree-cache-hits,' ',$http-status/ss:expanded-tree-cache-misses,' ',local:hm-ratio($ph, $pm),' ',$http-status/ss:fs-program-cache-hits, ' ',$http-status/ss:fs-program-cache-misses, ' ',local:hm-ratio($dh, $dm),' ',$http-status/ss:db-program-cache-hits, ' ',$http-status/ss:db-program-cache-misses, ' ',local:hm-ratio($mh, $mm),' ',$http-status/ss:fs-main-module-seq-cache-hits, ' ',$http-status/ss:fs-main-module-seq-cache-misses, ' ',local:hm-ratio($dsh, $dsm),' ',$http-status/ss:db-main-module-seq-cache-hits, ' ',$http-status/ss:db-main-module-seq-cache-misses, ' ',local:hm-ratio($lh, $lm),' ',$http-status/ss:fs-lib-module-cache-hits, ' ',$http-status/ss:fs-lib-module-cache-misses, ' ',local:hm-ratio($xh, $xm),' ',$http-status/ss:db-lib-module-cache-hits, ' ',$http-status/ss:db-lib-module-cache-misses, codepoints-to-string(10));



