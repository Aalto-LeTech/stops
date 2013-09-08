CourseInstance.delete_all

instances = [
 ['CHEM-A1250', :period_i, 2],
 ['CSE-A1111', :period_i, 2],
 ['CSE-A1121', :period_iii, 2],
 ['CSE-A1130', :period_iii, 3],
 ['CSE-A1141', :period_i, 2],
 ['ENE-C2001', :period_v, 1],
 ['ENE-C3001', :period_i, 1],
 ['ENE-C3002', :period_ii, 1],
 ['ENG-3043.Kand', :period_i, 2],
 ['ENG-3043.Kand', :period_iii, 2],
 ['ENG-A1001', :period_iv, 2],
 ['ENG-A1002', :period_v, 1],
 ['ENG-A1004', :period_i, 1],
 ['ENG-A1005', :period_ii, 1],
 ['ENY-C2001', :period_i, 2],
 ['ENY-C2002', :period_i, 1],
 ['ENY-C2003', :period_i, 2],
 ['ENY-C2004', :period_v, 1],
 ['ENY-C2005', :period_iii, 1],
 ['KJR-C1001', :period_iv, 2],
 ['KJR-C2001', :period_iv, 2],
 ['KJR-C2002', :period_i, 2],
 ['KJR-C2003', :period_iv, 2],
 ['KJR-C2004', :period_iii, 2],
 ['KJR-C2005', :period_ii, 1],
 ['KJR-C2006', :period_iii, 1],
 ['KON-C3001', :period_i, 2],
 ['KON-C3002', :period_iv, 2],
 ['KON-C3004', :period_i, 2],
 ['MAA-C2001', :period_v, 1],
 ['MAA-C2002', :period_iii, 1],
 ['MAA-C2003', :period_iii, 1],
 ['MAA-C2004', :period_v, 1],
 ['MAA-C2005', :period_iv, 1],
 ['MAA-C3001', :period_i, 1],
 ['MEK-C3001', :period_iv, 2],
 ['MS-A0001', :period_i, 1],
 ['MS-A0101', :period_ii, 1],
 ['MS-A0201', :period_iii, 1],
 ['MS-A0301', :period_iv, 1],
 ['MS-A0401', :period_i, 1],
 ['MS-A0501', :period_i, 1],
 ['MS-C1050', :period_iii, 1],
 ['MS-C1080', :period_ii, 1],
 ['MS-C1110', :period_iii, 1],
 ['MS-C1280', :period_iv, 1],
 ['MS-C1300', :period_i, 1],
 ['MS-C1300', :period_iii, 1],
 ['MS-C1340', :period_ii, 1],
 ['MS-C1340', :period_iv, 1],
 ['MS-C1350', :period_i, 1],
 ['MS-C1420', :period_i, 1],
 ['MS-C1420', :period_iii, 1],
 ['MS-C1530', :period_iii, 1],
 ['MS-C1540', :period_iii, 1],
 ['MS-C1601', :period_iv, 1],
 ['MS-C1650', :period_iv, 1],
 ['MS-C1741', :period_iii, 2],
 ['MS-C2104', :period_iii, 2],
 ['MS-C2105', :period_iii, 1],
 ['MS-C2107', :period_i, 2],
 ['MS-C2107', :period_iii, 2],
 ['MS-C2111', :period_i, 2],
 ['MS-C2128', :period_i, 2],
 ['MS-C2132', :period_iii, 2],
 ['PHYS-A3120', :period_iii, 1],
 ['PHYS-A3130', :period_iv, 1],
 ['RAK-C3001', :period_i, 2],
 ['RAK-C3002', :period_iv, 2],
 ['RAK-C3003', :period_iv, 2],
 ['RYM-C1001', :period_i, 2],
 ['RYM-C1002', :period_iv, 2],
 ['RYM-C2001', :period_ii, 1],
 ['RYM-C2002', :period_i, 1],
 ['RYM-C2003', :period_v, 1],
 ['RYM-C2004', :period_i, 1],
 ['RYM-C3001', :period_i, 1],
 ['TU-A1100', :period_i, 2],
 ['TU-A1100', :period_iii, 2],
 ['YYT-C2001', :period_i, 1],
 ['YYT-C2002', :period_v, 1],
 ['YYT-C2003', :period_v, 1],
 ['YYT-C2004', :period_v, 1],
 ['YYT-C3001', :period_i, 1],
 ['YYT-C3002', :period_iii, 1]
]

period_numbers = {
  0 => :period_i,
  1 => :period_ii,
  2 => :period_iii,
  3 => :period_iv,
  4 => :period_v,
  5 => :period_s
}

periods = {}    # :period_i => [Period, Period, ...]
period_numbers.each_value do |period_symbol|
  periods[period_symbol] = []
end

Period.where("begins_at > '2013-08-01'").find_each do |period|
  period_symbol = period_numbers[period.number]
  periods[period_symbol] << period
end

abstract_courses = {}
AbstractCourse.find_each do |course|
  abstract_courses[course.code.strip] = course
  puts "'#{course.code}'"
end

instances.each do |instance_info|
  course = abstract_courses[instance_info[0]]
  
  unless course
    puts "Course '#{instance_info[0]}' not found"
    next
  end
  
  instance_periods = periods[instance_info[1]]
  length = instance_info[2]
  
  instance_periods.each do |period|
    CourseInstance.create(:abstract_course_id => course.id, :period_id => period.id, :length => length)
  end
end
