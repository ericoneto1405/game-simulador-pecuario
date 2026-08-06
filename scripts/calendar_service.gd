class_name CalendarService

const MONTH_LENGTHS := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


static func is_leap_year(year: int) -> bool:
	return year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)


static func days_in_year(year: int) -> int:
	return 366 if is_leap_year(year) else 365


static func month_length(year: int, month: int) -> int:
	if month == 2 and is_leap_year(year):
		return 29
	return int(MONTH_LENGTHS[clampi(month, 1, 12) - 1])


static func day_of_year_from_date(year: int, month: int, day: int) -> int:
	var result := clampi(day, 1, month_length(year, month))
	for previous_month in range(1, clampi(month, 1, 12)):
		result += month_length(year, previous_month)
	return result


static func calendar_month_and_day(day_of_year: int, year: int) -> Vector2i:
	var remaining_days := clampi(day_of_year, 1, days_in_year(year))
	for month_index in range(MONTH_LENGTHS.size()):
		var ml := month_length(year, month_index + 1)
		if remaining_days <= ml:
			return Vector2i(month_index + 1, remaining_days)
		remaining_days -= ml
	return Vector2i(12, 31)


static func formatted_date(day_of_year: int, year: int) -> String:
	var md := calendar_month_and_day(day_of_year, year)
	return "%02d/%02d/%04d" % [md.y, md.x, year]


static func migrate_legacy_day_of_year(legacy_day_of_year: int) -> int:
	var old_day := clampi(legacy_day_of_year, 1, 360)
	var old_month_index := (old_day - 1) / 30
	var old_month_day := ((old_day - 1) % 30) + 1
	old_month_day = mini(old_month_day, int(MONTH_LENGTHS[old_month_index]))
	var migrated_day := old_month_day
	for month_index in range(old_month_index):
		migrated_day += int(MONTH_LENGTHS[month_index])
	return migrated_day


static func civil_day_number(year: int, month: int, day: int) -> int:
	var adjusted_year := year
	var adjusted_month := month
	if adjusted_month <= 2:
		adjusted_year -= 1
		adjusted_month += 12
	return (
		365 * adjusted_year
		+ floori(adjusted_year / 4.0)
		- floori(adjusted_year / 100.0)
		+ floori(adjusted_year / 400.0)
		+ floori((153 * (adjusted_month - 3) + 2) / 5.0)
		+ day - 1
	)


static func local_datetime_from_server_unix(
	unix_utc: int,
	server_utc_offset_seconds: int
) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(unix_utc + server_utc_offset_seconds)


static func days_between_server_dates(
	from_unix_utc: int,
	to_unix_utc: int,
	server_utc_offset_seconds: int
) -> int:
	if from_unix_utc <= 0 or to_unix_utc <= from_unix_utc:
		return 0
	var from_date := local_datetime_from_server_unix(from_unix_utc, server_utc_offset_seconds)
	var to_date := local_datetime_from_server_unix(to_unix_utc, server_utc_offset_seconds)
	return maxi(
		civil_day_number(
			int(to_date["year"]), int(to_date["month"]), int(to_date["day"])
		) - civil_day_number(
			int(from_date["year"]), int(from_date["month"]), int(from_date["day"])
		),
		0
	)
