declare 
    host security.website.website_name%TYPE := '&host';
    delegation_sid security_pkg.T_SID_ID := &delegation_sid;
    layout_id csr.delegation_layout.layout_id%TYPE;
begin
    security.user_pkg.LogonAdmin(host);

    csr.delegation_pkg.CreateLayoutTemplate( 
        XMLTYPE(
            '<table>'||chr(10)||
            '  <tbody>'||chr(10)||
            '    <tr>'||chr(10)||
            '      <td></td>'||chr(10)||
            '      <td>Unit</td>'||chr(10)||
            '      <td for="$region" in="Regions">$region</td>'||chr(10)||
            '    </tr>'||chr(10)||
            '    <tr for="$indicator" in="Indicators">'||chr(10)||
            '      <th>$indicator</th>'||chr(10)||
            '      <td conversion-id="uom" />'||chr(10)||
            '      <td for="$region" in="regions"'||chr(10)||
            '          indicator="$indicator" region="$region"'||chr(10)||
            '          conversion-ref="uom" />'||chr(10)||
            '    </tr>'||chr(10)||
            '  </tbody>'||chr(10)||
            '</table>'),
        'Auto generated layout',
        layout_id);

    csr.delegation_pkg.SetLayoutTemplate(delegation_sid, layout_id);

    dbms_output.put_line('Layout id = ' || layout_id);
end;
/
