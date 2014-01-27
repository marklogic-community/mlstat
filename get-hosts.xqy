xquery version "1.0-ml";
declare namespace an="http://marklogic.com/xdmp/assignments";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace xh="http://www.w3.org/1999/xhtml";


declare variable $HOSTS as element (ho:host)*  := (xdmp:read-cluster-config-file("hosts.xml")/ho:hosts/ho:host);

for $host in $HOSTS
return $host/ho:host-name/text()
