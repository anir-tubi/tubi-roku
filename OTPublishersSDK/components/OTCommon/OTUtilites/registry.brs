Function RegistryUtil() as Object
  registry = {

    '** Writes value to Registry
    '@param key Registry section key
    '@param val value to write
    '@param section Registry section name
    write: Function(key as String, val as Dynamic, section = "OTsdkReg" as String) as Void
      sec = createObject("roRegistrySection", section)
      try
        val = val.tostr()
      catch e
        val = FormatJson(val)
      end try
      sec.write(key, val)
      sec.flush()
    End Function

    '** Writes multiple values to Registry
    '@param keys is an AA with the keys and values to be written
    '@param section Registry section name
    writeKeys: Function(keys as Object, section = "OTsdkReg" as String) as Void
      sec = createObject("roRegistrySection", section)
      for each key in keys
        if keys[key] = invalid then keys[key] = ""
        try
          val = keys[key].tostr()
        catch e
          val = FormatJson(keys[key])
        end try
        sec.write(key, val)
      end for
      sec.flush()
    End Function

    '** Reads value from Registry
    '@param key Registry section key
    '@param section Registry section name
    read: Function(key as String, section = "OTsdkReg" as String) as Dynamic
      sec = createObject("roRegistrySection", section)
      if sec.exists(key) then return sec.read(key)
      return invalid
    End Function

    '** Retrieve all entries in the specified section
    '@param section Registry section name
    readSection: Function(section = "OTsdkReg" as String) as Object
      sec = createObject("roRegistrySection", section)
      aa = {}
      keyList = sec.getKeyList()
      for each key in keyList
        aa[key] = m.read(key, section)
      end for
      return aa
    End Function

    writeSection: Function(keys as Object, section = "OTsdkReg" as String) as Object
      sec = createObject("roRegistrySection", section)
      sec.WriteMulti(keys)
      sec.flush()
    End Function

    '** Deletes multiple key value from Registry
    '@param key Registry section key
    '@param section Registry section name
    delete: Function(key as String, section = "OTsdkReg" as String) as Dynamic
      sec = createObject("roRegistrySection", section)
      if sec.exists(key) then return sec.delete(key)
      return invalid
    End Function

    '** Deletes key value from Registry
    '@param list of keys to delete from registry
    '@param section Registry section name
    deleteKeys: Function(keys as Object, section = "OTsdkReg" as String) as Dynamic
      sec = createObject("roRegistrySection", section)
      for each key in keys
        if sec.exists(key) then sec.delete(key)
      end for
      return invalid
    End Function

    '** Deletes all key values from the specified section
    '@param section Registry section name
    deleteSection: Function(section = "OTsdkReg" as String) as Boolean
      reg = createObject("roRegistry")
      res = reg.delete(section)
      reg.flush()
      return res
    End Function

    '** get available space in the registry
    ' converts bytes to kb - 1000B = 1kb
    GetSpaceAvailable: Function() as Integer
      reg = CreateObject("roRegistry")
      availableSpace = reg.GetSpaceAvailable()
      return availableSpace / 1000
    End Function
  }

  return registry
End Function

Function getRegGroupData() as Object
  groups = {}
  sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
  if sdkReg.Exists("groupData")
    groupData = sdkReg.Read("groupData")
    if groupData <> invalid then groups = ParseJson(sdkReg.Read("groupData"))
  end if
  return groups
End Function

Function saveGroupsToRegistry(groupData as Object)
  groupData = ParseJson(FormatJson(groupData))
  sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
  gpData = getRegGroupData()
  if groupData <> invalid
    groupData.Delete("iab")
    groupData.Delete("google")
    gpData.append(groupData)
    sdkReg.Write("groupData", FormatJson(gpData))
    sdkReg.Flush()
  end if
End Function
