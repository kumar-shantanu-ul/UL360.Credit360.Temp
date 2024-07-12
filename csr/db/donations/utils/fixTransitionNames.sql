begin
  for r in (
      select transition_sid, (
        select description from donation_status where donation_status_sid = from_donation_status_sid
        )  || '  to  ' ||
        (
        select description from donation_status where donation_status_sid = to_donation_status_sid
        ) full_name
        from transition
  )
  LOOP
    securableobject_pkg.renameso(sys_context('security','act'), r.transition_sid, r.full_name);
  END LOOP;
end;
