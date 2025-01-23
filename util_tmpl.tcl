#!/usr/bin/tclsh

lappend auto_path ~/work/libs/tcl/
package require getopt


proc show_help {} {
	puts "[file tail $::argv0] \[OPTIONS] ARG"
	puts " OPTIONS:"
}

proc getopt_cb {_priv oname oval} {
	upvar 2 $_priv priv

	switch $oname {
	-h -
	--help {
		show_help
		exit 0
	}
	-v -
	--version {
		puts "Version 0.1"
		exit 0
	}
	default {
		puts stderr "Unknown option: $oname"
		exit 1
	}
	}

	return 0
}

#################################################################
# MAIN
#################################################################
set priv {}
getopt::parse {getopt_cb priv} argv

if {[llength $argv] != 1} {
	puts stderr "Not enough arguments!"
	exit 1
}
