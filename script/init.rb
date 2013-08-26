



PERIODS_PER_YEAR = 6




module Init

  def self.help

    puts "Usage: ./init.rb (init|dev|fix)"
    puts ""
    puts "Check the file before running!"

  end


  def self.cli

    if ARGV.empty?
      self.help
      exit(1)
    end

    ARGV.each do |arg|
      if arg == 'init'
        self.init()
      elsif arg == 'dev'
        self.for_development()
      elsif arg == 'fix'
        self.fix()
      else
        self.help
        puts "Invalid argument: #{arg}!"
        exit(1)
      end
    end

  end


  def self.destroy_data

    puts "Destroying plan competences, plan courses, study plans, course instances, period descriptions and periods..."

    PlanCompetence.destroy_all()
    PlanCourse.destroy_all()
    StudyPlan.destroy_all()
    CourseInstance.destroy_all()
    PeriodDescription.destroy_all()
    Period.destroy_all()

  end


  def self.create_periods_with_descriptions

    puts "Creating periods with descriptions..."

    dts = Date.parse("2000-01-01")
    dte = Date.parse("2030-01-01")

    ys = 2000
    ye = 2030
    y = ys

    while y < ye

      z = y + 1

      ys = y.to_s[2..3]
      zs = z.to_s[2..3]

      if y < 2013
        data = [
          { s: "#{y}-09-01", e: "#{y}-11-01", i: 0, x: 'I',   n: "#{ys}-#{zs} I"   },
          { s: "#{y}-11-01", e: "#{z}-01-01", i: 1, x: 'II',  n: "#{ys}-#{zs} II"  },
          { s: "#{z}-01-01", e: "#{z}-03-01", i: 2, x: 'III', n: "#{ys}-#{zs} III" },
          { s: "#{z}-03-01", e: "#{z}-06-01", i: 3, x: 'IV',  n: "#{ys}-#{zs} IV"  },
          { s: "#{z}-06-01", e: "#{z}-09-01", i: 4, x: 'S',   n: "#{ys}-#{zs} S"   }
        ]
      else
        data = [
          { s: "#{y}-09-01", e: "#{y}-10-28", i: 0, x: 'I',   n: "#{ys}-#{zs} I"   },
          { s: "#{y}-10-28", e: "#{z}-01-01", i: 1, x: 'II',  n: "#{ys}-#{zs} II"  },
          { s: "#{z}-01-01", e: "#{z}-02-24", i: 2, x: 'III', n: "#{ys}-#{zs} III" },
          { s: "#{z}-02-24", e: "#{z}-04-14", i: 3, x: 'IV',  n: "#{ys}-#{zs} IV"  },
          { s: "#{z}-04-14", e: "#{z}-06-01", i: 4, x: 'V',   n: "#{ys}-#{zs} V"   },
          { s: "#{z}-06-01", e: "#{z}-09-01", i: 5, x: 'S',   n: "#{ys}-#{zs} S"   }
        ]
      end

      for dat in data
        dts = Date.parse(dat[:s])
        dte = Date.parse(dat[:e])

        puts " + [#{dts} - #{dte}] #{dat[:n]}..."

        period = Period.create(
          number:            dat[:i],
          begins_at:         dts,
          ends_at:           dte
        )

        [ 'en', 'fi', 'sv' ].each do |locale|
          PeriodDescription.create(
            period_id:         period.id,
            locale:            locale,
            name:              dat[:n],
            symbol:            dat[:x]
          )
        end

      end

      y += 1

    end

  end


  def self.init_first_study_periods

    puts "Initializing first_study_period for all users..."

    current_period = Period.current

    User.find_each do |user|
      user.first_study_period = current_period
      user.save
    end

  end


  def self.create_random_course_instances

    puts "Creating random course instances..."

    periods = Period.order(:begins_at).all

    AbstractCourse.find_each do |abstract_course|
      period_number = rand(PERIODS_PER_YEAR)
      #length = Math.ceil( Math.sqrt( rand() ) * 3 )
      length = (rand() * 3.0).ceil
      # Length of the last periods can only be 1
      length = 1 if period_number == 1 || period_number == 5

      periods.each do |period|
        if period.number == period_number
          CourseInstance.create(
            abstract_course_id:   abstract_course.id,
            period_id:            period.id,
            length:               length
          )
        end
      end
    end

  end


  def self.init

    puts "Initializing..."
    self.destroy_data()
    self.create_periods_with_descriptions()
    self.init_first_study_periods()
    self.create_random_course_instances()
    puts "Done!"

  end


  def self.for_development
    puts "Doing initializations for development..."
    user = User.where(id: 2).first
    user.first_study_period = Period.current.find_preceding(4).last
    user.save
    puts "Done!"
  end


  def self.fix
    puts "Doing custom fixes..."
    puts "Done!"
  end

end




Init::cli()




# EOF
