#################
## SKILLS GAME ##
#################

bind raw - INVITE invite
bind pub - !part pub:part
bind pub - .part pub:part
bind pub - !ignore pub:ignore
bind pub - .ignore pub:ignore
bind evnt - prerestart fixfreeze
bind pub - !rehash pub:rehash
bind pub - .rehash pub:rehash
bind pub - !restart pub:restart
bind pub - .restart pub:restart
bind pub - !die pub:die
bind pub - .die pub:die
bind pub - !id pub:id
bind pub - .id pub:id
bind pub - !fixtimer pub:tf
bind pub - .fixtimer pub:tf
bind join - * join:announce

proc join:announce {nick uhost hand chan} {
    global staff; # See hallowvale.tcl
    global mod;
    foreach i $staff {
        if {$hand == $i} {
            msgchan $chan "Bot admin \002$nick\002 has joined!"
        }
    }
    foreach i $mod {
        if {$hand == $i} {
            msgchan $chan "Bot moderator \002$nick\002 has joined!"
        }
    }
    return 0
}

proc pub:ignore {nick user hand chan text} {
    if {[isstaff $hand] || [ismod $hand]} {
        newignore [getchanhost [lindex $text 0]] $nick $text 0
        dccbroadcast "[lindex $text 0] at [getchanhost [lindex $text 0]] got put on ignorelist by Nick: $nick Handle: $hand"
    }
}

proc invite {from key arg} {
    set chan [lindex [split $arg :] 1]
    if {$chan == "#2dum"  || $chan == "#Force"} {return 0}
    channel add $chan
    msgchan [lindex [split $arg :] 1] "Hey there, I'm ThorsHammer, an IRC game bot! I was invited here by $from. My bot owner is [hand2nick BaconServ]. If you're new (or even if you're an old player,) then use !help to get started. Join #ThorsHammer for help, prizes, and more."
    return 0
}

proc pub:part { nick user hand chan text } {
    if {$chan == "#tezz" || $chan == "#ThorsHammer"} {notice $nick "Sorry - this channel is in the protected channels list."; return 0}
    if {[isop $nick $chan] || [isstaff $hand] || [ismod $hand]} {
        if {[lindex $text 0] == "ThorsHammer"} {
            channel remove $chan
            dccbroadcast "Chanop $nick has parted me from $chan."
        }
    } else {
        notice $nick "Sorry - you don't have a high enough rank to part me!"
    }
}

proc fixfreeze {type} {setall tired no}

proc pub:rehash {nick user hand chan text} {
    if {[isstaff $hand]} {msgchan $chan "Rehashing..."; rehash; msgchan $chan "...done."}
}

proc pub:restart {nick user hand chan text} {
    if {[isstaff $hand]} {msgchan $chan "Restarting..."; restart}
}

proc pub:die {nick user hand chan text} {
    if {[isstaff $hand]} {msgchan $chan "Dieing :("; die}
}

proc pub:id {nick user hand chan text} {
    if {[isstaff $hand]} {msgnick nickserv "IDENTIFY mypassword"}
}

proc pub:tf {nick user hand chan text} {
    if {[isstaff $nick]} {setstat [lindex $text 0] tired no; msgchan $chan "[lindex $text 0]'s timer has been fixed."}
}

###########################################################
# Commands:                                               #
#                                                         #
# !go <skill>                                             #
# Now seperated to prevent major lag. Go is one proc.     #
#                                                         #
# !lamp <skill>                                           #
# Now given randomly instead of hourly (Random Event.)    #
#                                                         #
# !store <item>                                           #
# Use that cash you got!                                  #
#                                                         #
###########################################################

## Variables ##


## Internal Variables ##
set id 0; # Used for lists

# Fish
# (Thank goodness for RuneHq.)
set fish {shrimp sardines herring anchovies trout pike salmon tuna lobsters bass swordfish monkfish sharks }
set fishlevels {1 5 10 15 20 25 30 35 40 46 50 62 76}
set fishexp {10 20 30 40 50 60 70 80 90 100 100 120 110}


## Convinence functions ##
proc notice {nick msg} { putserv "NOTICE $nick :$msg" }
proc msgchan {chan msg} { putserv "PRIVMSG $chan :$msg" }
proc msgnick {nick msg} { putserv "PRIVMSG $nick :$msg" }
proc getstat {hand stat} { return [getuser $hand XTRA $stat] }
proc setstat {hand stat setting} { return [setuser $hand XTRA $stat $setting] }


## Bindings ##
bind pub - !go "pub:go 0"
bind pub - .go "pub:go 0"
bind pub - @go "pub:go 1"
bind pub - !lamp "pub:lamp 0"
bind pub - .lamp "pub:lamp 0"
bind pub - @lamp "pub:lamp 1"
bind pub - !store "pub:store 0"
bind pub - .store "pub:store 0"
bind pub - @store "pub:store 1"
bind pub - !help "help 0"
bind pub - .help "help 0"
bind pub - @help "help 1"
bind pub - !commands "help 0"
bind pub - .commands "help 0"
bind pub - @commands "help 1"
bind pub - !rank "pub:rank 0"
bind pub - .rank "pub:rank 0"
bind pub - @rank "pub:rank 1"
bind pub - !bank "pub:bank 0"
bind pub - .bank "pub:bank 0"
bind pub - @bank "pub:bank 1"
bind pub - !stats "pub:stats 0"
bind pub - .stats "pub:stats 0"
bind pub - @stats "pub:stats 1"
bind msg - .global msg:globalmessage
bind msg - !global msg:globalmessage

#bind pubm - "% ?go*" pub:go
#bind pubm - "% ?lamp*" pub:lamp
#bind pubm - "% ?store*" pub:store
#bind pubm - "% ?help*" help
#bind pubm - "% ?rank*" pub:rank
#bind pubm - "% ?bank*" pub:bank
#bind msgm - "% ?global*" msg:globalmessage


## Functions ##
proc pub:go {outloud nick user hand chan text} {
    ########################################  ABOUT  ######################################
    ## So, basically skills are just manipulations of a lot of varibles and user stats.  ##
    ## Once more skills start to fill in here, I'll move them out to individual procs.   ##
    #######################################################################################
    if {[checkreg $nick $chan] == 0} { return 0 };             # If he's not registered, stop.
    set command [lindex $text 0];                              # Set the skill to train
    #if {[lindex $text 0] == ".go" || [lindex $text 0] == "!go"} {set outloud 0} else {set outloud 1}
    if {$command == "fish"} {
        go_fish $outloud $nick $user $hand $chan $text
    }
    if {$command == "cook"} {
        go_cook $outloud $nick $user $hand $chan $text
    }
    if {$command == "sell"} {
        go_sell $outloud $nick $user $hand $chan $text
    }
}

proc msg:globalmessage {nick uhost hand text} {
    if {[isstaff $hand]} {
        foreach i [channels] {
            msgchan $i "\0030,1\[GLOBAL\] <$nick> $text"
        }
    }
}

proc help {outloud nick user hand chan text} {
    global botnick
    dccbroadcast "$nick in $chan uses !help"
    if {$outloud == 0} {
        notice $nick "Welcome to the skills game! To get started, '/msg $botnick !reg', this will register you into the sytem. Afterwards, you may use '.go <action>' in any channel with $botnick in it to play. Go ahead, try using '.go fish' in a channel."
        notice $nick "Current actions availible are: fish, cook, sell. Other commands include: !rank, !bank, !stats, !help"
    } else {
        msgchan $chan "Welcome to the skills game! To get started, '/msg $botnick !reg', this will register you into the sytem. Afterwards, you may use '.go <action>' in any channel with $botnick in it to play. Go ahead, try using '.go fish' in a channel."
        msgchan $chan "Current actions availible are: fish, cook, sell. Other commands include: !rank, !bank, !stats, !help"
    }
}

proc levelup { exp level hand nick skill } {
    set newlevel [getlevel $exp];                              # Get the level based on exp
    if {$newlevel > $level} {
        if {$skill == "fishing"} {
            setstat $hand lvlfishing $newlevel;                    # Set the fishing level to the new one
            notice $nick "Congratulations, you are now fishing level $newlevel!"
            dccbroadcast "[hand2nick $hand] is now fishing level $newlevel (previous $level.)"
        } elseif {$skill == "cooking"} {
            setstat $hand lvlcooking $newlevel;                    # Set the cooking level to the new one
            notice $nick "Congratulations, you are now cooking level $newlevel!"
            dccbroadcast "[hand2nick $hand] is now cooking level $newlevel (previous $level.)"
        }
    }
}

# Thanks to Thommey! :)
proc getlevel { exp } { set a 0; set b 1; while {$a <= $exp} { set a [expr {$a + int($b + 300 * pow(2,$b/7.0)) / 4.0}]; incr b }; expr {$b-1} }

proc getfish { level } {
    global fish fishlevels id;                                 # Grab the fish/levels list
    set max [llength $fish];                                   # Used for the while loop
    incr max -1
    while {$max > -1} {
        # dccbroadcast "Current position in array: $max"
        set testlevel [lindex $fishlevels $max];               # Get the current level to test
        #msgchan "#ThorsHammer" $testlevel
        if {$level >= $testlevel} {
            set id $max;                                       # Used for exp rates
            # dccbroadcast "Fish returned: [lindex $fish $max]"
            return [lindex $fish $max];                        # Returns the highest fish you can catch
            break
            set max 0;                                         # Probably not needed because of return...
        } else {incr max -1};                                  # Keep the loop going
    }
}

proc fishplace { fish2check } {
    global fish fishlevels id;                                 # Grab the fish/levels list
    set max [llength $fish];                                   # Used for the while loop
    incr max -1
    while {$max > -1} {
        # dccbroadcast "Current position in array: $max"
        set testfish [lindex $fish $max];                     # Get the current level to test
        #msgchan "#ThorsHammer" $testlevel
        if {$fish2check == $testfish} {
            set id $max;                                     
            # dccbroadcast "Fish returned: [lindex $fish $max]"
            return $max;                                       # Returns the highest fish you can catch
            break
            set max 0;                                         # Probably not needed because of return...
        } else {incr max -1};                                  # Keep the loop going
    }
    return 0
}

proc sotired { nick hand } {
    setstat $hand tired "yes"
    set howlong [expr {round(rand()*5)+2}]
    notice $nick "You look tired, good sir. Have a rest for at least $howlong minutes."
    timer $howlong "notice $nick {You can now use a skill again, good sir!}"
    timer $howlong "setstat $hand tired no"
}

proc checkreg { nick chan } {
    # If the person hasn't yet said hello to the bot, tell them to. Ugly code. :(
    global botnick
    if {[nick2hand $nick $chan] == "*"} {
        notice $nick "You are not registered yet. Please '/msg $botnick !reg' to login, and use !help in-channel to start."
        return 0
    } else { return 1 }
}

proc userexists {hand} {
    # Return 1 if the user has registered.
    if {[getstat $hand expfishing] == ""} {return 0} else {return 1}
}

proc newprofile { hand } {
    global fish
    setstat $hand lvlfishing 1
    setstat $hand expfishing 0
    setstat $hand lvlcooking 1
    setstat $hand expcooking 0
    setstat $hand money 0
    setstat $hand tired "no"
    setstat $hand diamonds 0
    set x 0; while {$x <= [llength $fish]} {
        # Create a section for each fish availible
        setstat $hand [lindex $fish $x] 0
        incr x +1
    }
}

proc isstaff {hand} {
    global staff; # See hallowvale.tcl
    foreach i $staff {
        if {$hand == $i} {
            return 1
        }
    }
    return 0
}

proc ismod {hand} {
    global mod; # See hallowvale.tcl
    foreach i $mod {
        if {$hand == $i} {
            return 1
        }
    }
    return 0
}

proc wipeall {} {
    set users [userlist]
    dccbroadcast "Wiping the profiles down... :("
    foreach u $users {
        newprofile $u
    }
    dccbroadcast "Done! :)"
}

proc setall {a b} {
    set users [userlist]
    foreach u $users {
        setstat $u $a $b
    }
    dccbroadcast "Done! :)"
}

proc go_fish {outloud nick user hand chan text} {
    global id fishexp ::lastbind;
    if {[getuser $hand XTRA tired] == "yes"} { return 0 }; # If tired; stop.
    set level [getstat $hand lvlfishing];                  # Get fishing level
    set exp [getstat $hand expfishing];                    # Get fishing exp
    if {$exp == ""} {
        newprofile $hand;                                  # Create user's profile
        set level 1; set exp 0;                            # Fix varibles to prevent error
    }
    set fish2get  [getfish $level];                        # Sets the fish to catch
    set ammount   [rand 30];                               # Set ammount of fish to catch
    set exprate   [lindex $fishexp $id];                   # Set the experience rate
    set expearned [expr {$ammount * $exprate}];            # Set ammount of exp earned this catch
    set fish      [getstat $hand $fish2get];               # Set ammount of fish
    incr exp      $expearned;                              # Set new exp ammount
    incr fish     $ammount;                                # Set new fish ammount
    setstat $hand expfishing $exp;                         # Save changes to exp
    setstat $hand $fish2get $fish;                         # Save changes to fish
    if {$outloud == 0} {
        notice $nick "You went out and caught $ammount $fish2get. You now have $fish $fish2get and have gained $expearned exp."
    } elseif {$outloud == 1} {
        msgchan $chan "$nick went out and caught $ammount $fish2get. He now has $fish $fish2get and has gained $expearned exp."
    }
    dccbroadcast "$nick caught $ammount $fish2get (totalling $fish) in $chan."
    #if {$chan == "#ThorsHammer"} {specialevent 1 $nick};   # Diamonds! :)
    levelup $exp $level $hand $nick fishing;               # Check if user got a new level
    sotired $nick $hand;                                   # Make user tired
}

proc go_cook {outloud nick user hand chan text} {
    global id fishexp ::lastbind;
    set level [getstat $hand lvlcooking];                  # Get cooking level
    set exp [getstat $hand expcooking];                    # Get cooking exp
    if {$exp == ""} {
        newprofile $hand;                                  # Create user's profile
        set level 1; set exp 0;                            # Fix varibles to prevent error
    }
    set ammount [getstat $hand [lindex $text 1]];          # Get ammount of fish to fry!
    if {$ammount < 1} {
        notice $nick "You don't have any of that!"
        return 0
    }
    set fish      [lindex $text 1];                        # What fish are we catching?
    set exprate   [expr {[lindex $fishexp $id]*1.2}];      # Faster exp then fishing
    set expearned [expr {round($ammount * $exprate)}];     # Gotta round
    incr exp      $expearned;                              # Save changes to exp
    setstat $hand expcooking $exp
    setstat $hand $fish 0
    if {$outloud == 0} {
        notice $nick "You cooked all $ammount of your $fish, netting you $expearned xp."
    } elseif {$outloud == 1} {
        msgchan $chan "$nick cooked all $ammount of his $fish, netting him $expearned xp."
    }
    dccbroadcast "$nick cooked $ammount $fish, earning $expearned xp in $chan."
    levelup $exp $level $hand $nick cooking
}

proc go_sell {outloud nick user hand chan text} {
    global fishlevels ::lastbind
    set money [getstat $hand money]
    set profiletest [getstat $hand expcooking]
    if {$profiletest == ""} {
        newprofile $hand;                                  # Create user's profile
        set level 1; set exp 0;                            # Fix varibles to prevent error
    }
    set ammount [getstat $hand [lindex $text 1]];          # Get ammount of fish to fry!
    if {$ammount < 1} {
        notice $nick "You don't have any of that!"
        return 0
    }
    set fish      [lindex $text 1]
    set moneyrate [lindex $fishlevels [fishplace [lindex $text 1]]]
    set earned    [expr {$ammount*$moneyrate}]
    incr money    $earned
    if {$outloud == 0} {
        notice $nick "You sold all $ammount of your raw $fish, earning you \$$earned!"
    } elseif {$outloud == 1} {
        msgchan $chan "$nick sold all $ammount of his raw $fish, earning him \$$earned!"
    }
    setstat $hand $fish 0
    setstat $hand "money" $money
}

proc scorelist {} {
    # Returns money values in order from greatest to smallest
    set users [userlist]
    set overallmoney {}
    foreach u $users {
        lappend overallmoney [getstat $u money] 
    }
    return [lsort -decreasing -integer $overallmoney];
}

proc whohas {score} {
    set users [userlist]
    foreach u $users {
        if {[getstat $u money] == $score} {return $u}
    }
    return ""; # If no one has that score
}

proc rankmoney {nick} {
    set scores [scorelist]
    set compare [getstat [nick2hand $nick] money]
    set rank 1
    foreach u $scores {
        if {$u == $compare} {return $rank} else {set rank [expr {$rank + 1}]}
    }
    return "ERROR: INVALID"
}

proc updatescores {repeat} {
    global highscores
    set highscores [scorelist]
    if {$repeat} {timer 30 "updatescores"}
}

proc pub:rank {outloud nick user hand chan text} {
    global highscores
    #if {[lindex $text 0] == ".rank" || [lindex $text 0] == "!rank"} {set outloud 0} else {set outloud 1}
    set cash [getstat $hand money]
    set name [lindex $text 0]
    if {$name == ""} then {set name $nick}
    dccbroadcast "Here 1. Name: $name"
    if {[string is integer $name]} {
        dccbroadcast "Here 2."
        updatescores 0
        set player [lindex $highscores [expr {$name - 1}]]
        if {$player == ""} {
            notice $nick "Nobody is rank $name at the moment.."
        } else {
            notice $nick "Rank $name goes to [whohas $player], with \$$player."
        }
    } else {
        dccbroadcast "Here 3"
        if {![string is integer [getstat [nick2hand $name] lvlfishing]]} {notice $nick "$name hasn't registered yet.."; return 0}
        set rnk [rankmoney $name]
        dccbroadcast "Here 4. Rank: $rnk"
        if {$outloud == 0} {notice $nick "$name ([nick2hand $name]) is rank $rnk with \$[getstat [nick2hand $name] money]."} else {
            msgchan $chan "$name ([nick2hand $player]) is rank $rnk with \$[getstat [nick2hand $name] money]."
        }
    }
}

proc pub:bank {outloud nick user hand chan text} {
    set get {money shrimp sardines herring anchovies trout pike salmon tuna lobsters bass swordfish monkfish sharks diamonds}
    set alt {dollars shrimp sardines herring anchovies trout pike salmon tuna lobsters bass swordfish monkfish sharks diamonds}
    set l ""
    set listplace 0
    #if {[lindex $text 0] == ".bank" || [lindex $text 0] == "!bank"} {set outloud 0} else {set outloud 1}
    set player [lindex $text 0]
    if {$player == ""} then {set player $hand}
    if {$player != $hand && ![isstaff $hand] && ![ismod $hand]} {notice $nick "No peeking at other peoples banks! Ask them to use @bank."; return 0}
    if {[userexists [nick2hand $player]] == 0} then {notice $nick "User $player doesn't exist.. Perhaps you should try a different nick?"; return 0}
    foreach u $get {
        set ammount [getstat [nick2hand $player] $u]
        if {$ammount > 0} {
            if {$l == ""} {
                append l "$ammount [lindex $alt $listplace]"
            } else {
                append l ", $ammount [lindex $alt $listplace]"
            }
        }
        incr listplace 1
    }
    if {$l == ""} {
        if {$outloud == 0} {
           notice $nick "$player currently doesn't have anything of value." 
        } else {
            msgchan $chan "$player currently doesn't have anything of value."
        }
    } else {
        if {$outloud == 0} {
           notice $nick "$player currently has: $l" 
        } else {
            msgchan $chan "$player currently has: $l"
        }
    }
}

proc pub:stats {outloud nick user hand chan text} {
    if {[lindex $text 0] == ""} {
        if {$outloud == 0} {
            notice $nick "$nick ($hand) stats: Fishing level [getstat $hand lvlfishing] ([getstat $hand expfishing] XP), Cooking level [getstat $hand lvlcooking] ([getstat $hand expcooking] XP), \$[getstat $hand money]."
        } else {
            msgchan $chan "$nick ($hand) stats: Fishing level [getstat $hand lvlfishing] ([getstat $hand expfishing] XP), Cooking level [getstat $hand lvlcooking] ([getstat $hand expcooking] XP), \$[getstat $hand money]."
        }
    } else {
        set player [lindex $text 0]
        if {[userexists [nick2hand $player]] == 0} {notice $nick "$player hasn't played or registered yet.."; return 0}
        if {$outloud == 0} {
            notice $nick "$player ([nick2hand $player]) stats: Fishing level [getstat [nick2hand $player] lvlfishing] ([getstat [nick2hand $player] expfishing] XP), Cooking level [getstat [nick2hand $player] lvlcooking] ([getstat [nick2hand $player] expcooking] XP), \$[getstat [nick2hand $player] money]."
        } else {
            msgchan $chan "$player ([nick2hand $player]) stats: Fishing level [getstat [nick2hand $player] lvlfishing] ([getstat [nick2hand $player] expfishing] XP), Cooking level [getstat [nick2hand $player] lvlcooking] ([getstat [nick2hand $player] expcooking] XP), \$[getstat [nick2hand $player] money]."
        }
    }
}

proc specialevent {type nick} {
    # List of special events:
    #########################
    # 1) Chance of finding a diamond
    
    if {$type == 1} {
        set chance [expr {round(rand()*50)}]
        if {$chance == 1} {
            set diamonds [getstat [nick2hand $nick] diamonds]
            incr diamonds 1
            setstat [nick2hand $nick] "diamonds" $diamonds
            dccbroadcast "(Special) $nick found a diamond!"
            notice $nick "While you were working, you found something in the sand... it's a diamond! You decide to store it in your bank to show it off."
        }
    }
}

set highscores [scorelist]
updatescores 0
if {[timers] == ""} {updatescores 1}