
-- 总课时 ---------------------------------------------
-- 2.0

DROP TABLE IF EXISTS memory.teacher_pref.teacher_timeslot;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.teacher_timeslot AS
SELECT dt.d
	, t.teacher_id
	, dt.start_time
	, dt.stm
	, if(tl.teacher_id IS NULL, 0, 1) AS is_leave
	, if(ta.teacher_id IS NULL, 0, 1) AS is_abst
FROM uumysql.teacher_contract.signed_time as st
	INNER JOIN memory.teacher_pref.teachers AS t
		ON st.teacher_id = t.teacher_id AND t.sys = 2
	INNER JOIN uumysql.teacher_contract.teacher_signed AS ts
		ON st.signed_id = ts.id
	INNER JOIN uumysql.teacher_contract.carport_time AS ct
		ON st.start_time <= ct.start_time
			AND st.end_time >= ct.end_time
	INNER JOIN memory.teacher_pref.dim_timeslot AS dt
		ON st.weekday = dt.wk
			AND ct.start_time = dt.start_time
			and to_unixtime(dt.d) + dt.start_time * 60 >= st.effective_start_time / 1000
			and to_unixtime(dt.d) + dt.end_time * 60 <= st.effective_end_time / 1000
	LEFT join memory.teacher_pref.teacher_leave_fixed AS tl
		ON t.teacher_id = tl.teacher_id
			and to_unixtime(dt.d) + dt.start_time * 60 >= to_unixtime(tl.start_time)
			and to_unixtime(dt.d) + dt.end_time * 60 <= to_unixtime(tl.end_time)
	LEFT join memory.teacher_pref.teacher_absence AS ta
		ON t.teacher_id = ta.teacher_id
			and to_unixtime(dt.d) + dt.start_time * 60 >= to_unixtime(ta.start_time)
			and to_unixtime(dt.d) + dt.end_time * 60 <= to_unixtime(ta.end_time)
WHERE ts.enable = 1 AND ts.status = 1
order by dt.d, t.teacher_id, ct.start_time
;


-- 1.0

INSERT INTO memory.teacher_pref.teacher_timeslot
SELECT dt.d
	, t.teacher_id
	, dt.start_time
	, dt.stm
	, if(tl.teacher_id IS NULL, 0, 1) AS is_leave
	, if(ta.teacher_id IS NULL, 0, 1) AS is_abst
FROM uumysql.newuuabc.signed_time as st
	INNER JOIN memory.teacher_pref.teachers AS t
		ON st.teacher_user_id = t.teacher_id AND t.sys = 1
	INNER JOIN uumysql.newuuabc.teacher_signed AS ts
		ON st.signed_id = ts.id
	INNER JOIN uumysql.newuuabc.carport_time AS ct
		ON st.start_time <= ct.start_time
			AND st.end_time >= ct.end_time
	INNER JOIN memory.teacher_pref.dim_timeslot AS dt
		ON st.weekday = dt.wk_old
			AND ct.start_time = dt.start_time
			and to_unixtime(dt.d) + dt.start_time * 60 >= st.effective_start_time
			and to_unixtime(dt.d) + dt.end_time * 60 <= st.effective_end_time
	LEFT join memory.teacher_pref.teacher_leave_fixed AS tl
		ON t.teacher_id = tl.teacher_id
			and to_unixtime(dt.d) + dt.start_time * 60 >= to_unixtime(tl.start_time)
			and to_unixtime(dt.d) + dt.end_time * 60 <= to_unixtime(tl.end_time)
	LEFT join memory.teacher_pref.teacher_absence AS ta
		ON t.teacher_id = ta.teacher_id
			and to_unixtime(dt.d) + dt.start_time * 60 >= to_unixtime(ta.start_time)
			and to_unixtime(dt.d) + dt.end_time * 60 <= to_unixtime(ta.end_time)
WHERE ts.enable = 1 AND ts.status = 1
order by dt.d, t.teacher_id, ct.start_time
;

