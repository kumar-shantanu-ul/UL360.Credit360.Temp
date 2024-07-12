BEGIN
	user_pkg.logonadmin('&&1');
	UPDATE region 
	  SET region_type = 3
	 WHERE region_type = 0
	   AND region_sid IN (SELECT region_sid
						    FROM region
						   WHERE CONNECT_BY_ISLEAF = 1
						   START WITH region_sid IN (SELECT region_tree_root_sid
													   FROM region_tree
													  WHERE is_primary = 1)
						 CONNECT BY PRIOR region_sid = parent_sid);
END;
/