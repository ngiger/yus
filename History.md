# 1.0.8 / Not yet released

* Removed obsolete install.rb file (from 2010)
* Ran standard:fix and manually corrected all warnings
* Remove references to no longer used gem og
* Moved *.txt files to *.md (Readme, History, Guide)
* Made bin/yus* commands work again (removed loading unused gems)
* Added Rake task standard
* Use simplecov when running bundle rake

# 1.0.7 / 08.01.2025

* Added devenv environment for Ruby 3.4 (see https://devenv.sh/)
* Fixed Rakefile
* Added minimal Ruby version 3.0 in gemspec
* (#8) Force yus.yml to be found in /etc/yus
* changelog_uri to gemspec
* Fix spelling for default cleaner_interval in bin/yusd

# 1.0.6 / 17.06.2020

* Update for Ruby 2.7.1, remove obsolete calls to untaint/SAFE

# 1.0.5 / 21.03.2019

* Requires at least ruby 2.3 and bundler 2.0
* Do not mention pg, ydbd-pg and ydbg in yus.gemspec as it is an indirect dependencies introduced odba


# 1.0.4 / 11.07.2016

* Added yus_migrate_to_utf_8
* Cleanup yus/helpers and bin/yus* to use always module name Yus (not YUS)
* Fixed an error preventing yusd to run under Ruby 2.3.1

# 1.0.3 / 23.05.2016

* Make it run under Ruby >= 2.1
* Replaced hoe by bundler/gem_tasks

# 1.0.2 / 01.10.2014

* Added bin/yus_dump to dump yus-database into data/yus_dump.yml
* Added concerned user and result when logging allowed?
* Improved unit-tests
* Made travis-ci pass for 1.8.7 and 2.1.2

# 1.0.1 / 18.06.2013

* Rename pg driver name to Pg
  - pg(ruby-pg) gem expects 'Pg' (not 'pg')

# 1.0.0 / 17.12.2010

* ywesee user server is not yet Ruby 1.9 ready.

  * Birthday!
