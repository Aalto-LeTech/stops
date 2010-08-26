# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

areas = Array.new
for i in 1..10
  areas[i] = Area.create(:position => i)
end

AreaDescription.create(:area_id => areas[1].id, :locale => 'fi', :name => 'Teoriatiet&auml;mys', :description => '')
AreaDescription.create(:area_id => areas[2].id, :locale => 'fi', :name => 'Suunnittelutekninen osaaminen', :description => '')
AreaDescription.create(:area_id => areas[3].id, :locale => 'fi', :name => 'Materiaalitekninen osaaminen', :description => '')
AreaDescription.create(:area_id => areas[4].id, :locale => 'fi', :name => 'Valmistus- ja tuotantotekninen osaaminen', :description => '')
AreaDescription.create(:area_id => areas[5].id, :locale => 'fi', :name => 'Projektiosaaminen', :description => '')
AreaDescription.create(:area_id => areas[6].id, :locale => 'fi', :name => 'Liiketoimintaosaaminen', :description => '')
AreaDescription.create(:area_id => areas[7].id, :locale => 'fi', :name => 'Tietotekniikan sovellusten hallinta', :description => '')
AreaDescription.create(:area_id => areas[8].id, :locale => 'fi', :name => 'Ekologinen tiet&auml;mys', :description => '')
AreaDescription.create(:area_id => areas[9].id, :locale => 'fi', :name => 'Lains&auml;&auml;d&auml;nn&ouml;llinen tiet&auml;mys', :description => '')
AreaDescription.create(:area_id => areas[10].id,  :locale => 'fi', :name => 'Tutkimus- ja kehitysosaaminen (T&K)', :description => '')

SkillLevel.create(:level => 1, :locale => 'fi', :name => 'Tunnistaminen', :definition => 'Opiskelija osaa tunnistaa, luetella ja m&auml;&auml;ritell&auml; asioita, k&auml;sitteit&auml;, periaatteita niiden opetetussa muodossa ilman ymm&auml;rt&auml;mist&auml;.')
SkillLevel.create(:level => 2, :locale => 'fi', :name => 'Ymm&auml;rt&auml;minen', :definition => 'Opiskelija ymm&auml;rt&auml;&auml; ja k&auml;sitt&auml;&auml; aiemmin oppimiaan asioita, k&auml;sitteit&auml; ja periaatteita ilman syv&auml;llist&auml; ymm&auml;rt&auml;mist&auml;.')
SkillLevel.create(:level => 3, :locale => 'fi', :name => 'Soveltaminen', :definition => 'Opiskelija osaa soveltaa oppimiaan asioita, k&auml;sitteit&auml; ja periaatteita ongelmien ratkaisemiseen annetuilla tiedoilla kyeten valitsemaan sopivan mentelm&auml;n tai tavan.')
SkillLevel.create(:level => 4, :locale => 'fi', :name => 'Analysointi/arviointi', :definition => ' Opiskelija osaa analysoida, tarkastella ja j&auml;sennell&auml; ongelman ratkaisemisen eri vaiheet ja kykenee arvioimaan, tulkitsemaan ja veratailemaan kriittisesti eri mentelmien antamia tuloksia kesken&auml;&auml;n. Edellytt&auml;&auml; syv&auml;llist&auml; ymm&auml;rt&auml;mist&auml;.')
SkillLevel.create(:level => 5, :locale => 'fi', :name => 'Luominen/kehitt&auml;minen', :definition => 'Opiskelija osaa luoda, kehitt&auml;&auml;, suunnitella ja rakentaa uusia teorioita, malleja, menetelmi&auml; tai tuotteita tai yhdistell&auml; olemassa olevia periaatteita, k&auml;sitteit&auml; ja tietoja uudella tavalla.')
SkillLevel.create(:level => 1, :locale => 'en', :name => 'Recognising')
SkillLevel.create(:level => 2, :locale => 'en', :name => 'Understading')
SkillLevel.create(:level => 3, :locale => 'en', :name => 'Applying')
SkillLevel.create(:level => 4, :locale => 'en', :name => 'Analysing/evaluating')
SkillLevel.create(:level => 5, :locale => 'en', :name => 'Creating/synthesising')



# Users
user = User.new(:password => 'admin', :password_confirmation => 'admin', :name => 'Admin', :email => 'admin@example.com')
user.studentnumber = '12345'
user.login = 'admin'
user.admin = true
user.save

# Create students
for i in 1..10 do
  r = User.new
  r.studentnumber = i.to_s.rjust(5, '0')
  r.login = r.studentnumber
  r.password = "student#{i}"
  r.password_confirmation = "student#{i}"
  r.name = "Student #{i}"
  r.email = "student#{i}@example.com"
  r.save
end