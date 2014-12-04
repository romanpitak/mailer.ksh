#!/usr/bin/ksh
############################################################
#
#                        MAILER
#
# This script sends emails
#
#
#      Author : Roman Pitak
#        date : 2011-05-19
#
# CHANGES :
#
# 2011-05-26 : changed the comunication engine from using "tail -f" to a coprocess
#              rapid speed increase
#              cleaned up the code
#
# 2011-07-18 : added configuration file
#
#############################################################

###########################
# configuration file init #
###########################

configurationFileName="$( echo "${0}" | sed -e 's/\.ksh$/\.conf/' )"
if test -f "${configurationFileName}" && test -x "${configurationFileName}"; then
  . ${configurationFileName}
else
  echo "WARNING : configuration file not found or not executable in \"${configurationFileName}\""
fi

##################
# variables init #
##################

# work mode
workMode="${defaultWorkMode:-help}"

typeset -i10 responseCode=0

##################
# functions init #
##################

alias echoLog='echo'
alias echoErr='echo'

function fatalErr {
  echo ${@:-}
  exit 1
}

function verboseEcho {
  test "${verbose}" = "YES" || return 0
  echoLog "$@"
  return 0
}
 
function say {
  verboseEcho "100 -> $@"
  print -p "${@:-}"
}

function getResponse {
  # TODO : timeout
  read -p response
  verboseEcho "100 <- ${response}"
  responseCode=$( echo "${response}" | sed -n -e 's/^\([0-9][0-9][0-9]\) .*$/\1/p' )
  test "${response}" = "Connection closed by foreign host." && responseCode=554 # fail
  return 0
}


#########################
# parameters processing #
#########################
while (( $# ))
do
  case "${1}" in
    -h|--help)
      workMode='help'
      shift
      ;;
      
    -v|--verbose)
      verbose='YES'
      shift
      ;;
      
    -b|--body)
      readBody='YES'
      shift
      ;;
      
    -m|--mailFile)
      if test $# -ge 2; then
        2="mailFile:${2}"
        shift
      else
        fatalErr "500 you must specify the file name of the mail file"
      fi
      ;;
      
      
    [Hh][Oo][Ss][Tt]\:*)
      SMTP_HOST="$( echo $1 | sed -e 's/^[Hh][Oo][Ss][Tt]:\(.*\)$/\1/' )"
      shift
      ;;
      
    [Pp][Oo][Rr][Tt]\:*)
      SMTP_PORT="$( echo $1 | sed -e 's/^[Pp][Oo][Rr][Tt]:\(.*\)$/\1/' )"
      shift
      ;;
      
    [Aa][Tt][Tt][Aa][Cc][Hh][Mm][Ee][Nn][Tt]\:*)
      attachment="$( echo $1 | sed -e 's/^[Aa][Tt][Tt][Aa][Cc][Hh][Mm][Ee][Nn][Tt]:\(.*\)$/\1/' )"
      shift
      test -f "${attachment}" && emailAttachment[${#emailAttachment[@]}]="${attachment}" || fatalErr "550 file not found \"${attachment}\""
      ;;
      
    -s|--subject) # set subject
      if test $# -ge 2; then
        2="subject:${2}"
        shift
      else
        fatalErr "500 you must specify the subject"
      fi
      ;;
    
    [Ss][Uu][Bb][Jj][Ee][Cc][Tt]\:*) # set subject
      emailSubject="$( echo $1 | sed -n -e 's/^[Ss][Uu][Bb][Jj][Ee][Cc][Tt]:\(.*\)$/\1/p' )"
      shift
      ;;

    [Ff][Rr][Oo][Mm]\:* ) # set sender
      emailFrom="$( echo $1 | sed -n -e 's/^[Ff][Rr][Oo][Mm]:\(.*\)$/\1/p' )"
      shift
      ;;
    
    [Tt][Oo]\:* ) # set recipient
      emailTo[${#emailTo[@]}]="$( echo $1 | sed -n -e 's/^[Tt][Oo]:\(.*\)$/\1/p' )"
      shift
      ;;
      
    [Cc][Cc]\:* ) # set carbon copy
      emailCc[${#emailCc[@]}]="$( echo $1 | sed -n -e 's/^[Cc][Cc]:\(.*\)$/\1/p' )"
      shift
      ;;
      
    [Rr][Ee][Pp][Ll][Yy]-[Tt][Oo]\:*|[Rr][Ee][Pp][Ll][Yy][Tt][Oo]\:*)
      emailReplyTo="$( echo $1 | sed -n -e 's/^[Rr][Ee][Pp][Ll][Yy]-\{0,1\}[Tt][Oo]:\(.*\)$/\1/p' )"
      shift
      ;;
      
    [Bb][Oo][Dd][Yy]\:*)
      emailBody="$( echo $1 | sed -e '1s/^[Bb][Oo][Dd][Yy]:\(.*\)$/\1/' )"
      shift
      ;;

    *)
      echoErr "501 your argument is invalid \"${1}\""
      workMode='help'
      shift
      break
      ;;
  esac
done

if test "${#emailTo[@]}" -gt 0; then
  workMode='mail'
else
  workMode='help'
fi


############################
# actual work is done here #
############################
case "${workMode}" in

  ###############################
  # print help message and exit #
  ###############################
  'help')
  
    echo "
  MAILER

  This is a mailer script. 

  options:
  -h|--help                     : prints this message
  -v|--verbose                  : turn on verbose output
  Body:                         : define the body of the message
  Subject:example               : define the subject
  To:user@example.com           : define the recipient(s)
  Cc:                           : define the carbon copy recipient(s)
  From:                         : define the sender
  Reply-To:                     : define the Reply-To field(s)
  Host:                         : smtp host ( default : ${SMTP_HOST:-not set} )
  Port:                         : smtp port ( default : ${SMTP_PORT:-not set} )
  Attachment:file_name.example  : attach a file
  
  examples:
  mailer.sh To:roman.pitak@gmail.com sUbJeCt:'test mail' body:'this is\\\\na test email'
  
  Implemented by Roman Pitak (roman@pitak.net)
  Source available at https://github.com/romanpitak/mailer.ksh
    "
    ;;
    
  # actualy attempt to send an email
  'mail')
      
    ###################################
    # start the telnet as a coprocess #
    ###################################
    telnet $SMTP_HOST $SMTP_PORT 2>&1 |&


    ####################################
    # wait for the connection to start #
    ####################################
    while getResponse ; do
      test "${responseCode}" -eq 220 && break
    done


    #############
    # say hello #
    #############
    say "HELO"
    getResponse
    test "${responseCode}" -eq 250 || fatalErr "500 HELO ERROR"


    #####################
    # declare the email #
    #####################
    say "MAIL FROM:<${emailFrom}>"
    getResponse
    test "${responseCode}" -eq 250 || fatalErr "500 FROM ERROR"


    ################
    # define "To:" #
    ################
    i=0
    while test "${i}" -lt "${#emailTo[@]}"; do
      say "RCPT TO:<${emailTo[i]}>"
      getResponse
      test "${responseCode}" -ne 250 && fatalErr "500 TO ERROR in \"${emailTo[i]}\""
      (( i += 1 ))
    done


    ################
    # define "Cc:" #
    ################
    i=0
    while test "${i}" -lt "${#emailCc[@]}"; do
      say "RCPT TO:<${emailCc[i]}>"
      getResponse
      test "${responseCode}" -ne 250 && fatalErr "500 TO ERROR in \"${emailCc[i]}\""
      (( i += 1 ))
    done

    ###########################
    # start the email message #
    ###########################
    say "DATA"
    getResponse code
    test "${responseCode}" -eq 354 || fatalErr "500 DATA ERROR"


    ################
    # email header #
    ################
    say "From: <${emailFrom}>"
    say "Subject: ${emailSubject:-}"


    ################
    # header "To:" #
    ################
    i=0
    while test "${i}" -lt "${#emailTo[@]}"; do
      say "To: <${emailTo[i]:-}>"
      (( i += 1 ))
    done


    ################
    # header "Cc:" #
    ################
    i=0
    while test "${i}" -lt "${#emailCc[@]}"; do
      say "Cc: <${emailCc[i]:-}>"
      (( i += 1 ))
    done


    ######################
    # header "Reply-To:" #
    ######################
    i=0
    while test "${i}" -lt "${#emailReplyTo[@]}"; do
      say "Reply-To: <${emailReplyTo[i]:-}>"
      (( i += 1 ))
    done

    #######################
    # end of email header #
    #######################

    ############################################
    # empty line - beginning of the email body #
    ############################################
    say


    ##############
    # email body #
    ##############

    say "${emailBody:-}"
    say
    say "${emailSignature:-}"


    ######################
    # insert attachments #
    ######################
    i=0
    while test "${i}" -lt "${#emailAttachment[@]}"; do
      uuencode ${emailAttachment[i]} $( echo ${emailAttachment[i]} | sed -e 's/\/.*\///' ) | while read encodedAttachmentLine; do
        say "${encodedAttachmentLine}"
      done
      (( i += 1 ))
    done


    #####################
    # end of email body #
    #####################
    say "." 
    getResponse
    test "${responseCode}" -ne 250 && fatalErr "500 queue ERROR"


    ########################
    # close the connection #
    ########################
    say "QUIT"
    getResponse
    test "${responseCode}" -eq 221 && echoLog "221 OK" || fatalErr "500 QUIT ERROR"
    ;;
    
esac










