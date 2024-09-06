#!/usr/bin/tclsh

lappend auto_path [pwd]
package require getopt

proc opts_parse {_priv oname oval} {
 upvar 2 $_priv priv

 switch $oname {
 b -
 d {
  lappend priv [list $oname $oval]
  return 1
 }
 default {
  lappend priv $oname
 }
 }

 return 0
}

set argv {-abc arg -d val -l name}
set priv {}
getopt::parse {opts_parse priv} argv
puts "opts: $priv"
puts "argv now is: $argv"
