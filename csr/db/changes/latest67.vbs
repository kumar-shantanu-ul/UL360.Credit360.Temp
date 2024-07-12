Function GetXml(ByVal so, ByVal attrPrefix)
    If IsObject(so.Attributes(attrPrefix + "-metadata")) Then
        If IsObject(so.Attributes(attrPrefix + "-metadata").Value) Then
            Dim m
            Set m = so.Attributes(attrPrefix + "-metadata")
            GetXml = m(attrPrefix)
        Else
            GetXml = so.Attributes(attrPrefix + "-metadata")
        End If
    Else
    
        GetXml = so.Attributes(attrPrefix + "-metadata")
    End If
    
End Function


Dim dbh, rs, sec
Set sec = CreateObject("NPSLSecurity2.Security")
sec.LogOnAuthenticated ("//builtin/administrator")
Set dbh = CreateObject("NPSLDA2.DBHelper")
dbh.OpenConnection "csr"
Set rs = dbh.RunSQLReturnRS("select csr_root_Sid, host from customer")

Do While Not rs.EOF
    Dim so
    Set so = sec.ReadObject(CLng(rs("csr_root_sid")))
    On Error Resume Next
    dbh.RunSQL "update customer set ind_info_xml_fields = ?, region_info_xml_fields = ?, user_info_xml_fields = ? where csr_root_sid = ?", _
        Array(GetXml(so, "ind"), GetXml(so, "region"), GetXml(so, "user"), rs("csr_root_sid"))
    If Err.Number <> 0 Then
        MsgBox "Error fixing up " & rs("host").Value & ": " & Err.Description
        Err.Clear
    End If
    rs.MoveNext
Loop

MsgBox "done!"
