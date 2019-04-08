-- ----------------------------------------------------------------------------------------------------
-- 1 Teachers


-- 1.1 get 2.0 teachers
DROP TABLE IF EXISTS memory.teacher_pref.teachers;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.teachers AS
SELECT tun.id AS teacher_id
	, tun.uuid AS teacher_sso_id
	, bui.uid AS teacher_ss_id
	, tun.english_name
	, fts.first_eff_start_time
	, 2 AS sys
FROM ssmysql.sishu.bk_user_info AS bui
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp
		ON pp.is_cur = TRUE
	INNER JOIN ssmysql.sishu.bk_user AS bu
		ON bui.uid = bu.uid
	INNER JOIN uumysql.newuuabc.teacher_user_new AS tun
		ON bu.uuid = CAST(tun.uuid AS varchar)
	INNER JOIN (
		SELECT ts.teacher_id
			, FROM_UNIXTIME(MIN(tc.effective_start_time) / 1000) AS first_eff_start_time
		FROM uumysql.teacher_contract.teacher_signed AS ts
			INNER JOIN uumysql.teacher_contract.teacher_contract AS tc
				ON ts.id = tc.signed_id
		WHERE ts.enable = 1 AND ts.status = 1 AND tc.enable = 1
		GROUP BY ts.teacher_id
	) AS fts
		ON fts.teacher_id = tun.id
WHERE -- bui.status = 1
	bui.status IN (1, 2) -- 离职的老师: 将来根据离职日期来判断，拉取当月离职的老师
	AND bui.dpid IN (SELECT id FROM ssmysql.sishu.bk_department WHERE parentid = 24)
	AND tun.disable = 1 AND tun.status = 3 AND tun.type = 1
	AND fts.first_eff_start_time < pp.etime
;


-- 1.2 get 1.0 teachers
INSERT INTO memory.teacher_pref.teachers
SELECT tun.id AS teacher_id
	, tun.uuid AS teacher_sso_id
	, NULL AS teacher_ss_id
	, tun.english_name
	, fts.first_eff_start_time
	, 1 AS sys
FROM uumysql.newuuabc.teacher_user_new AS tun
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp
		ON pp.is_cur = TRUE
	INNER JOIN (
		SELECT ts.teacher_id
			, FROM_UNIXTIME(MIN(tc.effective_start_time)) AS first_eff_start_time
		FROM uumysql.newuuabc.teacher_signed AS ts
			INNER JOIN uumysql.newuuabc.teacher_contract AS tc
				ON ts.id = tc.signed_id
		WHERE ts.enable = 1 AND ts.status = 1
		GROUP BY ts.teacher_id
	) AS fts
		ON fts.teacher_id = tun.id
WHERE tun.status = 3 AND tun."type" = 1 AND tun.disable = 1
	AND tun.id NOT IN (SELECT teacher_id FROM memory.teacher_pref.teachers WHERE sys=2)
	AND fts.first_eff_start_time < pp.etime
;


-- -----------------------------------------------------------------------------------------
-- 3. teacher leave

-- 3.1 from sys 1.5

DROP TABLE IF EXISTS memory.teacher_pref.teacher_leave;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.teacher_leave AS
SELECT t.teacher_id
	, t.teacher_sso_id
	, FROM_UNIXTIME(tl.start_time) + INTERVAL '8' HOUR AS start_time
	, FROM_UNIXTIME(tl.end_time) + INTERVAL '8' HOUR AS end_time
	, FROM_UNIXTIME(tl.create_at) + INTERVAL '8' HOUR AS create_time
	, (tl.start_time - tl.create_at) / 3600.0 AS apply_before_hours
	, IF(tl."type" = 3 -- 年假不影响 bonus
		 OR (tl.start_time - tl.create_at) / 3600.0  > pp.min_allow_bonus_leave_hours
		, 0, 1) AS is_bonus_affected
	, 1 AS sys
FROM uumysql.newuuabc.teacher_leave AS tl
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp
		ON is_cur = TRUE
	INNER JOIN memory.teacher_pref.teachers AS t
		ON tl.teacher_user_id = t.teacher_id
WHERE tl.status < 3
	-- AND end_time >= to_unixtime(pp.stime_utc)
	-- AND start_time < to_unixtime(pp.etime_utc)
	AND start_time >= to_unixtime(pp.stime_utc)  -- 只需要结算周期内才开始的请假
	AND start_time < to_unixtime(pp.etime_utc)
;


-- 3.2 from sys 2.0

INSERT INTO memory.teacher_pref.teacher_leave
SELECT t.teacher_id
	, t.teacher_sso_id
	, from_unixtime(bl.starttime) AS start_time
	, from_unixtime(bl.endtime) AS end_time
	, from_unixtime(bl.addtime) AS create_time
	, (bl.starttime - bl.addtime) / 3600.0 AS apply_before_hours
	, IF((bl.starttime - bl.addtime) / 3600.0  > pp.min_allow_bonus_leave_hours
		, 0, 1) AS is_bonus_affected
	, 2 AS sys
FROM ssmysql.sishu.bk_leave AS bl
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp
		ON is_cur = true
	INNER JOIN ssmysql.sishu.bk_check AS c
		ON bl.id = c.jnid AND c."type" = 1
	INNER JOIN memory.teacher_pref.teachers AS t
		ON bl.uid = t.teacher_ss_id
WHERE c.sh = 1
	AND bl.display = 1
	AND c.display = 1
	-- AND bl.endtime >= to_unixtime(pp.stime)
	-- AND bl.starttime < to_unixtime(pp.etime)
	AND bl.starttime >= to_unixtime(pp.stime)		-- 只需要结算周期内才开始的请假
	AND bl.starttime < to_unixtime(pp.etime)
;



-- ----------------------------------------------------------------------------------------------------
-- 4. teacher absence

-- 4.1 from sys 1.5

DROP TABLE IF EXISTS memory.teacher_pref.teacher_absence;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.teacher_absence AS
SELECT t.teacher_id
	, t.teacher_sso_id
	, FROM_UNIXTIME(start_time) AS start_time
	, FROM_UNIXTIME(end_time) AS end_time
	, (end_time - start_time) / 60 AS duration
	, 1 AS sys
FROM uumysql.newuuabc.teacher_absenteeism AS ta
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp
		ON is_cur = TRUE
	INNER JOIN memory.teacher_pref.teachers AS t
		ON ta.teacher_id = t.teacher_id
WHERE  ta.status < 3
	AND end_time >= to_unixtime(pp.stime)
	AND start_time < to_unixtime(pp.etime)
;
