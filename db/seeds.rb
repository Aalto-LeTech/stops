# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# areas = Array.new
# for i in 1..10
#   areas[i] = Area.create(:position => i)
# end

# AreaDescription.create(:area_id => areas[1].id, :locale => 'fi', :name => 'Teoriatietämys', :description => '')
# AreaDescription.create(:area_id => areas[2].id, :locale => 'fi', :name => 'Suunnittelutekninen osaaminen', :description => '')
# AreaDescription.create(:area_id => areas[3].id, :locale => 'fi', :name => 'Materiaalitekninen osaaminen', :description => '')
# AreaDescription.create(:area_id => areas[4].id, :locale => 'fi', :name => 'Valmistus- ja tuotantotekninen osaaminen', :description => '')
# AreaDescription.create(:area_id => areas[5].id, :locale => 'fi', :name => 'Projektiosaaminen', :description => '')
# AreaDescription.create(:area_id => areas[6].id, :locale => 'fi', :name => 'Liiketoimintaosaaminen', :description => '')
# AreaDescription.create(:area_id => areas[7].id, :locale => 'fi', :name => 'Tietotekniikan sovellusten hallinta', :description => '')
# AreaDescription.create(:area_id => areas[8].id, :locale => 'fi', :name => 'Ekologinen tietämys', :description => '')
# AreaDescription.create(:area_id => areas[9].id, :locale => 'fi', :name => 'Lainsäädännöllinen tietämys', :description => '')
# AreaDescription.create(:area_id => areas[10].id,  :locale => 'fi', :name => 'Tutkimus- ja kehitysosaaminen (T&K)', :description => '')

puts('Creating skill levels')
SkillLevel.create(:level => 1, :locale => 'fi', :name => 'Tunnistaminen', :definition => 'Opiskelija osaa tunnistaa, luetella ja määritellä asioita, käsitteitä, periaatteita niiden opetetussa muodossa ilman ymmärtämistä.')
SkillLevel.create(:level => 2, :locale => 'fi', :name => 'Ymmärtäminen', :definition => 'Opiskelija ymmärtää ja käsittää aiemmin oppimiaan asioita, käsitteitä ja periaatteita ilman syvällistä ymmärtämistä.')
SkillLevel.create(:level => 3, :locale => 'fi', :name => 'Soveltaminen', :definition => 'Opiskelija osaa soveltaa oppimiaan asioita, käsitteitä ja periaatteita ongelmien ratkaisemiseen annetuilla tiedoilla kyeten valitsemaan sopivan mentelmän tai tavan.')
SkillLevel.create(:level => 4, :locale => 'fi', :name => 'Analysointi/arviointi', :definition => ' Opiskelija osaa analysoida, tarkastella ja jäsennellä ongelman ratkaisemisen eri vaiheet ja kykenee arvioimaan, tulkitsemaan ja veratailemaan kriittisesti eri mentelmien antamia tuloksia keskenään. Edellyttää syvällistä ymmärtämistä.')
SkillLevel.create(:level => 5, :locale => 'fi', :name => 'Luominen/kehittäminen', :definition => 'Opiskelija osaa luoda, kehittää, suunnitella ja rakentaa uusia teorioita, malleja, menetelmiä tai tuotteita tai yhdistellä olemassa olevia periaatteita, käsitteitä ja tietoja uudella tavalla.')
SkillLevel.create(:level => 1, :locale => 'en', :name => 'Recognising')
SkillLevel.create(:level => 2, :locale => 'en', :name => 'Understading')
SkillLevel.create(:level => 3, :locale => 'en', :name => 'Applying')
SkillLevel.create(:level => 4, :locale => 'en', :name => 'Analysing/evaluating')
SkillLevel.create(:level => 5, :locale => 'en', :name => 'Creating/synthesising')


# Periods
puts('Creating periods')
period_names_fi = ["III kevät","IV kevät"," kesä","I syksy","II syksy"]
period_names_en = ["III spring","IV spring"," summer","I fall","II fall"]
period_begins = ["01-01","01-03","01-06","01-09","01-11"]
period_ends = ["28-02","31-05","31-08","31-10","31-12"]

for year in 2005..2020 do
  for period in 0..4
    p = Period.new
    p.number = period
    p.begins_at = "#{period_begins[period]}-#{year}"
    p.ends_at = "#{period_ends[period]}-#{year}"
    p.save

    PeriodDescription.create(:period_id => p.id, :locale => 'fi', :name => "#{year} #{period_names_fi[period]}")
    PeriodDescription.create(:period_id => p.id, :locale => 'en', :name => "#{year} #{period_names_en[period]}")
  end
end

first_period = Period.order(:begins_at).first

# Users
puts('Creating users')

user = User.new(:password => 'admin', :password_confirmation => 'admin', :name => 'Admin', :email => 'admin@example.com')
#user.studentnumber = '12345'
user.first_study_period = first_period
user.login = 'admin'
user.studentnumber = 'admin'
user.admin = true
user.save

# Create students
for i in 1..10 do
  r = User.new
  r.studentnumber = i.to_s.rjust(5, '0')
  r.login = i.to_s.rjust(5, '0')
  r.first_study_period = first_period
  r.password = "student#{i}"
  r.password_confirmation = "student#{i}"
  r.name = "Student #{i}"
  r.email = "student#{i}@example.com"
  r.save
end
