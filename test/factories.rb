FactoryGirl.define do

# Sequences
  prng = Random.new(340592340914)
  sequence :credits do
    prng.rand 2..10
  end

  sequence :course_code do |n|
    "T-106.#{n.to_s.rjust(4, '0')}"
  end


# Factories
  factory :curriculum do
    sequence(:name) { |n| "Curriculum #{n}" }
    start_year 2006
    end_year 2020
  end

  factory :competence do 
    type       'Competence'
    credits
    level      1
    curriculum
  end

  factory :scoped_course do 
    type        'ScopedCourse'
    credits
    course_code
  end

  factory :skill do
    position  1
    level     1
    credits

  end

end