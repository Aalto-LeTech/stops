# ENY Perusopinnot 70 op
eny_basic_mandatory = [
  'ENG-A1001',
  'ENG-A1002',
  'ENG-A1004',
  'ENG-A1005',
  'CSE-A1111',
  'CSE-A1130',
  'MS-A0006',
  'MS-A0106',
  'PHYS-A3120',
  'PHYS-A3130',
  'CHEM-A1250',
  'TU-A1100',
  'Kie-98.5001',
  'Kie-98.5002',
]

eny_basic_elective = [
  'MS-A0206',
  'MS-A0305',
  'MS-A0503',
  'MS-A0402',
]

# ENY Pääaine 50+10 op
eny_major_mandatory = [
  'ENY-C2001',
  'ENY-C2002',
  'ENY-C2003',
  'ENY-C2004',
  'ENY-C2005',
  'KJR-C2002',
  'KJR-C2003',
  'KJR-C2004',
  'ENG304x.Kand',
  'ENG304x.Kyps',
]
 
eny_major_elective = [
  'ENE-C2001',
  'ENE-C3001',
  'KJR-C1001',
  'MAA-C2001',
  'YYT-C2001',
  'YYT-C2002',
  'YYT-C2003',
  'YYT-C3001',
]

eny_mandatory = eny_basic_mandatory + eny_major_mandatory
eny_elective = eny_basic_elective + eny_major_elective



# KJR Perusopinnot 70 op:
kjr_basic_mandatory = [
  'ENG-A1001',
  'ENG-A1002',
  'ENG-A1004',
  'ENG-A1005',
  'CSE-A1111',
  'CSE-A1130',
  'MS-A0005',
  'MS-A0105',
  'MS-A0205',
  'MS-A0305',
  'PHYS-A3120',
  'PHYS-A3130',
  'CHEM-A1250',
  'TU-A1100',
  'Kie-98.5001',
  'Kie-98.5002',
]

kjr_basic_elective = [
]

#KJR Pääaine 50+10 op:
kjr_major_mandatory = [
  'ENY-C2001',
  'KJR-C1001',
  'KJR-C2001',
  'KJR-C2002',
  'KJR-C2003',
  'KJR-C2004',
  'KJR-C2005',
  'KJR-C2006',
  'ENG304x.Kand',
  'ENG304x.Kyps',
]
 
kjr_major_elective = [
  'KON-C3001',
  'KON-C3002',
  'KON-C3004',
  'MEK-C3001',
  'RAK-C3001',
  'RAK-C3003',
]

kjr_mandatory = kjr_basic_mandatory + kjr_major_mandatory
kjr_elective = kjr_basic_elective + kjr_major_elective

# RYM Perusopinnot 70 op:
rym_basic_mandatory = [
  'ENG-A1001',
  'ENG-A1002',
  'ENG-A1004',
  'ENG-A1005',
  'CSE-A1111',
  'CSE-A1130',
  'MS-A0006',
  'MS-A0106',
  'MS-A0502',
  'PHYS-A3120',
  'PHYS-A3130',
  'CHEM-A1250',
  'TU-A1100',
  'Kie-98.5001',
  'Kie-98.5002',
]

rym_basic_elective = [
  'MS-A0206',
  '30C00200',
]


# RYM Pääaine 50+10 op:
rym_major_mandatory = [
  'RYM-C1001',
  'RYM-C1002',
  'RYM-C2001',
  'RYM-C2002',
  'RYM-C2003',
  'RYM-C2004',
  'RYM-C3001',
  'MS-C2104',
  'ENG304x.Kand',
  'ENG304x.Kyps',
]

rym_major_elective = [
  'MAA-C2002',
  'MAA-C2003',
  'MAA-C2004',
  'YYT-C2004',
]

rym_mandatory = rym_basic_mandatory + rym_major_mandatory
rym_elective = rym_basic_elective + rym_major_elective

eny_major = CompetenceNode.find(73)
kjr_major = CompetenceNode.find(59)
rym_major = CompetenceNode.find(74)

eny = {name: 'ENY', node: eny_major, mandatory_courses: eny_mandatory, elective_courses: eny_elective}
kjr = {name: 'KJR', node: kjr_major, mandatory_courses: kjr_mandatory, elective_courses: kjr_elective}
rym = {name: 'RYM', node: rym_major, mandatory_courses: rym_mandatory, elective_courses: rym_elective}


def check(structure)
  puts structure[:name]
  
  supporting_prereqs = {}   # code => CompetenceNode
  structure[:node].supporting_prereqs.each do |node|
    supporting_prereqs[node.course_code] = node
  end

  # Check that all strict prereqs are included in mandatory courses
  puts "Mandatory prereqs"
  strict_prereqs = {}   # code => CompetenceNode
  structure[:node].recursive_prereqs.each do |node|
    strict_prereqs[node.course_code] = node
    #puts node.course_code
    
    puts "#{node.course_code} should not be mandatory" unless structure[:mandatory_courses].include?(node.course_code)
  end
  puts
    
  # Check that mandatory courses are included in strict prereqs
  structure[:mandatory_courses].each do |course_code|
    puts "#{course_code} is missing from strict prereqs" unless strict_prereqs[course_code]
  end
  puts
  
  # Check that elective courses are included in supporting prereqs
  puts "Supporting prereqs"
  structure[:elective_courses].each do |course_code|
    puts "#{course_code} is missing from supporting prereqs" unless supporting_prereqs[course_code]
  end
  puts
  puts
  
end

check(eny)
check(kjr)
check(rym)
