param(
    [string]$Namespace = "recon-platform",
    [string]$MqPod = "ibm-mq-0",
    [string]$QueueManager = "QM1",
    [string]$Principal = "app"
)

$ErrorActionPreference = "Stop"

$mqsc = @"
SET AUTHREC OBJTYPE(QMGR) PRINCIPAL('$Principal') AUTHADD(CONNECT,INQ,DSP)
SET AUTHREC PROFILE('RECON.IN') OBJTYPE(QUEUE) PRINCIPAL('$Principal') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('RECON.RETRY') OBJTYPE(QUEUE) PRINCIPAL('$Principal') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('RECON.BACKOUT') OBJTYPE(QUEUE) PRINCIPAL('$Principal') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('RECON.REPLAY') OBJTYPE(QUEUE) PRINCIPAL('$Principal') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('SYSTEM.DEAD.LETTER.QUEUE') OBJTYPE(QUEUE) PRINCIPAL('$Principal') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
REFRESH SECURITY TYPE(AUTHSERV)
"@

$mqsc | kubectl exec -i -n $Namespace $MqPod -- runmqsc $QueueManager

Write-Host "Applied IBM MQ OAM authorities for principal '$Principal' on queue manager '$QueueManager'."
