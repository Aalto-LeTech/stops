FactoryGirl.define do

  prng = Random.new(340592340914)
  sequence :credits do
    prng.rand 2..10
  end

  sequence :course_code do |n|
    "T-106.#{n.to_s.rjust(4, '0')}"
  end

  factory :skill do
    position  1
    level     1
    credits
  end

  factory :scoped_course do 
    type        'ScopedCourse'
    credits
    course_code
  end

end