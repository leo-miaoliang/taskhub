CREATE SCHEMA IF NOT EXISTS memory.teacher_pref;


-- 结算周期及其设置
DROP TABLE IF EXISTS memory.teacher_pref.setting_payperiod;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.setting_payperiod AS
SELECT date_trunc('month', current_timestamp - INTERVAL '1' DAY) AS stime  -- include
	, date_trunc('month', current_timestamp - INTERVAL '1' DAY) - interval '8' hour AS stime_utc
	, cast(current_date AS timestamp) AS etime 	-- not include
	, cast(current_date AS timestamp) - interval '8' hour AS etime_utc
	-- 费用设置
	, 15 AS standby_usd_h
	-- 时间设置
	, 12 * 60 * 60 AS max_class_create_in_urgent  -- 最大允许的紧急课程课前创建时间间隔: <=
	, 0 AS min_come_late_seconds -- 最小允许的迟到时间: >
	, 0 AS min_leave_early_seconds -- 最小允许的早退时间: >
	, 24 * 60 * 60 AS max_fb_deferred_seconds -- 最大允许的延迟评语时间: <= 
	, 7 * 24 AS min_allow_bonus_leave_hours   -- 最小允许的请假提前时间: >
	-- 扣款设置, rod = rate of deduction
	, 0.2 AS come_late_rod 		-- 迟到扣款率
	, 0.2 AS leave_early_rod 	--　早退扣款率
	, 1 AS fb_rod				-- 未提交评语扣款率
	-- 手续费
	, 0 AS subsidy_bank_usd
	, 22 AS subsidy_paypal_usd
	, TRUE AS is_cur
;



DROP TABLE IF EXISTS memory.teacher_pref.dim_timeslot;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.dim_timeslot AS
SELECT d
	, day_of_week(d) AS wk
	, day_of_week(d) % 7 AS wk_old
	, ct.start_time
	, ct.end_time
	, time '00:00' + parse_duration(concat(cast(ct.start_time as varchar), 'm')) as stm
	, time '00:00' + parse_duration(concat(cast(ct.end_time as varchar), 'm')) as etm
FROM (
	SELECT current_date - INTERVAL '1' DAY AS d
)
CROSS JOIN uumysql.teacher_contract.carport_time AS ct
ORDER BY d, start_time
;
