################
## Hallowvale ##
################

############
# Commands #
############
#
# (Commands only work in #Hallowvale)
#
# !enter
# Start a new game, or join in.
#
# !kill <person>
# Kill a person at night.
#
# !heal <person>
# Heal a person at night.
#
# !arrest <person>
# Det can use every other night to
# prevent a person from voting and
# to tell his identity at the end
# of the day.
#
# <Admin>
#
# !boot <person>
# Forces a player out of the game
#
# !unboot <person>
# Joins player into game (citizen.)
#
############

## NOTE ##
# For sake of shortness, mafia will be used throughout instead of "hallowvale."

## Variables ##


## Internal Variables ##
set mafiastarted 0
set staff {BaconServ WASTED}
set mod {BontuTheBOT Andreoli Flinty}
set players {}
set dead {}
set mafia {}
set alivemafia {}
set hitlist {}
set unconscious {}
set hangers {}
array set votes {}
set stage "night"
set doc ""
set cop ""
set saved ""
set revive ""

proc nightfix {} {
    global hitlist unconscious hangers votes stage saved revive
    set hitlist {}
    set unconscious {}
    set hangers {}
    array unset votes
    array set votes {}
    set stage "night"
    set saved ""
    set revive ""
}



## Convinence functions ##
proc notice {nick msg} { putserv "NOTICE $nick :$msg" }
proc msgchan {chan msg} { putserv "PRIVMSG $chan :$msg" }
proc msgnick {nick msg} { putserv "PRIVMSG $nick :$msg" }
proc getstat {hand stat} { return [getuser $hand XTRA $stat] }
proc setstat {hand stat setting} { return [setuser $hand XTRA $stat $setting] }


## Bindings ##
bind pub - !enter pub:enter
bind pub - !boot pub:boot
bind pub - !unboot pub:unboot
bind pub - !end pub:end
bind pub - !hang pub:hang
bind msg - !bc msg:broadcast
bind msg - !kill msg:kill
bind msg - !heal msg:heal
bind msg - !revive msg:revive
bind msg - !arrest msg:arrest
bind msg - !z msg:zamchat
bind pub - !bug pub:bug
bind pub - .bug pub:bug
bind msg - !bug msg:bug
bind msg - .bug msg:bug

## Functions ##

proc pub:enter { nick user hand chan text } {
    global mafiastarted players
    if {![isstaff $hand] && $mafiastarted == 0} {notice $nick "The game is currently in staff-mode, only an admin can start a game."; return 0}
    if {$chan != "#Hallowvale"} {notice $nick "Please play on #Hallowvale! :)"; return 0}
    if {$mafiastarted == 0} {
        set mafiastarted 1;                                                     # Show we're in the signup phase
        msgchan $chan "\0030,1\002Hallowvale signups are starting, use !enter to sign up!"
        utimer 30 {if {$mafiastarted != 0} {
            msgchan "#Hallowvale" "\0030,1Signups end in 15 seconds, use !enter to join in now!";
                   utimer 15 "if {$mafiastarted != 0} startmafia"
            }
        };                                      # Start the game in 90 seconds.
        return 1
    } elseif {$mafiastarted == 1} {
        if {[lsearch $players $nick] != -1} {notice $nick "You're already signed up!"; return 0}
        lappend players $nick
        notice $nick "You have successfully signed up, the game will begin soon."
        pushmode #Hallowvale +v $nick
        return 1
    } elseif {$mafiastarted == 2} {
        notice $nick "Please wait for the current game to finish."
        return 0
    }
}

proc pub:hang { nick user hand chan text } {
    global players stage votes
    if {$stage != "evening"} {return 0}
    #if {$nick in $hangers} {
    #    notice $nick "You already decided who you want to hang - you can't turn back!"
    #    return 0
    #}
    if {[strlwr $nick] ni [strlwr $players]} {
        notice $nick "You can only choose living players to hang."
        return 0
    }
    # Otherwise,
    #lappend hangers $nick
    #lappend votes [lindex $text 0]
    set votes($nick) [lindex $text 0]
    notice $nick "Your vote to hang [lindex $text 0] has been noted."
}

proc pub:end {nick user hand chan text} {
    if {[isstaff $hand]} {
        msgchan "#Hallowvale" "\0030,1Game ended by staff member: $nick"
        endmafia
    }
}

proc pub:boot {nick user hand chan text} {
    if {[isstaff $hand]} {
        msgchan "#Hallowvale" "\0030,1\002[lindex $text 0] died suddenly in a fire!"
        remplayer [lindex $text 0]
    }
}

proc pub:unboot {nick user hand chan text} {
    global players dead
    if {[isstaff $hand]} {
        msgchan "#Hallowvale" "\0030,1\002What a glorious event! Admin $nick gave [lindex $text 0] the gift of life!"
        lappend players [lindex $text 0]
        set dead [lsearch -all -inline -not -exact $dead [lindex $text 0]]
        pushmode #Hallowvale +v [lindex $text 0]
    }
}

proc pub:masshl {nick user hand chan text} {
    set peeps ""
    foreach u [chanlist #Hallowvale] {
        
    }
}

proc msg:broadcast {nick uhost hand text} {
    if {[isstaff $hand]} {
        msgchan "#Hallowvale" "\00312,0\002<$nick> $text"
    }
}

proc msg:kill {nick uhost hand text} {
    global mafia players hitlist dead stage
    if {$stage != "night"} {return 0}
    if {$nick in $dead} {return 0}
    if {[lsearch $mafia $nick] > -1} {
        if {[lsearch -exact -nocase $players [lindex $text 0]] > -1 && ![lsearch -exact -nocase $hitlist [lindex $text 0]] > -1 && ![lsearch -exact -nocase $dead [lindex $text 0]] > -1} {
            bcmafia "$nick wants [lindex $text 0]'s flesh to be burned alive. His opinion has been noted."
            lappend hitlist [lindex $text 0]
        } else {
            bcmafia "$nick wants to kill a person that isn't alive or is already on our agenda. Whatta fool, eh?"
        }
    }
}

proc msg:heal {nick uhost hand text} {
    global players dead saved doc revive stage
    if {$stage != "night"} {dccbroadcast "Doc Err: Stage is not night"; return 0; }
    if {$nick != $doc} {dccbroadcast "Doc Err: Nick != Doc"; return 0; }
    if {$nick in $dead} {dccbroadcast "Doc Err: Nick is in dead"; return 0;}
    if {[lsearch -exact -nocase $players [lindex $text 0]] > -1 && ![lsearch -exact -nocase $dead [lindex $text 0]] > -1} {
        set saved [lindex $text 0]
        set revive ""
        msgnick $doc "You will heal [lindex $text 0] tonight."
    } else {
        msgnick $doc "What? You're a doctor, not a miracle worker."
    }
}

proc msg:revive {nick uhost hand text} {
    global players dead saved doc revive stage
    if {$stage != "night"} {return 0}
    if {$nick != $doc} {return 0}
    if {$nick in $dead} {return 0}
    if {[lsearch -exact -nocase $dead [lindex $text 0]] > -1} {
        set saved ""
        set revive [lindex $text 0]
        msgnick $doc "You will attempt to revive [lindex $text 0] tonight."
    } else {
        msgnick $doc "Your powers of revival only extend to dead people originating from this town."
    }
}

proc msg:zamchat {nick uhost hand text} {
    global mafia
    if {[lsearch $mafia $nick] > -1} {
        bcmafia "\[ZAMORAK\] $nick: $text"
    }
}


proc startmafia {} {
    global mafia players cop doc mafiastarted alivemafia
    if {[llength $players] < 4} {msgchan "#Hallowvale" "\0030,1GAME OVER! Games require more then three people"; endmafia; devoiceall; return 0}
    set mafiastarted 2
    pushmode #Hallowvale +m
    set mafnum [expr {int(floor([llength $players]/3))}];                       # About one baddie per 2 innocents
    set temp 0;                                                                 # Temporary
    while {$mafnum > 0} {
        set baddie [lindex $players [rand [llength $players]]]
        if {$baddie ni $mafia} {
            lappend mafia $baddie
            lappend alivemafia $baddie
            incr mafnum -1
            #msgchan "#Hallowvale" $mafia
        }
    }
    while {$temp == 0} {
        set doc [lindex $players [rand [llength $players]]]
        if {$doc ni $mafia} {; # Can't be both doc and mafia!
            set temp 1
            #msgchan "#Hallowvale" $doc
        }
    }
    set temp 0
    while {$temp == 0 && [llength $players] > 6} {
        set cop [lindex $players [rand [llength $players]]]
        if {![lsearch $mafia $cop] > -1 && $cop != $doc} {; # Another check
            set temp 1
        }
    }
    bcmafia "You are a ZAMORAK INFILTRATOR. Use '!help infiltrator' for more information. Use '!z <message>' to chat in the infiltrator channel."
    msgnick $doc "You are a SARADOMIN HEALER. Use '!help healer' for more information."
    msgnick $cop "You are a SARADOMIN JAILKEEPER. Use '!help jailkeeper' for more information."
    night;                                                                      # Night time! :D
}

proc night {} {
    global doc cop night mafiastarted dead stage
    nightfix
    set stage "night"
    if {$mafiastarted == 0} {return 0}
    bcmafia "Please choose the unfortunate victim by using '!kill <nick>'"
    if {$doc ni $dead} {msgnick $doc "Please choose a person to save using '!heal <nick>' or try to revive someone using '!revive <nick>'"}
    if {$cop ni $dead} {msgnick $cop "If you want to arrest someone then use '!arrest <nick>', or if you want to shoot someone, then use '!shoot <nick>'"}
    msgchan "#Hallowvale" "\0030,1It's now night time, and everybody has fallen asleep... or have they? Night ends in 40 seconds."
    utimer 40 {msgchan "#Hallowvale" "\0030,1Ten seconds left until night is over.";
               utimer 10 dusk}
}

proc dusk {} {
    global stage target hitlist mafiastarted revive doc
    if {$mafiastarted == 0} {return 0}
    msgchan "#Hallowvale" "\0030,1It's now dusk... the sun should come up soon."
    mafiatarget
    if {$target != 0} {bcmafia "It is decided, we shall burn $target tonight."} else {bcmafia "It is decided, we will stay hiden and rest."}
    if {$revive != ""} {
        set chance [expr {round(rand()*10)}]
        if {$chance < 4} {reviveplayer $revive} else {msgnick $doc "No matter how hard you try, you can't revive $revive tonight. Perhaps better luck will be with you next night?"}
    }
    set hitlist {}
    set stage "dusk"
    utimer 15 morning;
}

proc morning {} {
    global target stage mafiastarted
    if {$mafiastarted == 0} {return 0}
    set stage "morning"
    whodied
    msgchan "#Hallowvale" "\0030,1It's now morningtime. Who is friendly, who is the enemy? Discuss amongst yourselves, you have 60 seconds."
    utimer 60 evening;
}

proc evening {} {
    global stage mafiastarted votes
    array unset votes
    array set votes {}
    if {$mafiastarted == 0} {return 0}
    set stage "evening"
    msgchan "#Hallowvale" "\0030,1It's now evening. Decide who you want dead by saying '!hang <nick>'. You have 30 seconds."
    utimer 35 lynch;
}

proc lynch {} {
    global mafiastarted votes players
    set a 0; set b 0; set c 0
    if {$mafiastarted == 0} {return 0}
    array unset total
    set total() {}
    foreach u $players {
        set total([strlwr $u]) 0
    }
    set target ""
    set largest 0
    set votelist ""
    foreach {name value} [array get votes] {
        dccbroadcast "$name voted for $value"
        incr total([strlwr $value]) 1
        lappend votelist $value
    }
    dccbroadcast "Votelist: $votelist"
    #foreach a $votes {; # Put in the number of votes per person
    #    incr total($a) 1
    #}
    foreach b $players {; # Get the max number of votes used
        if {$total([strlwr $b]) > $largest} {set largest $total([strlwr $b])}
    }
    dccbroadcast "Largest: $largest"
    foreach c $players {; # Finally, put the people with highest votes in a list
        if {$total([strlwr $c]) == $largest} {lappend target $c}
    }
    dccbroadcast "Targets: $target"
    set rcfl [llength $target]; set choice [expr {round(rand()*$rcfl)}]
    dccbroadcast "Rcfl: $rcfl | choice: $choice"
    set killed [lindex $target $choice]
    msgchan "#Hallowvale" "\0030,1The villagers, screaming for blood, surrounded $killed and tore him to pieces!"
    remplayer $killed
    utimer 5 night;
}

proc whodied {} {
    global hitlist target saved unconscious
    if {$target == "0"} {
        msgchan "#Hallowvale" "\00314,1The day has dawned with no death. Perhaps Zamorak's forces have gone soft?"
        return 0
    } elseif {[string equal -nocase $target $saved]} {
        msgchan "#Hallowvale" "\00314,1$target was burned by Zamorak's forces, but our good doctor healed his injuries. Unfortuantly, $target will spend the whole day unconscious in bed."
        lappend unconscious $target
        pushmode #Hallowvale -v $target
        return 0
    } else {
        msgchan "#Hallowvale" "\00314,1Somebody has died! After examining the burned remains, it has been concluded that he has been killed by Zamorak's forces."
        remplayer $target
        return 1
    }
}

proc reviveplayer {p} {
    global players dead alivemafia mafia
    msgchan "#Hallowvale" "\0030,1\002Amazing news! $p seemed to have somehow risen from the dead, ready to help the town!"
    lappend players $p
    if {$p in $mafia} {lappend alivemafia $p}
    set dead [lsearch -all -inline -not -exact $dead $p]
    pushmode #Hallowvale +v $p
}

proc bcmafia {msg} {
    global mafia dead
    foreach i $mafia {
        if {$i ni $dead} {msgnick $i $msg}
    }
}

proc devoiceall {} {
    global players
    foreach i $players {
        pushmode #Hallowvale -v $i
    }
}

proc checkend {} {
    global mafia players mafiastarted dead alivemafia
    set divided [expr {[llength $players] - [llength $alivemafia]}]
    if {$mafiastarted == 2} {
        dccbroadcast "Mafia: $mafia | Alive Mafia: $alivemafia | Players: $players | Divided: $divided | Llength mafia: [llength $mafia]"
        if {[llength $alivemafia] > $divided} {
            msgchan "#Hallowvale" "\0030,1The infiltrators came into the land, ransacking all the tents and claiming the land"
            msgchan "#Hallowvale" "\00310,1\002GAME OVER!\002 The ZAMORAK side won!"
            endmafia
            return 1
        }
        if {[llength $alivemafia] == 0} {
            msgchan "#Hallowvale" "\0030,1The peaceful Saradomins managed to exterminate all of the vile Zamorakions!"
            msgchan "#Hallowvale" "\00310,1\002GAME OVER!\002 The SARADOMIN side won!"
            endmafia
            return 1
        }
        return 0
    }
}

proc remplayer {nick} {
    global players dead mafia alivemafia
    set players [lsearch -all -inline -not -exact $players $nick]
    if {[lsearch $mafia $nick] > -1} {
        msgchan "#Hallowvale" "\00310,1$nick is now dead. He was on \002ZAMORAK'S\002 side!"
    } else {
        msgchan "#Hallowvale" "\00310,1$nick is now dead. He was on \002SARADOMIN'S\002 side!"
    }
    if {$nick in $alivemafia} {
        set alivemafia [lsearch -all -inline -not -exact $alivemafia $nick]
    }
    pushmode #Hallowvale -v $nick
    checkend
    return [lappend dead $nick]
}

proc isstaff {hand} {
    global staff
    foreach i $staff {
        if {$hand == $i} {
            return 1
        }
    }
    return 0
}

proc endmafia {} {
    global mafiastarted staff players dead mafia hitlist unconscious stage doc cop saved revive alivemafia votes
    pushmode #Hallowvale -m
    devoiceall
    set mafiastarted 0
    set players {}
    set dead {}
    set mafia {}
    set hitlist {}
    set unconscious {}
    set stage "night"
    set doc ""
    set cop ""
    set saved ""
    set revive ""
    set alivemafia {}
    array unset votes
    array set votes {}
}

proc pub:bug { nick user hand chan text } {
    if {![userexists $hand]} {return 0}
    msgnick "[hand2nick BaconServ]" "BUG REPORT from $nick @ $hand: $text"
    dccbroadcast "BUG REPORT from $nick @ $hand @ $chan: $text"
    notice $nick "Thank you - your bug report has been recieved."
}

proc msg:bug {nick uhost hand text} {
    if {![userexists $hand]} {return 0}
    msgnick "[hand2nick BaconServ]" "BUG REPORT from $nick @ $hand: $text"
    dccbroadcast "BUG REPORT from $nick @ $hand from PM: $text"
    msgnick $nick "Thank you - your bug report has been recieved."
}

proc mafiatarget {} {global hitlist target; if {[lindex $hitlist 0] != ""} {return [set target [lindex $hitlist [rand [llength $hitlist]]]]} else {return [set target 0]}}