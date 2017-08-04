print "Hot Patch 2.3.oldui"


' Disallow SMS for activation
m.app.registerScreen.allowSMS = false
m.app.registerScreen.exitOnBack = true