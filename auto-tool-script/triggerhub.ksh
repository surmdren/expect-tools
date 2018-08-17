#!/bin/bash
# To automate repeatable DBA tasks.
# Version 1.0 by Thiago Cargnelutti - 2013/09/16
# Version 2.0 by Thiago Cargnelutti - 2014/01/10
# Version 3.0 by Thiago Cargnelutti - 2014/04/04
# Version 4.0 by DB2 team -2018/05/29
# Version 5.0 by DB2 team -2018/05/31

mode=
paramsfile=
inputlist=
uploadlogic=
uploadextra=
logicparams=
tempdirectory=
commands=

parmlist="${*}"
for parm in ${parmlist};   do
      case ${parm} in
        '-?') script_help='Y' ;;
        '-HELP') script_help='Y' ;;
        '/?') script_help='Y' ;;
        '-help') script_help='Y' ;;
        '-h') script_help='Y' ;;
      esac
done

while getopts ":f:i:l:e:d:p:s:k:" opt
do
  case $opt in
	f) paramsfile=$OPTARG ;;
        i) inputlist=$OPTARG ;;
        l) uploadlogic=$OPTARG ;;
        e) uploadextra=$OPTARG ;;
        d) tempdirectory=$OPTARG ;;
       esac
done

if [ -z $paramsfile ] && [ -z $inputlist ]; then 
  echo " "
  echo "Either a parameters file (option -f) or a list of target servers/instances (option -i) should be provided."
  echo " "
  script_help='Y'
fi

if [ ! -z $paramsfile ] && [ ! -z $inputlist ] ; then
  echo " "
  echo "Both a parameters file (option -f) and a list of target servers/instances (option -i) are not accepted at the same time."
  echo " "
  script_help='Y'
fi

if [[ ! -z $inputlist ]]; then
  if [[ -z $uploadlogic ]] || [[ -z $tempdirectory ]] ; then
    echo " "
    echo "When a parameters file is not used, it's supposed to go with an uploaded logic. So the options -l and -d must be provided."
    echo " "
    script_help='Y'
  fi
  if [[ ! -f $uploadlogic ]] ; then
    echo " "
    echo "The informed logic script could not be found."
    echo " "
    exit "99"
  fi
fi

if [[ ${script_help} = "Y" ]]; then
    echo " "
    echo "Usage: triggerhub.ksh -f <parameters file>
       triggerhub.ksh -i <servers list file>
       		                        [-l < logic script >]
	                                [-e < extra1.xxx_extra2.xxx_... >] 
	 			        [-d < directory >]
					[-p < file | prompt >]

                Mandatory parameters:
                        -f File name with parameters.
			OR
			-i File name with target servers/instances.

                Optional parameters:
                        -l Script to be uploaded and executed on target servers.  DEFAULTS to none.
                        -e Extra files to be uploaded and support logic script execution.  DEFAULTS to none.
			-d Temp directory that will be created under /tmp on target servers. DEFAULTS to none.

                        Other parameters which can be used for help:
                        -?          : Help (same as -help)
                        -HELP       : Help (same as -?)
                        -help       : Help (same as -?)
                        -h       : Help (same as -?)
                        /?       : Help (same as -?)
    "
    echo " "
    exit "99"
fi

if [[ ! -z $paramsfile ]]; then
	if [[ ! -f $paramsfile ]]; then
		echo " "
		echo "The informed responses file could not be found."
		echo " "
		exit "99"
	fi
	. $paramsfile
	if [[ $mode == "upload" ]]; then
		if [[ ! -f $uploadlogic ]] ; then
			echo " "
			echo "The informed logic script could not be found."
			echo " "
			exit "99"
		fi
		if [[ -z $tempdirectory ]]; then
			echo " "
			echo "Temp directory name was not informed. Please verify the parameters file, field tempdirectory."
			echo " "
			exit "99"
		fi
		if [[ ! -z $logicparams ]]; then
			readyexp=`grep "logic_ksh | tee" autospreadchanges.exp | wc -l`
			if [[ $readyexp -eq 1 ]]; then
				sed "s/logic_ksh | tee/logic_ksh ${logicparams} | tee/" autospreadchanges.exp >autospreadchanges.exp.logic
				mv autospreadchanges.exp autospreadchanges.exp.ori
	                        mv autospreadchanges.exp.logic autospreadchanges.exp
       	         	else
                        	echo " "
				echo "The script autospreadchanges.exp is not provided in its original content. Please copy it from the deployment repository, instead of reusing it from other executions. This script may be modified as part of the execution flow."
				echo " "
				exit "99"
			fi
		fi
	elif [[ $mode == "simple" ]]; then
		uploadlogic=
		uploadextra=
		logicparams=
		tempdirectory=
		if [[ -z $commands ]]; then
			echo " "
			echo "The commands were not informed. Please verify the parameters file, field commands."
			echo " "
			exit "99"
		fi
		readyexp=`grep "TO BE REPLACED" autospreadchanges.exp  | wc -l`
		if [[ $readyexp -eq 1 ]]; then
			sed "s/TO BE REPLACED WHEN GOING SIMPLE/${commands}/" autospreadchanges.exp >autospreadchanges.exp.simple
			mv autospreadchanges.exp autospreadchanges.exp.ori
			mv autospreadchanges.exp.simple autospreadchanges.exp
		else
			echo " "
			echo "The script autospreadchanges.exp is not provided in its original content. Please copy it from the deployment repository, instead of reusing it from other executions. This script may be modified as part of the execution flow."
			echo " "
			exit "99"
		fi
	else
		echo " "
		echo "The mode was not informed. Please verify the parameters file, field mode."
		echo " "
		exit "99"
	fi
fi

if [[ ! -f $inputlist ]]; then
	echo " "
	echo "The file listing servers and userids could not be found."
	echo " "
	exit "99"
fi

if [ -f results.Fail.out ]; then rm results.Fail.out; fi
if [ -f results.OK.out ]; then rm results.OK.out; fi
if [ -f results.SudoError.out ]; then rm results.SudoError.out; fi
if [ -f results.AuthError.out ]; then rm results.AuthError.out; fi
if [ -f results.NoResolve.out ]; then rm results.NoResolve.out; fi
if [ -f results.NoResponse.out ]; then rm results.NoResponse.out; fi
if [ -f results.IDnotExist.out ]; then rm results.IDnotExist.out; fi
if [ -f results.NewPwd.out ]; then rm results.NewPwd.out; fi
if [ -f results.RSA.out ]; then rm results.RSA.out; fi
if [ -f remaining_notCovered1.txt ]; then rm remaining_notCovered1.txt; fi
if [ -f remaining_notCovered2.txt ]; then rm remaining_notCovered2.txt; fi
if [ -f BadEnvironment.txt ]; then rm BadEnvironment.txt; fi
if [ -f inplacelogic.out.* ]; then rm inplacelogic.out.*; fi
if [ -f output.* ]; then rm output.*; fi
if [ -f results.*.out.1 ]; then rm results.*.out.1; fi
if [ -f results.*.out.2 ]; then rm results.*.out.2; fi
if [ -f $inputlist.fmt* ]; then rm $inputlist.fmt*; fi

chmod u+x multi.ksh
chmod u+x autospreadchanges.exp
cat $inputlist >$inputlist.fmt

echo ""
totalIlines=`wc -l $inputlist | awk '{print $1}'`
totalNlines=`wc -l $inputlist.fmt | awk '{print $1}'`
echo "Number of servers: $totalNlines"

echo ""

if [[ -z $uploadlogic ]] ; then
	upload_ksh=0
else
	upload_ksh=1
fi

curdir=`pwd`
if [ -f $inputlist.fmt ]; then
if [[ $upload_ksh -eq 0 ]]; then
	./multi.ksh $inputlist.fmt $upload_ksh
else
	if [[ -z $uploadextra ]]; then
		./multi.ksh $inputlist.fmt $upload_ksh 0extra $uploadlogic $tempdirectory
	else
		./multi.ksh $inputlist.fmt $upload_ksh 1extra $uploadlogic $uploadextra $tempdirectory
	fi	
fi
fi

#echo "Results with the first credentials: (checking against input to record remaining ones, if any)"
count_ok=`wc -l results.OK.out 2>/dev/null | awk '{print $1}'`
count_sudo=`wc -l results.SudoError.out 2>/dev/null | awk '{print $1}'`
count_auth=`wc -l results.AuthError.out 2>/dev/null | awk '{print $1}'`
count_resolve=`wc -l results.NoResolve.out 2>/dev/null | awk '{print $1}'`
count_response=`wc -l results.NoResponse.out 2>/dev/null | awk '{print $1}'`
count_fail=`wc -l results.Fail.out 2>/dev/null | awk '{print $1}'`
count_id=`wc -l results.IDnotExist.out 2>/dev/null | awk '{print $1}'`
count_newpwd=`wc -l results.NewPwd.out 2>/dev/null | awk '{print $1}'`
count_RSA=`wc -l results.RSA.out 2>/dev/null | awk '{print $1}'`

while read baseline; do
	((done=0))
	((sudo=0))
        ((auth=0))
        ((resolve=0))
        ((response=0))
        ((fail=0))
        ((id=0))
        ((newpw=0))
	((rsa=0))
	baseline_only_server=`echo $baseline | cut -d" " -f1`
	if [[ $count_ok -gt 0 ]]; then
		while read oK; do
			if [[ $baseline = $oK ]]; then
				echo "OK: $baseline OK"
				((done=1))
				break
			fi
		done < results.OK.out
	fi
	if [[ $count_sudo -gt 0 ]]; then
		while read sudoError; do
			if [[ $baseline = $sudoError ]]; then
				echo "Error on su: $baseline"
				((sudo=1))
				break
			fi
		done <results.SudoError.out
	fi
        if [[ $count_auth -gt 0 ]]; then
                while read authError authErrorInst; do #spliting instance for performance matters
			#authError=`echo $authError | cut -d" " -f1`
                        if [[ $baseline_only_server = $authError ]]; then
                                echo "Error on authentication: $baseline_only_server"
                                ((auth=1))
                                break
                        fi
                done <results.AuthError.out
        fi
        if [[ $count_resolve -gt 0 ]]; then
                while read resolveError resolveErrorInst; do
			#resolveError=`echo $resolveError | cut -d" " -f1`
                        if [[ $baseline_only_server = $resolveError ]]; then
                                echo "Name resolution problem: $baseline_only_server"
                                ((resolve=1))
                                break
                        fi
                done <results.NoResolve.out
        fi
        if [[ $count_response -gt 0 ]]; then
                while read responseError responseErrorInst; do
			#responseError=`echo $responseError | cut -d" " -f1`
                        if [[ $baseline_only_server = $responseError ]]; then
                                echo "Server not responding: $baseline_only_server"
                                ((response=1))
                                break
                        fi
                done <results.NoResponse.out
        fi
        if [[ $count_fail -gt 0 ]]; then
                while read failError failErrorInst; do
			#failError=`echo $failError | cut -d" " -f1`
                        if [[ $baseline_only_server = $failError ]]; then
                                echo "Exp Timeout or Other failure: $baseline_only_server"
                                ((fail=1))
                                break
                        fi
                done <results.Fail.out
        fi
        if [[ $count_id -gt 0 ]]; then
                while read idError; do
                        if [[ $baseline = $idError ]]; then
                                echo "ID does not exist any more: $baseline"
                                ((id=1))
                                break
                        fi
                done <results.IDnotExist.out
        fi
        if [[ $count_newpwd -gt 0 ]]; then
                while read pwdchange pwdchangeInst; do
			#pwdchange=`echo $pwdchange | cut -d" " -f1`
                        if [[ $baseline_only_server = $pwdchange ]]; then
                                echo "New password set: $baseline_only_server"
                                ((newpwd=1))
                                break
                        fi
                done <results.NewPwd.out
        fi
        if [[ $count_RSA -gt 0 ]]; then
                while read anyrsa anyrsa_Insts; do
                        if [[ $baseline_only_server = $anyrsa ]]; then
                                echo "RSA key changed: $baseline_only_server"
                                ((rsa=1))
                                break
                        fi
                done <results.RSA.out
        fi
	if [[ $done = 0 && $sudo = 0 && $auth = 0 && $resolve = 0 && $response = 0 && $fail = 0 && $id = 0 && $newpwd = 0 && $rsa = 0 ]]; then
                echo $baseline >>remaining_notCovered1.txt
	fi
done <$inputlist

echo ""
echo "succeeded: $count_ok"
echo "su failed: $count_sudo"
echo "authentication failed: $count_auth"
echo "name resolution failed: $count_resolve"
echo "server response failed: $count_response"
echo "RSA key changed - failed: $count_RSA"
echo "expect timeout and other - failed: $count_fail"

echo ""
echo Total succeeded: $count_ok

if [[ ! -f remaining_notCovered1.txt ]]; then
	remain1=0
else
	remain1=`wc -l remaining_notCovered1.txt| awk '{print $1}'`
fi
echo "not processed, not recorded in result files:" $remain1
echo ""

rm -rf $tempdirectory
mkdir $tempdirectory
mv inplacelogic* $tempdirectory
mv results* $tempdirectory
mv output* $tempdirectory
