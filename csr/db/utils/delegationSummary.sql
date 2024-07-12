exec user_pkg.logonadmin('experian.credit360.com');

-- imperfect if they split or do complex things but helpful for AMs
SELECT  
    CASE WHEN 
        LAG(name, 1) OVER (ORDER BY name) = x.name THEN null
        ELSE x.root_Sid
    END id,
    CASE WHEN 
        LAG(name, 1) OVER (ORDER BY name) = x.name THEN null
        ELSE x.NAME
    END NAME,
    CASE WHEN 
        LAG(NAME, 1) OVER (ORDER BY NAME) = x.NAME THEN NULL
        ELSE decode(interval, 'm','Monthly','q','Quarterly','h','Half yearly','y','Annual','Unknown')
    END INTERVAL,
    x.description, stragg(users) users
  FROM (
    SELECT d.root_sid, d.NAME, d.delegation_sid, d.INTERVAL, lvl, r.description, '('||lvl||') '||delegation_pkg.ConcatDelegationUsers(d.delegation_Sid) users
      FROM delegation_region dr, region r, (
        SELECT delegation_sid, name, level lvl, interval, connect_by_root delegation_sid root_sid
          FROM delegation
         WHERE end_dtm > '1 jan 2010'
         START WITH parent_sid =9910144
        CONNECT BY PRIOR delegation_sid = parent_Sid
    )d
    WHERE d.delegation_sid = dr.delegation_sid
      AND dr.region_sid = r.region_sid
)x
GROUP BY x.root_Sid, x.NAME, x.interval, x.description
ORDER BY x.root_Sid, x.name, x.description

