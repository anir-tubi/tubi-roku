print "Hot Patch 2.5.oldui"

' Disallow SMS for activation
m.app.registerScreen.allowSMS = false
m.app.registerScreen.exitOnBack = true

'Turn off Live TV
m.app.linearTV.showLinearTV = false
m.app.cp.showLinearTV = false
