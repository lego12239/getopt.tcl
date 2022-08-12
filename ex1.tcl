#!/usr/bin/tclsh

lappend auto_path [pwd]
package require getopt

set optsspec [dict create\
  "-v --version" 0\
  "-h --help" 0\
  "-d --debug" 1\
  "-V --verbose" 2]

set ctx [getopt::mkctx $optsspec]

while {[llength [set ov [getopt::next ctx argv]]] > 0} {
	puts "([llength $ov])'[lindex $ov 0]'='[lindex $ov 1]'"
}
