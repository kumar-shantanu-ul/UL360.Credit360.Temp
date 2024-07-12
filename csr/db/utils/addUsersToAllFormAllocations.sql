set serveroutput on
declare
	v_act_id security_pkg.T_ACT_ID;
	v_item_list VARCHAR2(32767);
	v_user_list VARCHAR2(32767);
begin
	user_pkg.logonauthenticated(security_pkg.sid_builtin_administrator,86400,v_act_id);
	for fr in (select * from form_allocation where form_sid in (1871084,1936141,1936187,1938253,1945242,1871055,1871072,1871075,1871076,1917017,1917090,1917094,1917098,1917118,1917128,1917154,1917219,1917238,1917272,1917289,1922283,1922306,1922349,1922427,1922474,1922526,1922555,1922663,1922709,1922763,1922847,1923014,1923218,1923243,1923326,1923341,1923352,1923444,1923465,1923544,1923575,1923617,1930067,1930070,1930119,1930137,1932274,1930214,1930216,1930225,1930269,1930369,1930482,1931999,1932288,1932293,1932294,1932309,1932317,1932325,1932333,1932334,1932335,1932336,1932337,1932338,1932340,1933078,1933096,1933116,1933425,1933427,1933435,1933453,1933590,1934677,1934707,1936097,1936282,1938233,1938234,1938252,1946151,1954686,2041706,2098961,7701349,7732083,7742447,7742467,7742475,7750871,7750986,7750995,7753223,7760857,7836974,7840126,7840134,7887980,7974225,7731986,7731987,7742476,7742483,7745356,5800919,7745378,7750878,7750970,7750993,7751000,7751017,7751025,5809813,9528597,1922333,1933064,1945890)) loop
		v_user_list := '9292828';
		for ru in (select * from form_allocation_user where form_allocation_id = fr.form_allocation_id and user_sid not in (9292828)) loop
			v_user_list := v_user_list || ',' || ru.user_Sid;
		end loop;
		v_item_list := null;
		for ri in (select * from form_allocation_item where form_allocation_id = fr.form_allocation_id) loop
			if v_item_list is not null then
				v_item_list := v_item_list || ',';
			end if;
			v_item_list := v_item_list || ri.item_sid;
		end loop;
		dbms_output.put_line('form sid ' || fr.form_sid || ', allocation ' || fr.form_allocation_id || ', users = ' || v_user_list || ', items = ' || v_item_list);
		form_pkg.setformallocation(v_act_id, fr.form_sid, fr.form_allocation_id, v_user_list, v_item_list);
	end loop;
end;
/