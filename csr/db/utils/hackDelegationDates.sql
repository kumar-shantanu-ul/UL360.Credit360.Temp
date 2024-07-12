-- change start_dtm, end_dtm, interval to required values
-- NUKES ALL SHEETS -- go run createNewSheet in a loop until all sheets are created
begin
	-- do all sub delegations
	for c in (
		select delegation_sid from delegation start with delegation_sid in (&&DELEGATION_SID) connect by prior delegation_sid = parent_sid
	) loop
    update delegation set start_dtm=to_date('2007-01-01','yyyy-mm-dd'),end_dtm=to_date('2009-01-01','yyyy-mm-dd'),interval='m'
    where delegation_sid=c.delegation_sid;
    for r in (select sheet_id from sheet where delegation_sid = c.delegation_sid) loop
      sheet_pkg.deleteSheet(r.sheet_id);
    end loop;
  end loop;
end;
/