# CourseInstance.delete_all
# PlanCourse.delete_all
# PlanCompetence.delete_all

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

PERIOD_NUMBER_BY_SYMBOL = {
  :period_i  => 0,
  :period_ii => 1,
  :period_iii=> 2,
  :period_iv => 3,
  :period_v  => 4,
  :period_s   => 5,
}

PERIOD_NUMBERS_OLD = {
  0 => :period_i,
  1 => :period_ii,
  2 => :period_iii,
  3 => :period_iv,
  4 => :period_s,
}

PERIOD_NUMBERS_NEW = {
  0 => :period_i,
  1 => :period_ii,
  2 => :period_iii,
  3 => :period_iv,
  4 => :period_v,
  5 => :period_s
}


def get_period_symbol_by_string(period_string)
  case period_string
    when 'I' then :period_i
    when 'II' then :period_ii
    when 'III' then :period_iii
    when 'IV' then :period_iv
    when 'V' then :period_v
  end
end

def get_length(period_start, period_end)
  PERIOD_NUMBER_BY_SYMBOL[period_end] - PERIOD_NUMBER_BY_SYMBOL[period_start] + 1
end


def create_instances(filename)
  # Load periods
  periods = {}    # :period_i => [Period, Period, ...]
  PERIOD_NUMBERS_NEW.each_value do |period_symbol|
    periods[period_symbol] = []
  end

  Period.where("begins_at < '2013-07-01'").order(:begins_at).find_each do |period|
    period_symbol = PERIOD_NUMBERS_OLD[period.number]
    periods[period_symbol] << period
  end
  Period.where("begins_at > '2013-07-01'").order(:begins_at).find_each do |period|
    period_symbol = PERIOD_NUMBERS_NEW[period.number]
    periods[period_symbol] << period
  end
    
  input = File.open(filename, 'r')
  input.each_line do |line|
    start_year = false
    end_year = false
    odd_year = false
    even_year = false
    force_length = false
    parts = line.split(':')
    course_code = parts[0]
    special_rules = parts[2]
    puts "#{course_code}"
    
    # Load course
    abstract_course = AbstractCourse.find_by_code(course_code)
    unless abstract_course
      puts "#{course_code} not found"
      next
    end
    
    abstract_course.course_descriptions.each do |description|
      description.default_period = parts[1]
      description.save
    end
    
    # Special rules
    if special_rules
      special_rules.strip!
      
      #print course_code
      even_year = special_rules.include?('even')
      odd_year = special_rules.include?('odd')
      
      if special_rules.include?('end')
        end_year = special_rules[4..-1].to_i
        #print " ends at #{end_year}"
      end
      
      if special_rules[0] == '2'
        start_year = special_rules[0..3].to_i
        #print " starts at #{start_year}"
      end
      
      if special_rules.include?('length')
        force_length = special_rules[7].to_i  # FIXME: this reads from the wrong place if there are multiple rules
        #print " length #{force_length}"
      end
      
      #print " even years" if even_year
      #print " odd years" if odd_year
      #puts
    end
    
    # Determine start and length
    parts[1].split(',').each do |period_string|
      length = force_length || 1
      period_parts = period_string.split('-')
      period_start_string = period_parts[0].strip
      next if period_start_string.empty?
      period_start = get_period_symbol_by_string(period_start_string)
      
      instance_periods = periods[period_start]
      unless instance_periods
        puts "Unknown period #{period_parts[0]} (#{course_code})"
        next
      end
      
      # Determine length
      if period_parts[1]
        period_end = get_period_symbol_by_string(period_parts[1].strip)
        length = get_length(period_start, period_end)
      end
      
      # Create instances
      instance_periods.each do |period|
        next if end_year && period.begins_at.year >= end_year
        next if start_year && period.begins_at.year < start_year
        next if odd_year && period.begins_at.year % 2 == 0
        next if even_year && period.begins_at.year % 2 == 1
        next if period.number == 4 && period.begins_at.year < 2014
        
        l = length
        l = 1 if period.number == 3 && period.begins_at.year < 2014
        
        CourseInstance.create(:abstract_course_id => abstract_course.id, :period_id => period.id, :length => l)
      end
    end
  end

  input.close()

end

create_instances('data/periods-misc.txt')
