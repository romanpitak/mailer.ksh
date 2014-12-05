# MAILER

This is a mailer script. 

(c) 2011-2014 [Roman Piták](http://pitak.net) roman@pitak.net

## OPTIONS

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
  
## EXAMPLES

    mailer.sh To:roman@pitak.net sUbJeCt:'test mail' body:'this is\\\\na test email'
  
Implemented by Roman Pitak (roman@pitak.net)

