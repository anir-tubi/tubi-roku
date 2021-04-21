Function unobserveAllFieldsScoped(component)
  if type(component) = "roSGNode"
    fields = component.getFields()
    
    for each field in fields
      component.unobserveFieldScoped(field)
    end for
  end if
End Function


Function unobserveAllFields(component)
  if type(component) = "roSGNode"
    fields = component.getFields()
    
    for each field in fields
      component.unobserveField(field)
    end for
  end if
End Function