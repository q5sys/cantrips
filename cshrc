set ashrcversion = "10.2.5.2"
#"$Id: cshrc,v 1.64 2017/07/21 19:20:48 xpi Exp $"
#1999 - 2017 Ash
#BSD license
#General disclaimer about damages real or causal resulting in teh use of this
#"software"
#___________________________________core paths_________________________________
set notify
set spinspites = ( 'i' '/' '-' '\' '|' '/' '-' '\' ) 
set spincursor = 0
if ( $?prompt ) then
  #diagnostic P to indicate pathmangling
  printf "P"
endif #prompt
#allow local paths to override  global ones
if ( -f /etc/skel/.chsrc ) then
	source /etc/skel/.cshrc	
endif #etcskel

#path_roots are possible stems for path heirarchy. 
#  taken from various unix traditions
# perform discovery for places to put executables, libraries and man pages
# **can't use * in path_roots expansion or set bombs if there are no children 
#   ex: /usr/local/* ; found on freebsd, new install
# this tasting process may be expensive on certain platforms where negative file
#   tests are slow

set path_roots = ( $HOME / /opt /usr/ucb /usr /usr/local )
set path_roots = ( $path_roots /opt/local /usr/share /sw /opt/X11 /usr/X11 )   
#path_components are places to look for binaries inside path_roots
set path_components = ( bin sbin libexec games tools ) 

#start with minimal paths so we have a path should things short out during launch
# you will see a P
setenv MANPATH /usr/share/man:/usr/local/man
setenv PATH /bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:
setenv PATH ${PATH}:${HOME}/cantrips/libexec:${HOME}/cantrips/dt

#now find more path_roots; 
#possibly expensive workaround for /usr/local/* in path_roots
foreach pathroot_candidate ( `ls /usr/local `) 
	if ( -d /usr/local/$pathroot_candidate )  then
		#echo $pathroot_candidate is a dir
		set path_roots = ( $path_roots /usr/local/$pathroot_candidate )
	endif #is a directory
end #foreach pathroot_candidates

foreach pathroot ( $path_roots )
    if ( -d $pathroot/man ) then
        if ( $MANPATH =~ "*$pathroot/man*" ) then 
            #echo "found redundant man $pathroot"
        else
            #echo found man $pathroot
            setenv MANPATH "$pathroot/man":$MANPATH
        endif
    endif
     if ( -d $pathroot/share/man ) then
        if ( $MANPATH =~ "*$pathroot/share/man*" ) then 
            #echo "found redundant man $pathroot/share"
        else
            #echo found man $pathroot/share
            setenv MANPATH "$pathroot/share/man":$MANPATH
        endif
        
    endif
    #look for locations of binaries within a pathroot 
    foreach pathcomponent ( $path_components ) 
        if ( -d $pathroot/$pathcomponent ) then
            if ( -e $pathroot/$pathcomponent/no_auto_path ) then
                # permit skipping paths that would  conflict with 
		# important things eg msp430/bin/cpp which clobbers ports builds 
                # echo skipping $pathcomponent in path  due to no_auto_path file found
		set pathskipped=($?pathskipped $pathroot/$pathcomponent)
	    else
                if ( $PATH =~ "*$pathroot/$pathcomponent*" ) then 
                    #echo "found $pathroot/$pathcomponent redundant"
                else
                    #echo "$pathroot/$pathcomponent found"
                    setenv PATH "$pathroot/$pathcomponent":$PATH
                endif
            endif
        endif #$pathcomponent exists
    end #foreach pathcomponent
end # foreach pathroot

#____________________________________________________global nonineractive macros
	setenv REDSIG	2
	setenv REDCOL	1

	alias redpids  "sed -E 's/^ +//' | sed -E 's/ +/	/g' | cut -f${REDCOL} " 
	alias redtide  "redpids | xargs -n1 kill"
	setenv gTODAY `date +"%Y%m%d"`
	alias gTODAY  'setenv gTODAY  `date +"%Y%m%d"`; echo ${gTODAY}'
	alias gNOW  'setenv gNOW  `date +"%s"`; echo ${gNOW}'
	setenv gUNAME `uname`
	alias p[        pushd
	alias p]        popd
	alias p[]       "dirs -v"
	alias p		"ps -axwww | grep -v grep | grep "
    alias space2tab "sed -E 's/ +/	/g'" #that's a hard tab in that hole
    alias chomp "sed -E 's/^ +//'"  #strip leading space

    set hunthome=${HOME}
    alias hunting_ground 'set hunthome=`pwd`'
    #find a zymbol
    alias hunt 'echo $hunthome; grep -nR \!\!:1 $hunthome'    

    #transform  file:linenum: into vi $1 +$2
    alias viize "sed -E 's/^(.*):([0-9]*):/vi \1  +\2/'"    

    #go edit file with symbol $1 in filename matching $2
    alias jump '`hunt \!\!:1 \!\!:2 | space2tab | cut -f1 | uniq |  viize`'

	alias srx 's \!\!:1 "cd \!\!:2 ; tar -cf - \!\!:3-$ " | tar -xpf -' 
	alias stx 'tar -cf - \!\!:3-$  | s \!\!:1 "cd \!\!:2 ; tar -xpf - "' 
	alias r 's -x -l root'
	alias R 's -x  -Y -l root'
	alias s 'ssh '
	alias S 's -Y '
	alias usage  "du -sxk * | sort -rn > usage; less usage"
	alias xrange 'python -c "for i in xrange (\!\!:1,\!\!:2):  print i" '
	alias byte 'python -c "import sys; sys.stdout.write (chr(\!\!:1))"'
#/______________________________________________________global interactive stuff
if ( $?prompt ) then
	printf "\b-"
	alias l 'source ~/.cshrc'	
	alias vl 'vi ~/.cshrc'
	alias vll 'vi ~/.cshrc.local'
    
	set listjobs="long"
	set autologout="0  1"
	set promptchars="#&"
	set rprompt=":%B`whoami | cut -c 1-4`%b:%c2:%P:%\!%S%m%s"
	set complete="enhance"
	set matchbeep="never"
	if ( ! -f ${HOME}/.ssh/known_hosts ) then
		touch ${HOME}/.ssh/known_hosts
	endif 	
	if ( ! -f ${HOME}/.ssh/config ) then
		touch ${HOME}/.ssh/config
	endif 	

	set hosts=(`cat /etc/hosts | sed -e 's/#.*//' | uniq` \
		`cat ${HOME}/.ssh/known_hosts | sed -e 's/#.*//' | sed -E 's/\[(.*)\]/\1/g' | cut -f1 -d ' ' | tr "," ' '` \
	 	`grep -s "Host "  ${HOME}/.ssh/config | cut -b5-50 | uniq`   )
	set interfaces = (`ifconfig | cut -d: -f1 | cut -f1 | sort | uniq`)
    # populate multiple idents for ssh -i 
 
    
	complete su  'p/1/-u/'
	complete fg           'c/%/j/' #per wb
	complete sudo  'p/1/( tcsh bash port fink )/'
	complete r 'p/1/$hosts/'
	complete s 'p/1/$hosts/'
	complete S 'p/1/$hosts/'
	complete R 'p/1/$hosts/'
	complete p 'p/1/`p . | space2tab | cut -f1,4 `/'
	complete S 'p/1/$hosts/'
	complete git 'p/1/( pull commit push status branch diff checkout )/'  'p/*/f/' 
	complete cvs 'p/1/(  status commit checkout )/' 
	complete ping  'p/*/$hosts/' 
	complete dig 'p/*/$hosts/' 
	complete ssh  'c/*@/$hosts/' 'p/1/u/@'
	complete scp          "c,*:/,F:/," \
			'c/-o/\"(Port )\"/' \
                        "c,*:,F:$HOME," \
                        'c/*@/$hosts/:/'
	complete make 'p/1/`cat [Mm]akefile* | grep : | cut -d: -f1 `/'
	complete man 'p/1/c/'
	complete which 'p/1/c/'
	complete where 'p/1/c/'
	complete netstat      'n/-I/`ifconfig -l`/' 
	#pkg wb
	set pkgcmds=(help add annotate audit autoremove backup check clean convert create delete fetch info install lock plugins \
                        query register repo rquery search set shell shlib stats unlock update updating upgrade version which)
	alias pkgsch	'set pkgtgt=`pkg search \!\!:1 | cut  -w -f1`; echo $pkgtgt' 
	

	alias __pkgs  'pkg info -q'
	# aliases that show lists of possible completions including both package names and options
	alias __pkg-check-opts        '__pkgs | xargs echo -B -d -s -r -y -v -n -a -i g x'
	alias __pkg-del-opts          '__pkgs | xargs echo -a -D -f -g -i -n -q -R -x -y'
	alias __pkg-info-opts         '__pkgs | xargs echo -a -A -f -R -e -D -g -i -x -d -r -k -l -b -B -s -q -O -E -o -p -F'
	alias __pkg-which-opts        '__pkgs | xargs echo -q -o -g'

	complete pkg          'p/1/$pkgcmds/' \
			'n/check/`__pkg-check-opts`/' \
			'N/check/`__pkgs`/' \
			'n/delete/`__pkg-del-opts`/' \
			'N/delete/`__pkgs`/' \
			'n/help/$pkgcmds/' \
			'n/info/`__pkg-info-opts`/' \
			'N/info/`__pkgs`/' \
			'n/which/`__pkg-which-opts`/' \
			'N/which/`__pkgs`/' \
			'n/install/$pkgtgt/'
			
			


	complete find 'n/-name/f/' 'n/-newer/f/' 'n/-{,n}cpio/f/' \
       'n/-exec/c/' 'n/-ok/c/' 'n/-user/u/' 'n/-group/g/' \
       'n/-fstype/(nfs 4.2)/' 'n/-type/(b c d f l p s)/' \
       'c/-/(name newer cpio ncpio exec ok user group fstype type atime \
       ctime depth inum ls mtime nogroup nouser perm print prune \
       size xdev)/' \
       'p/*/d/'	

	#zfs
	complete zfs 'p/1/(get set list destroy snapshot create clone promote send recv hold )/' \
		'n/list/`zfs list -t all | cut -w -f1`/' \
		'n/destroy/`zfs list -t all   | cut -w -f1`/' \
		'n/send/`zfs list -t all | cut -w -f1`/' \
		'n/snapshot/`zfs list | cut -w -f1`/' \
		'n/promote/`zfs list -t all  | cut -w -f1`/' \
		'n/get/`zfs get all  | cut -w -f2 | sort | uniq`/' \
		'n/set/`zfs get all  | cut -w -f2 | sort | uniq`/=' 'N/set/`zfs list | cut -w -f1`/' \
	
	# groups
	complete chgrp 'p/1/g/'
	# users
	complete chown 'p/1/u/' 
	complete setenv 'p/1/e/'
	complete unsetenv 'p/1/e/'
	complete set 'p/1/s/='
	complete uncomplete 'p/*/X/'
	complete dd           'c/if=/f/' 'c/of=/f/' \
                        'c/conv=*,/(ascii block ebcdic lcase pareven noerror notrunc osync sparse swab sync unblock)/,' \
                        'c/conv=/(ascii block ebcdic lcase pareven noerror notrunc osync sparse swab sync unblock)/,' \
                        'p/*/(bs cbs count files fillcahr ibs if iseek obs of oseek seek skip conv)/='

	complete cd 'C/*/d/'
	complete kill 'c/-/S/' 'c/%/j/' 
	alias interfaces  "ifconfig | cut -d: -f1 | cut -f1 | sort | grep -v lo  | uniq "
	set tdterms = (proto tcp udp icmp ether fddi ip arp ip6 dir src dst inbound outbound port  portrange less greatergateway net and or host src dst broadcast multicast atalk ipx decnet on rulenum reason rset subrulenum action vlan mpls ppoed iso vpi  lane llc oam4s link slip icmp-echoreply icmp-unreach icmp-sourcequench  icmp-redirect icmp-echo icmp-routeradvert icmp-routersolicit icmp-timxceed icmp-paramprob icmp-tstamp icmp-tstam-preply icmp-ireq icmp-ireqreply icmp-maskreq icmp-maskreply tcp-fin tcp-syn tcp-rst tcp-push tcp-ack tcp-urg )
	alias  td "sudo tcpdump -lvvnX -s200  -i "
	complete td  'p/1/$interfaces/' 'p/*/$tdterms/'
	alias tdtrace 'echo "interface \!\!:1 file: \!\!:2 expression: \!\!:3-$";              sudo tcpdump -s0 -i \!\!:1 -C 24 -W 10 -w \!\!:2`date +"%s"`.\!\!:1.pcap                                \!\!:3-$'
	alias screenshotX11window 'xwd | convert - jpeg:- > \!\!:1.jpeg'
	complete tdtrace 'p/1/$interfaces/' 'p/2/(pcapfile inny outty sqick foo)/' 'p/*/$tdterms/'
	alias screenlet 'screen -S `echo \!\!:1 | cut -w -f1  ` -dm \!\!:1' 
	alias sc screen
	complete sc 'p/1/(-r) /' 'p/2/`screen -ls | grep tached | space2tab | cut -f2 | cut -f2 -d.`/' 
	alias  sa screen -r
	complete sa  'p/1/`screen -ls | grep tached | sed "s/[ \t][0-9]*\.\([0-z]*\).*/\1/"`'
	alias  td 'tcpdump  -n'
	complete td 'p/1/( -i )/' 'p/2/`ifconfig | cut -d: -f1 | cut -f1 | sort  | uniq `/' 'p/*/( -v -x -X -wfile -rfile -s00 )/'
	complete ifconfig  'p/1/`ifconfig | cut -d: -f1 | cut -f1 | sort  | uniq `/' 'p/*/( -v -x -X -wfile -rfile -s1500 )/'
	complete dc 'p/1/(-e)/' 'n/-e/(16o16iDEADp 2p32^p)/' 
	complete sysctl 'n/*/`sysctl -aN`/'
	complete kldload 'p|1|`ls /boot/modules`|'
	complete umount 'p^1^`mount | cut -w -f3`^'
	complete dtrace 'p/1/(-s -n -l -q)/'   \
			'n/-s/f/'
	alias dt_providers  'dtrace -ln ":::" | chomp | cut -w -f2 | sort | uniq'
	# based on https://github.com/cobber/git-tools/blob/master/tcsh/completions

	set gitcmds=(add bisect blame branch checkout cherry-pick clean clone commit describe difftool fetch grep help init \
			log ls-files mergetool mv push rebase remote rm show show-branch status submodule tag)

	complete git          "p/1/(${gitcmds})/" \
			'n/branch/`git-list all branches`/' \
			'n/checkout/`git-list all branches tags`/' \
			'n/clean/(-dXn -dXf)/' \
			'n/diff/`git-list all branches tags`/' \
			'n/fetch/`git-list repos`/' \
			"n/help/(${gitcmds})/" \
			'n/init/( --bare --template= )/' \
			'n/merge/`git-list all branches tags`/' \
			'n/push/`git-list repos`/' \
			'N/remote/`git-list repos`/' \
			'n/remote/( show add rm prune update )/' \
			'n/show-branch/`git-list all branches`/' \
			'n/stash/( apply branch clear drop list pop show )/' \
			'n/submodule/( add foreach init status summary sync update )/'

	complete gpart        'p/1/(add backup bootcode commit create delete destroy modify recover resize restore set show undo unset)/' \
			'n/add/x:-t type [-a alignment] [-b start] [-s size] [-i index] [-l label] -f flags geom/' \
			'n/backup/x:geom/' \
			'n/bootcode/x:[-b bootcode] [-p partcode -i index] [-f flags] geom/' \
			'n/commit/x:geom/' \
			'n/create/x:-s scheme [-n entries] [-f flags] provider/' \
			'n/delete/x:-i index [-f flags] geom/' \
			'n/destroy/x:[-F] [-f flags] geom/' \
			'n/modify/x:-i index [-l label] [-t type] [-f flags] geom/' \
			'n/recover/x:[-f flags] geom/' \
			'n/resize/x:-i index [-a alignment] [-s size] [-f flags] geom/' \
			'n/restore/x:[-lF] [-f flags] provider [...]/' \
			'n/set/x:-a attrib -i index [-f flags] geom/' \
			'n/show/x:[-l | -r] [-p] [geom ...]/' \
			'n/undo/x:geom/' \
                        'n/unset/x:-a attrib -i index [-f flags] geom/'

	complete cu 'p/1/( -l )/' 'n^-l^`ls /dev/{cu,tty}*[0-9]*`^' 'n/-s/( 9600 115200 38400 )/'

	if ( -f /etc/printcap ) then
		set printers=(`sed -n -e "/^[^      #].*:/s/:.*//p" /etc/printcap`)
		complete lpr        'c/-P/$printers/'   
		complete lpq        'c/-P/$printers/'
		complete lprm       'c/-P/$printers/'
	endif
	
    alias tat 'cvs status | grep Stat | grep -v Up-to-date'
	set dunique
	set colorcat
	set prompt2="loop%R>"
	set prompt3="willis?   %R   >"
	setenv EDITOR `which vi`
	set autolist
	set printexitvalue
	#if something takes 1 sec - find out how long. 
	set time=(1 "user:%U system:%S wall:%E cpu:%P%% shared:%X+private:%DkB  input:%I output:%O faultsin:%F swaps:%W")
	#unset color
	#unsetenv LS_COLOR
	set listflags="XaA"
	alias v 	view
	alias ssh-initagent 'mkdir -v -m 700 -p ${HOME}/.tmp/; ssh-agent -c > ${HOME}/.tmp/ssh-agent.csh; source  ${HOME}/.tmp/ssh-agent.csh'
	alias keydsaold 	'cat ~/.ssh/id_[rd]sa.pub ; sleep 3; cat ~/.ssh/id_*sa.pub  | ssh \!\!:1 "mkdir -p .ssh; chmod 700 .ssh; cat - >> .ssh/authorized_keys2; chmod 600 .ssh/authorized_keys2"'
	alias keydsa 		'cat ~/.ssh/id_*sa.pub ; sleep 3; cat ~/.ssh/id_*sa.pub     | ssh \!\!:1 "mkdir -p .ssh; chmod 700 .ssh; cat - >> .ssh/authorized_keys ; chmod 600 .ssh/authorized_keys"'
	alias fixcshrc 'mv -f ~/.cshrc /tmp/oldcshrc; scp xpi@aeria.net:.cshrc ~/'
	complete keydsa  'p/1/$hosts/'
	alias keydrop 'echo "keydropping ssh key (two seconds to abort)" ; grep "^\!\!:1" ~/.ssh/known_hosts || echo "did you mean this one?:"; grep \!\!:1 ~/.ssh/known_hosts ; sleep 1; echo "."; sleep 1; cp ~/.ssh/known_hosts /tmp/; cat ~/.ssh/known_hosts | sed -e "/^\!\!:1/d" > /tmp/keytmp && cp /tmp/keytmp ~/.ssh/known_hosts'
	complete keydrop 'p/1/$hosts/'
	if ( -f ${HOME}/.tmp/ssh-agent.csh ) then
		set ssh_agent_report=`source ${HOME}/.tmp/ssh-agent.csh; echo "";  ssh-add -l`
		#what could possibly wrong with picking up a random file?
	endif
	alias df	df -k
	alias du	du -xk
	alias h		'history -r | more'
	alias wipe	'echo -n  > '
	alias lf	ls -FA
	alias ll	ls -lgsArtF
	alias lr	ls -lgsAFR
	alias netwtf 	'netstat -in; curl 'http://geoiplookup.wikimedia.org' &;  p tunnelclient; ping -c 1 -q 8.8.8.8 > /dev/null || echo "google unreachable" & ; ping -c1 -q aeria.net > /dev/null || echo "aeria unrch" &; '
	alias tset	'set noglob histchars=""; eval `\tset -s \!*`; unset noglob histchars'
	alias lerg 'date >> ${HOME}/env/lerg; vi + ${HOME}/env/lerg'
	alias mc  'mc -b'
	set nobeep
    set correct = cmd
	set nostat="/afs /.a /proc /.amd /.automount /net"
	set fignore=( .o .a .bak ~ , .v .bad .old .syms .dylib .lst .ld .so .org .virg. .tmp .pyc .oo .al .exe .dll .obj . .1 .svn CVS )
	set symlinks=expand
	#set filec ##// tcsh implicit complettion 
	set nokanji
	set histdup erase
	set implicitcd=verbose
	#set savedirs  ##/annoying rentrant behaviours
	set listmax = 120
	set history = 1000
	set ignoreeof = 5
	umask 22
	#version
	set	dcmesg = ".cshrc> $ashrcversion ${gUNAME} "
	printf "\b/"
	# make help/ins key do something useful for a change, the loafy-bitch
	bindkey -c ^[[2~ 'setenv eetmp `date +"%s"`.tcshtmp;  history > /tmp/${eetmp}; vi /tmp/${eetmp}'
	#f13
	bindkey ^[[25~ vi-search-back
	#f12
	bindkey ^[[24~ complete-word-back
	#f11
	bindkey ^[[23~ complete-word-fwd
	#f10
	bindkey ^[[21~ delete-word
	#f9
	bindkey ^[[20~ backward-delete-word
	#f8
	bindkey ^[[19~ forward-word
    #mac opt ->
	bindkey ^]f backward-word
	#f7
	bindkey ^[[18~ backward-word
    #mac opt <-
	bindkey ^[b backward-word
	#f2
	bindkey -c ^[OQ 'date +"%s" >> ~/lerg;  cat cltmp >> ~/lerg' 
	#f1  edit last command line
	bindkey -c ^[OP 'echo "\!\!" > $HOME/tmp/cltmp; vi $HOME/tmp/cltmp'

	#smart up key
	bindkey -k up history-search-backward
	bindkey -k down history-search-forward
	
	if (  ${?TERM} & ${TERM} =~ "xterm*" || ${TERM} == "screen"  ) then
		printf '\033]0;%s\033\' "xt:$user@${HOST} `date`" #title block settings
		setenv Xgreenscreenopts '-bg black -fg green'
		alias xterm xterm  ${Xgreenscreenopts}
		set betterfont="-*-droid sans mono-*-*-*-*-*-*-*-*-*-*-*-*"
		alias xt 'xterm ${Xgreenscreenopts} \\
			-fn "$betterfont" &'
		alias xt8 'xterm ${Xgreenscreenopts} \\
			-fn "-*-*-*-*-*-*-*-80-*-*-*-*-*-*" &'
		alias xt20 'xterm -bg black -fg green -fn \\
			"-*-*-*-*-*-*-*-200-*-*-*-*-*-*" &'
		alias xt30 'xterm -bg black -fg green -fn \\
			"-*-*-*-*-*-*-*-300-*-*-*-*-*-*" &'
		alias xt40 'xterm -bg black -fg green -fn \\
			"-*-*-*-*-*-*-*-400-*-*-*-*-*-*" &'
		if ( $USER == "root" ) then 
			printf "\b\n\033[31m\033[43m thou art root\n"
		else
			printf "\b\n\033[35m" #purple
			#foreach i ( `jot 49` ) 
			#	printf "\b\n\033[%sm %s" "$i" "$i"
			#end
		endif
	endif #xterm specializations

endif #prompt


#________________________________________________________________
if ( ${gUNAME} == "Linux" ) then
if ( $?prompt ) then
	unalias ls
	unalias vi
	alias p		"ps -efwww | grep -v grep | grep "
	complete p 'p/1/`ps -efwww | cut -b39-120 `/'
	complete kill 'c/-/S/' 'c/%/j/' 'p/1/`ps -ef | cut -b10-15 `/'
	alias monstar	'tail -f /var/log/messages &;\
		 tail -f /var/log/daemon &; \
		 tail -f /var/log/syslog & '

endif #prompt
endif
#________________________________________________________________
if ( ${gUNAME} == "Darwin" ) then
setenv MANPATH /sw/share/man/:$MANPATH
setenv PAGER `which less`
if ( $?prompt ) then
	complete redtide 'p/1/`ps -axwww`/'
endif #prompt
endif #darwin
#________________________________________________________________
if ( ${gUNAME} == "FreeBSD" ) then
	alias monstar 'tail -f /var/log/{messages,auth.log,mail.log}'
	setenv REDCOL 0  #why is ps a mercurial flower?
	complete redtide 'p/1/`ps -auxwww`/'
	if ( -f /etc/csh.chsrc ) then
		source /etc/csh.cshrc	
	endif #etcskel
	complete service 'p/1/`service -l`/' 'p/2/( start  stop restart rcvar enabled status poll)/'
endif #freebsd
#________________________________________________________________
if ( ${gUNAME} == "SunOS" ) then
	if ( $?prompt ) then
		echo "SunOS environment - Illuminos?"
	endif #prompt 
	alias monstar	'tail -f /var/adm/messages &;\
			tail -f /var/log/syslog & '
	alias ps        /usr/ucb/ps
	setenv EDITOR /usr/ucb/vi
	setenv PATH /usr/ucb:${PATH} #replace stupid sun tools with BSDisms 
	setenv PATH ${PATH}:/usr/ccs/bin #base compiler and bintools
	setenv PATH ${PATH}:/usr/opt/SUNWmd/sbin #for raid tools
	setenv PATH ${PATH}:/usr/platform/sun4u/sbin #for prtdiag

endif ##sunos

setenv CVSROOT 'xpi@death.aeria.net:/home/xpi/CVSPrivate'

setenv BUGS 1
setenv SRCBASE ~/src
setenv LIBBASE ~/src/lib

setenv CVS_RSH	`which ssh`
setenv RSYNC_RSH `which ssh`	 
setenv RSH `which ssh`	 #for rdist
#______________________________________________________________________securitry
#/________________________________________________________the last word locally
#makes all things here mutable
#let the local thing bollackup  my nice presets
if ( -r ${HOME}/.cshrc.local ) then
	source ${HOME}/.cshrc.local
endif 

if ( $?prompt ) then
	printf "\b\\"
	if ( $user == "root" ) then 
		set prompt="#"
	else
		set prompt="%"
	endif
		
	printf "\b*\b"
	echo  $dcmesg
	if ( $?ssh_agent_report ) then 
		echo $ssh_agent_report 
	endif
endif # if prompt

