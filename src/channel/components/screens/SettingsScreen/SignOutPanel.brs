Function init()
 m.Name = m.top.findNode("Name")
 m.Email = m.top.findNode("Email")
 m.top.observeField("name", "onNameChanged")
 m.top.observeField("email", "onEmailChanged")
End Function

Function onNameChanged()
 if m.top.name <> invalid and m.top.name <> ""
   m.Name.text = "You're signed in as " + m.top.name
 else
   m.Name.text = ""
 end if
End Function

Function onEmailChanged()
 if m.top.email <> invalid and m.top.email <> ""
   m.Email.text = "Email: " + m.top.email
 else
   m.Email.text = ""
 end if
End Function
