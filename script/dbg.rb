class Dbggr


  def initialize
    @locale = 'en'
    @course_classes = [
      AbstractCourse,
      ScopedCourse,
      CourseInstance,
      UserCourse,
      StudyPlanCourse
    ]
  end


  #=> Course Class Total Item Counts
  #      AbstractCourse  30
  #        ScopedCourse  69
  #      CourseInstance   0
  #          UserCourse   0
  #     StudyPlanCourse  30
  def print_course_class_total_item_counts
    puts "=> Course Class Total Item Counts"
    @course_classes.each do |course_class|
      puts "% 20s % 4d" % [ course_class, course_class.count ]
    end
  end


  # return abstract course info
  def abstract_course_to_s( abstract_course )
    return "[%03d] % 15s  : % 3d sc, % 3d ci, % 3d p" % [ abstract_course.id, abstract_course.code, abstract_course.scoped_courses.count, abstract_course.course_instances.count, abstract_course.periods.count ]
  end

  # lists all abstract courses
  def list_abstract_courses
    AbstractCourse.find_each do |abstract_course|
      puts "  " + abstract_course_to_s( abstract_course )
    end
  end


  # lists all scoped courses
  def list_scoped_courses
    ScopedCourse.find_each do |scoped_course|
      ac    = scoped_course.abstract_course
      acbcc = AbstractCourse.where( code: scoped_course.course_code ).first
      s = "  [%03d] % 40s  : " % [ scoped_course.id, scoped_course.name(@locale)[0,40] ]
      if ac and ac == acbcc
        puts s + abstract_course_to_s( ac )
      else
        puts s + "% 15s (%03d vs %03d)" % [ scoped_course.course_code, ac.nil? ? -1 : ac.id, acbcc.nil? ? -1 : acbcc.id ]
      end
    end
  end


  # lists all scoped courses with their abstract course code
  # and their prereq course names
  def list_course_prereqs
    ScopedCourse.find_each do |scoped_course|
      puts "Scoped: #{scoped_course.localized_description.name}"
      if scoped_course.abstract_course
        puts "Abstract: #{scoped_course.abstract_course.code}"
      else
        puts "Abstract: NULL"
      end
      if scoped_course.prereqs.size > 0
        puts "Prereqs:"
        scoped_course.prereqs.each do |prereq_course|
          puts " - #{prereq_course.localized_description.name}"
        end
      else
        puts "Prereqs: NONE"
      end
      puts "\n\n"
    end
  end


  # perform custom fixes related to scoped courses
  def fix_scoped_courses
    ScopedCourse.find_each do |scoped_course|
      puts 'SC[%03d]' % [ scoped_course.id ]
      acbcc = AbstractCourse.where( code: scoped_course.course_code ).first
      if acbcc.nil?
        puts ' - cleaning .abstract_course'
        scoped_course.abstract_course = nil
        scoped_course.save
      end
    end
  end


  # lists all course instances
  def list_course_instances
    CourseInstance.find_each do |course_instance|
      puts "  [%03d] % 15s % 4s-%d % 15s" % [ course_instance.id, course_instance.abstract_course.code, course_instance.period.symbol, course_instance.length, course_instance.period.name(@locale) ]
    end
  end


  # lists all user courses
  def list_user_courses
    UserCourse.find_each do |user_course|
      puts "  [%03d] % 25s  %d" % [ user_course.id, user_course.course_instance.dbg_name, user_course.grade ]
    end
  end


  # lists all periods
  def list_periods
    Period.find_each do |period|
      puts "  [%03d] % 3d % 4s % 4s [%s - %s] % 15s" % [ period.id, period.number, period.symbol, period.to_roman_numeral, period.begins_at, period.ends_at, period.name(@locale) ]
    end
  end


  # creates a few course instances
  def create_some_course_instances

    # input data
    data = [
      { code: 'MS-A0501',  raw_period: 'I-II'   },  # stl
      { code: 'MS-A0101',  raw_period: 'I-II'   },  # diff1
      { code: 'MS-A0201',  raw_period: 'III-IV' },  # diff2
      { code: 'CSE-A1121', raw_period: 'III-IV' },  # ohjp2
      { code: 'CSE-A1141', raw_period: 'III-IV' },  # trak
      { code: 'MS-C2104',  raw_period: 'III-IV' },  # tap
      { code: 'MS-C2105',  raw_period: 'III'    },  # op
      { code: 'MS-C2107',  raw_period: 'III-IV' },  # smt
      { code: 'MS-C2111',  raw_period: 'I-II'   }   # stop
    ]

    data.each do |dat|

      abstract_course = AbstractCourse.where( code: dat[:code] ).first
      raw_period = dat[:raw_period]

      if abstract_course.nil?
        puts "% 10s does not match any abstract course!" % [ dat.code ]
      else
        csv_matrix = CsvMatrix.new
        csv_matrix.create_course_instances( abstract_course, raw_period )
      end
    end
  end


  # creates a few user courses
  def get_period( sin )
    period_to_date = {
      'I'    =>  '-09-01',
      'II'   =>  '-11-01',
      'III'  =>  '-01-01',
      'IV'   =>  '-03-01',
      'S'    =>  '-06-01'
    }
    year, period = sin.split('-')
    sdate = year + period_to_date[ period ]
    Period.find_by_date( sdate )
  end


  # creates a few user courses
  def create_some_user_courses

    #UserCourse.destroy_all

    # input data
    data = [
      { code: 'MS-A0501',   time: '2011-I',    grade: 4   },  # stl
      { code: 'MS-A0101',   time: '2009-I',    grade: 3   },  # diff1
      { code: 'CSE-A1121',  time: '2010-III',  grade: 5   },  # ohjp2
      { code: 'CSE-A1141',  time: '2010-III',  grade: 5   },  # trak
      { code: 'MS-C2104',   time: '2011-III',  grade: 2   }   # tap
    ]

    @user = User.where( :id => 2 ).first

    data.each do |dat|
      puts 'creating user course |%s|...' % [ dat ]
    
      abstract_course = AbstractCourse.where( code: dat[:code] ).first
      if abstract_course.nil?
        raise 'nil abstract course!'
      end

      # check whether the user has already passed the course
      if @user.passed?( abstract_course )
        puts ' - course %s already passed' % ( abstract_course.code )
      end

      period = get_period( dat[:time] )
      course_instance = CourseInstance.where( 'abstract_course_id = ? AND period_id = ?', abstract_course.id, period.id ).first
      #course_instance = CourseInstance.where( :abstract_course => abstract_course, :period => period ).first
      if course_instance.nil?
        raise 'nil course_instance!'
      end

      # creating the user course
      ucourse = UserCourse.create(
        :user_id             =>  @user.id,
        :abstract_course_id  =>  abstract_course.id,
        :course_instance_id  =>  course_instance.id,
        :grade               =>  dat[:grade]
      )
    end
  end


  def dbg
    @user = User.where( :id => 2 ).first

    #create_some_course_instances
    #print_course_class_total_item_counts
    #fix_scoped_courses
    #list_abstract_courses
    #list_scoped_courses
    #list_course_instances
    list_user_courses
    #list_periods
    #create_some_user_courses
    #@user.user_courses.sort { |a, b| a.get_end_date <=> b.get_end_date }
    exit

    #y u

    @study_plan = @user.study_plan
    #y @study_plan

    #y @study_plan.courses.first
    #y @study_plan.study_plan_courses.first

    i = 0
    @study_plan.courses.each do |course|
      i += 1
      if i < 10
        next
      elsif i < 16
        puts "\n\n=> SC #{course.course_code} #{course.name(@locale)}\n\n"
        # modify database entries in order to have the course regarded as passed
    abstract_course
        #y course
        #y course.abstract_course
        if course.abstract_course

          #  create_table "user_courses", :force => true do |t|
          #    t.integer "user_id",            :null => false
          #    t.integer "abstract_course_id", :null => false
          #    t.integer "course_instance_id"
          #    t.integer "grade"
          #  end
          ucourse = UserCourse.create(
            :user_id             =>  @user.id,
            :abstract_course_id  =>  course.abstract_course.id,
            :course_instance_id  =>  course_instance.id,
            :grade               =>  1 + rand(5)
          )
          #ucourse = UserCourse( abstract_course = course.abstract_course )
          y ucourse
          #@user.user_courses.append( ucourse )
        else
          puts "NO ABSTRACT COURSE"
        end
      else
        break
      end
    end

    exit


    p = Period.first

    puts p.begins_at

    while d > p.begins_at.class
      puts d
    end

    y p


    exit


    StudyPlanCourse.find_each do |study_plan_course|
      puts "Scoped: #{study_plan_course.localized_description.name}"
      if study_plan_course.abstract_course
        puts "Abstract: #{study_plan_course.abstract_course.code}"
      else
        puts "Abstract: NULL"
      end
      puts "\n\n"
    end


    exit


    User.find_each do |user|
      puts "User: #{user.studentnumber}"
      if user.user_courses.size > 0
        puts "UserCourses:"
        user.user_courses.each do |user_course|
          puts " - #{user_course.scoped_course.name}"
        end
      else
        puts "UserCourses: NONE"
      end
      puts "\n\n"
    end
  end
end




dbggr = Dbggr.new
dbggr.dbg




