#!/usr/bin/tclsh

lappend auto_path [pwd]
package require getopt


if {[llength $argv] == 0} {
	set argv {-abc arg -d val -l name}
}

getopt::for {oname oval with_val} argv {
	set with_val 0

	switch $oname {
	-b -
	-d {
		puts "$oname = $oval"
		set with_val 1
	}
	-D {
		error "Bad option: $oname"
	}
	-q {
		break
	}
	default {
		puts "$oname"
	}
	}
}

puts "argv now is: $argv"
