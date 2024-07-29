function RegistryUtil() as Object
    registry = {

        '** Writes value to Registry
        '@param key Registry section key
        '@param val value to write
        '@param section Registry section name
        write: function(key as String, val as String, section = "OTsdkReg" as String) as Void
            sec = createObject("roRegistrySection", section)
            sec.write(key, val.tostr())
            sec.flush()
        end function

        '** Writes multiple values to Registry
        '@param keys is an AA with the keys and values to be written
        '@param section Registry section name
        writeKeys: function(keys as object, section = "OTsdkReg" as String) as Void
            sec = createObject("roRegistrySection", section)
            for each key in keys
                if keys[key] = invalid then keys[key] = ""
                sec.write(key, keys[key].tostr())
            end for
            sec.flush()
        end function

        '** Reads value from Registry
        '@param key Registry section key
        '@param section Registry section name
        read: function(key as String, section = "OTsdkReg" as String) as Dynamic
            sec = createObject("roRegistrySection", section)
            if sec.exists(key) then return sec.read(key)
            return invalid
        end function

        '** Retrieve all entries in the specified section
        '@param section Registry section name
        readSection: function(section = "OTsdkReg" as String) as Object
            sec = createObject("roRegistrySection", section)
            aa = {}
            keyList = sec.getKeyList()
            for each key in keyList
                aa[key] = m.read(key, section)
            end for
            return aa
        end function

        writeSection: function(keys as Object,section = "OTsdkReg" as String) as Object
            sec = createObject("roRegistrySection", section)
            sec.WriteMulti(keys)
            sec.flush()
        end function

        '** Deletes multiple key value from Registry
        '@param key Registry section key
        '@param section Registry section name
        delete: function(key as String, section = "OTsdkReg" as String) as Dynamic
            sec = createObject("roRegistrySection", section)
            if sec.exists(key) then return sec.delete(key)
            return invalid
        end function

          '** Deletes key value from Registry
        '@param list of keys to delete from registry
        '@param section Registry section name
        deleteKeys: function(keys as object, section = "OTsdkReg" as String) as Dynamic
            sec = createObject("roRegistrySection", section)
            for each key in keys
                if sec.exists(key) then sec.delete(key)
            end for
            return invalid
        end function

        '** Deletes all key values from the specified section
        '@param section Registry section name
        deleteSection: function(section = "OTsdkReg" as String) as Boolean
            reg = createObject("roRegistry")
            res = reg.delete(section)
            reg.flush()
            return res
        end function
        
        '** get available space in the registry
        ' converts bytes to kb - 1000B = 1kb 
        GetSpaceAvailable: function() as integer
            reg = CreateObject("roRegistry")
            availableSpace = reg.GetSpaceAvailable()
            return availableSpace / 1000
        end function
    }

    return registry
end function

function getRegGroupData() as object
    groups = {}
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    if sdkReg.Exists("groupData")
        groupData = sdkReg.Read("groupData")
        if groupData <> invalid then groups = ParseJson(sdkReg.Read("groupData"))
    end if
    return groups
end function

function saveGroupsToRegistry(groupData as object)
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
end function
