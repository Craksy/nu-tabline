# a couple of helpers
def overwrite-prompt [] { print -n (ansi -e 1F) (ansi -e 0J) } # ExecuteHostCommand doesn't print a prompt on a new line
def conf [key] { $env.tabline | get $key }
def color [fg bg] { ansi -e { fg: (conf $fg), bg: (conf $bg)} }

def print-seperator [left right] {
    let opts = (
        if $right.active {{fg: inactive_background, bg: active_background, sep: separator_hard }} 
        else if $left.active {{ fg: active_background, bg: inactive_background, sep: separator_hard }} 
        else {{ fg: inactive_foreground, bg: inactive_background, sep: separator_soft }}
    )
    print -n (color $opts.fg $opts.bg) (conf $opts.sep) (ansi reset)
}

def print-tab [tab] {
    print -n (
        if $tab.active { color active_foreground active_background } 
        else { color inactive_foreground inactive_background }
    ) " " ($tab.path | path basename) " " (ansi reset)
}

def print-tabline [] {
    let nshells = (shells | length)
    shells | window 2 | each -n { |win|
        print-tab $win.item.0
        print-seperator $win.item.0 $win.item.1
        if $win.index == ($nshells - 2) { 
            print-tab $win.item.1 
            if (conf end_separator) {
                let clr = {fg: (if $win.item.1.active { (conf active_background)} else {(conf inactive_background)}) }
                print -n (ansi -e $clr) (conf separator_hard) (ansi reset)
            }
        }
    }
}

def hook [] {
    if (shells | length) > 1 {
        print -n (ansi -e s) (ansi -e H) (ansi -e 2K)
        print-tabline
        print -n (ansi -e u)
    }
}

export def-env switch [tab] { g $tab; overwrite-prompt }
export def-env close [] { exit; overwrite-prompt }
export def clear [] { print (ansi -e H) (ansi -e 2J) } # overwrite default clear command. deleted my tabline and gave me the sads.

export def-env init [] {
    let default_config = {
        separator_hard: ""
        separator_soft: ""
        inactive_foreground: '#0d5f99'
        inactive_background: '#111111'
        active_foreground: '#ffffff'
        active_background: '#0d5f99'
        end_separator: false
    }
    let pp_hooks = ($env.config.hooks.pre_prompt | append { hook })
    let hooks = ($env.config.hooks | upsert pre_prompt $pp_hooks)
    let-env config = ($env.config | upsert hooks $hooks)
    let-env tabline = if 'tabline' in $env { $default_config| merge { $env.tabline } } else { $default_config }
}