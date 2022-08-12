# Copyright (c) 2022 Oleg Nemanov <lego12239@yandex.ru>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# https://github.com/lego12239/getopt.tcl


namespace eval getopt {
proc mkctx {optsspec {prms ""}} {
	set ctx [dict create ospec {}]

	dict set ctx prms [_create_prms $prms]

	dict set ctx ospec [_compile_optsspec $optsspec]

	# 0 - start of a next list item, wait "-"
	# 1 - got a first "-", wait "-" or a char
	# 2 - wait a char after first "-" (short option)
	# 3 - wait a short option mandatory argument
	# 4 - wait a short option optional argument
	# 5 - got an option argument
	# 10 - got a second "-", wait an option name
	# 11 - wait a long option mandatory argument
	# 12 - wait a long option optional argument
	# 13 - got an unknown long option
	# 14 - got a long option with no argument
	# 100 - any other char/state exclude described here(non option char)
	# 111 - finish
	dict set ctx state 0
	dict set ctx idx 0
	dict set ctx pos 0

	return $ctx
}

proc _create_prms {prms_new} {
	set prms [dict create \
	  err_on_unknown_opt 0]

	dict for {k v} $prms_new {
		switch -exact $k {
		"err_on_unknown_opt" {
			if {$v} {
				dict set prms err_on_unknown_opt 1
			} else {
				dict set prms err_on_unknown_opt 0
			}
		}
		default {
			throw {GETOPT WRONG_PRM} "Wrong parameter '$k'"
		}
		}
	}

	return $prms
}

proc _compile_optsspec {optsspec} {
	set ospec ""

	dict for {k v} $optsspec {
		set names [split $k]
		foreach name $names {
			if {$name eq ""} {
				continue
			}
			if {[string equal -length 2 "--" $name]} {
				set name [list "--" [string range $name 2 end]]
			} elseif {[string equal -length 1 "-" $name]} {
				set name [list "-" [string range $name 1 end]]
				if {[string length [lindex $name 1]] > 1} {
					throw {GETOPT OPTSSPEC_ERR}\
					  [string cat "Short option with long name "\
					    "'[lindex $name 1]' in spec '$k'"]
				}
			} else {
				throw {GETOPT OPTSSPEC_ERR}\
				  "Nor short option nor long option '$name' in spec '$k'"
			}
			if {[dict exists $ospec {*}$name]} {
				throw {GETOPT OPTSSPEC_ERR}\
				  "Option '[join $name ""]' from spec '$k' already exist"
			}
			set vtype [lindex $v 0]
			if {[lsearch -exact {0 1 2} $vtype] < 0} {
				throw {GETOPT OPTSSPEC_ERR}\
				  [string cat "Option '[join $name ""]' from spec '$k' "\
				    "has wrong option "\
				    "argument type: it should be 0 for 'no argument', "\
				    "1 for 'mandatory argument' or 2 for 'optional argument'"]
			}
			dict set ospec {*}$name [list $vtype $k]
		}
	}

	return $ospec
}

proc next {_ctx _argv} {
	upvar $_ctx ctx
	upvar $_argv argv
	# An specified option name(needed mostly for error messages)
	set oname ""

	if {[dict get $ctx state] == 111} {
		return {}
	}

	while {[dict get $ctx idx] < [llength $argv]} {
		set arg [lindex $argv [dict get $ctx idx]]
		set len [string length $arg]
		while {[dict get $ctx pos] < $len} {
			set c [string index $arg [dict get $ctx pos]]
			switch -exact [dict get $ctx state] {
			0 {
				if {$c eq "-"} {
					dict set ctx state 1
				} else {
					dict set ctx pos $len
					dict set ctx state 100
				}
			}
			1 {
				if {$c eq "-"} {
					dict set ctx state 10
				} else {
					dict set ctx state 2
					dict incr ctx pos -1
				}
			}
			2 {
				set ospec [_get_ospec ctx [list "-" $c]]
				set oname "-$c"
				if {[llength $ospec] == 0} {
					if {[dict get $ctx prms err_on_unknown_opt]} {
						throw {GETOPT UNKNOWN_OPT} "Option '$oname' is unknown"
					}
					dict incr ctx pos
					return [list $oname]
				}
				if {[lindex $ospec 0] == 0} {
					dict incr ctx pos
					return [list [lindex $ospec 1]]
				}
				if {[lindex $ospec 0] == 1} {
					dict set ctx state 3
				} else {
					dict set ctx state 4
				}
			}
			3 -
			4 {
				set optarg [string range $arg [dict get $ctx pos] end]
				dict set ctx state 5
				dict set ctx pos $len
			}
			10 {
				set eqpos [string first = $arg]
				if {$eqpos < 0} {
					set oname [string range $arg [dict get $ctx pos] end]
					dict set ctx pos $len
				} else {
					set oname [string range $arg [dict get $ctx pos] $eqpos-1]
					dict set ctx pos $eqpos
				}
				set ospec [_get_ospec ctx [list "--" $oname]]
				set oname "--$oname"
				if {[llength $ospec] == 0} {
					if {[dict get $ctx prms err_on_unknown_opt]} {
						throw {GETOPT UNKNOWN_OPT} "Option '$oname' is unknown"
					}
					dict set ctx state 13
					dict set ctx pos $len
				} elseif {[lindex $ospec 0] == 0} {
					if {$eqpos >= 0} {
						throw {GETOPT OPT_WITH_ARG}\
						  "Option '$oname' shouldn't has an argument"
					}
					dict set ctx state 14
				} elseif {[lindex $ospec 0] == 1} {
					dict set ctx state 11
				} else {
					dict set ctx state 12
				}
			}
			11 -
			12 {
				set optarg [string range $arg [dict get $ctx pos] end]
				dict set ctx state 5
				dict set ctx pos $len
			}
			}
			dict incr ctx pos
		}
		# TODO: refactor the code below
		dict set ctx pos 0
		# Remove option and its arg from argv
		switch -exact [dict get $ctx state] {
		0 -
		100 {
			dict incr ctx idx
		}
		default {
			set argv [lreplace $argv [dict get $ctx idx] [dict get $ctx idx]]
		}
		}

		switch -exact [dict get $ctx state] {
		1 {
			throw {GETOPT UNCOMPLETED_OPT} "Uncompleted short option"
		}
		3 -
		11 {
		}
		4 -
		12 {
			dict set ctx state 0
			return [list [lindex $ospec 1]]
		}
		5 {
			dict set ctx state 0
			return [list [lindex $ospec 1] $optarg]
		}
		10 {
			dict set ctx state 111
			return {}
		}
		13 {
			dict set ctx state 0
			return [list $oname]
		}
		14 {
			dict set ctx state 0
			return [list [lindex $ospec 1]]
		}
		default {
			dict set ctx state 0
		}
		}
	}
	switch -exact [dict get $ctx state] {
	3 -
	11 {
		throw [list GETOPT MAND_ARG_IS_MISSED $oname]\
		  "Mandatory argument for option $oname is missed"
	}
	}
	dict set ctx state 111

	return {}
}

proc _get_ospec {_ctx oname} {
	upvar $_ctx ctx

	if {[dict exists $ctx ospec {*}$oname]} {
		return [dict get $ctx ospec {*}$oname]
	}
	return {}
}
}

package provide getopt 1.0.2
