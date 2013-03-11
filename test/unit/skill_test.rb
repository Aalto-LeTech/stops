require 'set'
require 'test_helper'

class SkillTest < ActiveSupport::TestCase

  context "A skill" do

    setup do 
      @curriculum = FactoryGirl.create :curriculum
      @skill      = FactoryGirl.build  :skill
      competence  = FactoryGirl.build  :competence
      course      = FactoryGirl.build  :scoped_course

      course.curriculum     = @curriculum
      competence.curriculum = @curriculum

      course.save! 

      competence.save!
      @root_skill_course_id = course.id

      @skill.competence_node = competence
      @skill.save!
    end

    should "have one CompetenceNode" do
      refute @skill.competence_node.nil?
    end

    should "not blow up when 'description' is called and there is no description" do
      assert_nothing_raised { @skill.description('en') }
    end


    context "as a prequirement to other skills" do

      setup do
        # @target_course_ids = Set.new
        # @target_skill_ids  = Set.new
        # @target_course_ids << @root_skill_course_id

        # # Second level of skills: two skills sharing a course
        # course            = FactoryGirl.build :scoped_course
        # course.curriculum = @curriculum
        # course.save!

        # level2_skill1 = FactoryGirl.build :skill
        # level2_skill1.competence_nodes << course
        # level2_skill1.save!
        # @skill.prereq_to << level2_skill1

        # level2_skill2 = FactoryGirl.build :skill
        # competence    = FactoryGirl.build :competence
        # competence.curriculum = @curriculum
        # competence.save!
        # level2_skill2.competence_nodes << course
        # level2_skill2.competence_nodes << competence
        # level2_skill2.save!
        # @skill.prereq_to << level2_skill2

        # # Second level of skills: another skill with separate course
        # course            = FactoryGirl.build:scoped_course
        # course.curriculum = @curriculum
        # course.save!

        # @target_course_ids << course.id

        # level2_skill3 = FactoryGirl.build :skill
        # level2_skill3.competence_nodes << course
        # level2_skill3.save!
        # @skill.prereq_to << level2_skill3

        # # Third level of skills
        # another_skill = FactoryGirl.build :skill
        # course        = FactoryGirl.build :scoped_course
        # course.curriculum = @curriculum
        # course.save!
        # another_skill.competence_nodes << course
        # another_skill.save!
        # level2_skill1.prereq_to << another_skill

        # another_skill = FactoryGirl.build :skill
        # course = FactoryGirl.build :scoped_course
        # course.curriculum = @curriculum
        # course.save!
        # @target_course_ids << course.id
        # another_skill.competence_nodes << course
        # another_skill.save!
        # level2_skill1.prereq_to << another_skill
        # level2_skill2.prereq_to << another_skill
        # @target_skill_ids << another_skill.id

        # another_skill = FactoryGirl.build :skill
        # course = FactoryGirl.build :scoped_course
        # course.curriculum = @curriculum
        # course.save!
        # @target_course_ids << course.id
        # another_skill.competence_nodes << course
        # another_skill.save!
        # level2_skill2.prereq_to << another_skill
        # level3_skill3 = another_skill

        # another_skill = FactoryGirl.build :skill
        # course = FactoryGirl.build :scoped_course
        # course.curriculum = @curriculum
        # course.save!
        # another_skill.competence_nodes << course
        # another_skill.save!
        # level2_skill3.prereq_to << another_skill
        # @target_skill_ids << another_skill.id

        # # Last level of skills
        # another_skill = FactoryGirl.build :skill
        # course = FactoryGirl.build :scoped_course
        # course.curriculum = @curriculum
        # course.save!
        # @target_course_ids << course.id
        # another_skill.competence_nodes << course
        # another_skill.save!
        # level3_skill3.prereq_to << another_skill
        # level2_skill3.prereq_to << another_skill
        # @target_skill_ids << another_skill.id

      end

      should "actually be a prerequirement to some skill according to 'prereq_to'" do
        # refute @skill.prereq_to.exists?, "Skill should have had prerequirements"
      end

      should "have a correctly functioning 'dfs' method" do
        # TODO: Work in progress
        assert true
      end
    end
  end
end
