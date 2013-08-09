# O4

O4 (Opiskelijaa ohjaava opinto-opas) or STOPS (Software for target-oriented personal sylabus) is web-based tool that allows university staff to plan course contents and students to construct personal study plans.


## Installing

As root:
```bash
apt-get install build-essential
apt-get install ruby1.9.1 ruby1.9.1-dev
apt-get install postgresql-server-dev-8.4 # (or applicable)
```

If necessary:
```bash
cd /usr/bin/
ln -s ruby1.9.1 ruby
ln -s rake1.9.1 rake
ln -s gem1.9.1 gem
ln -s irb1.9.1 irb
```

Add this to your own .bash_rc:
```bash
PATH="$PATH:/var/lib/gems/1.9.1/bin"
```

As a normal user:
```bash
gem install bundler
```


### Create database

```bash
sudo -u postgres psql
```

```sql
CREATE USER rails PASSWORD 'password' CREATEDB;
CREATE DATABASE o4 OWNER rails;
```


### Configure application

As normal user:
```bash
cd o4
bundle install

cp config/database.yml.base config/database.yml
cp config/initializers/settings.rb.base config/initializers/settings.rb
cp config/initializers/secret_token.rb.base config/initializers/secret_token.rb

rake db:schema:load
rake db:seed
```

Edit settings in database.yml, settings.rb and secret_token.rb.
