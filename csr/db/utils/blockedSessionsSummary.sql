COLUMN blocker FORMAT a75
select  s2.sid || ' ' ||s2.serial#|| ' ' ||s2.username|| ' ' ||s2.status|| ' ' ||s2.osuser|| ' ' ||s2.machine|| ' ' ||s2.program blocker,
        count(s1.sid) blocked_sessions
  from v$session s1, v$session s2
 where s1.blocking_session is not null
   and s1.blocking_session = s2.sid
 group by s2.sid,s2.sid,s2.serial#,s2.username,s2.status,s2.osuser,s2.machine,s2.program;