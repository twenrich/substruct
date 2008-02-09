namespace :substruct do
      
  SUBSTRUCT_DATA_DUMP_MODELS = [
    'ContentNode', 'Country', 'Preference', 'OrderShippingType', 
    'OrderShippingWeight', 'OrderStatusCode', 'Right', 'Role', 'User'
  ]
  
  SUBSTRUCT_BOOTSTRAP_PATH = 'vendor/plugins/substruct/db/bootstrap'
  
  # MAINTENANCE ===============================================================
  
  desc %q\
  Hourly maintenance task that should be run on your Substruct site.
  Does some housekeeping so the DB is in order.
  Remember to pass it the proper RAILS_ENV if running from cron.
  \
  task :maintain => :environment do
    puts "Updating country order counts..."
    countries = Country.find(:all)
    countries.each { |c|
      sql = "SELECT COUNT(*) "
      sql << "FROM order_addresses "
      sql << "WHERE country_id = ?"
      c.number_of_orders = ActiveRecord::Base.count_by_sql([sql, c.id])
      c.save
    }

    puts "Updating product costs..."
    orders = Order.find(:all, :conditions => "product_cost = 0")
    orders.each { |order|
      order.product_cost = order.line_items_total
      order.save
    }

    puts "Removing crusty sessions..."
    stale = Session.find(:all, :conditions => ["updated_at <= ?", Time.now - SESSION_TIMEOUT])
    stale.each { |s| s.destroy }
  end
  
  # DATABASE ==================================================================
  
  namespace :db do
    
    desc %q\
    Initializes Substruct database passed in RAILS_ENV and preps for use.
    Will drop / re-create / re-load authority data.
    BE CAREFUL THIS WILL DESTROY YOUR DATA IF USED INCORRECTLY.
    \
    task :bootstrap do |task_args|
      
      # Check requirements
      require 'rubygems' unless Object.const_defined?(:Gem)
      %w(RedCloth fastercsv mime-types mini_magick).each do |gem_name|
        check_installed_gem(gem_name)
      end
      
      mkdir_p File.join(RAILS_ROOT, 'log')
      
      puts "Initializing database..."
      
      # Move our schema file into place so we can load it.
      schema_file = File.join(RAILS_ROOT, 'vendor/plugins/substruct/db/schema.rb')
      FileUtils.cp(schema_file, File.join(RAILS_ROOT, 'db'))
    
      %w(
        environment 
        db:drop
        db:create
        db:schema:load
        substruct:db:load_authority_data
        tmp:create
      ).each { |t| Rake::Task[t].execute task_args}
      
      puts '=' * 80
      puts
      puts "Thanks for trying Substruct #{Substruct::Version::STRING}"
      puts
      puts "Now you can start the application with 'script/server' "
      puts "visit: http://localhost:3000/admin, and log in with admin / admin."
      puts
      puts "For help, visit the following:"
      puts "  Official Substruct Site - http://dev.subimage.com/projects/substruct"
      puts "  Substruct Google Group - http://groups.google.com/group/substruct"
      puts
      puts "- Subimage LLC - http://www.subimage.com"
      puts 

    end # bootstrap
    
    desc %q\
    Dump authority data to YML files.
    ...Also moves dumped files to the proper directory required for an import later on.
    You don't need this unless you're prepping an official Substruct release.
    \
    task :dump_authority_data => :environment do |task_args|

      bootstrap_fixture_path = File.join(RAILS_ROOT, SUBSTRUCT_BOOTSTRAP_PATH)
      fixture_dump_path = File.join(RAILS_ROOT, 'test/fixtures')
      
      FileUtils.rm Dir.glob(File.join(fixture_dump_path, "*.yml"))
      
      # Dump
      puts "Dumping data..."
      SUBSTRUCT_DATA_DUMP_MODELS.each do |model_name|
        ENV['MODEL'] = model_name
        Rake::Task['db:fixtures:dump'].execute task_args
      end

      puts "Removing old fixture files..."
      FileUtils.rm Dir.glob(File.join(bootstrap_fixture_path, "*.yml"))
      puts "Moving fixture files to the proper location..."
      FileUtils.mv(Dir.glob(File.join(fixture_dump_path, "*.yml")), bootstrap_fixture_path)
      
    end
  
      
    desc %q\
    Loads baseline data needed for Substruct to operate.
    Delete records & load initial database fixtures (substruct/db/bootstrap/*.yml) into the current environment's database.
    \
    task :load_authority_data => :environment do
      require 'active_record/fixtures'
      puts "Clearing previous data..."
      SUBSTRUCT_DATA_DUMP_MODELS.each do |model|
        model.constantize.destroy_all
      end
      puts "Removing all sessions..."
      Session.destroy_all
      puts "Loading default data..."
      bootstrap_fixture_path = File.join(RAILS_ROOT, SUBSTRUCT_BOOTSTRAP_PATH)
      Dir.glob(File.join(bootstrap_fixture_path, '*.{yml,csv}')).each do |file|
        Fixtures.create_fixtures(bootstrap_fixture_path, File.basename(file, '.*'))
      end
      puts "...done."
    end
    
  end # db namespace
  
  # Packaging & release =======================================================
  
  namespace :release do
  
    desc %q\
    Packages a gzip release tagged by VERSION.
    Makes new Rails site, exports the stuff necessary, and gzips the badboy.
    Great for n00bz who can't install Rails apps.
    No more bitching about incorrect versions or dependencies!
    \
    task :package => :environment do
      version = ENV['VERSION']
      raise "Please specify a Substruct VERSION" if version.nil?
      tag = "rel_#{version}"
      release_name = "substruct_#{tag.gsub('.', '-')}"
      tmp_dir = File.join(RAILS_ROOT, 'tmp', release_name)
      # clean up any tmp releases
      FileUtils.rm_rf(Dir.glob(File.join(tmp_dir, '*.gz')))
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      Dir.chdir(tmp_dir)
      
      puts "Making Substruct #{version} release here: #{tmp_dir}"
      `rails .`
      
      
      puts "Exporting Substruct release (#{tag})..."
      FileUtils.rm_rf(File.join(tmp_dir, 'vendor/plugins'))
      puts `svn export http://svn.subimage.com/source/substruct/site/tags/#{tag} vendor/plugins --username substruct --password substruct`
      
      puts "Exporting Rails version as defined in environment.rb (#{RAILS_GEM_VERSION})..."
      rails_tag = "rel_#{RAILS_GEM_VERSION.gsub!('.', '-')}"
      puts `svn export http://svn.rubyonrails.org/rails/tags/#{rails_tag} vendor/rails`
      
      # Crazy shit we need to do in order to make this proper.
      # Better here than having people do it via instructions on the site!
      #
      puts "Copying appropriate files..."
      ss_dir = File.join(tmp_dir, 'vendor/plugins/substruct')      
      # copy from ss config dir into real config
      config_dir = File.join(tmp_dir, 'config')
      FileUtils.cp(File.join(ss_dir, 'config', 'environment.rb'), config_dir)
      FileUtils.cp(File.join(ss_dir, 'config', 'routes.rb'), config_dir)
      FileUtils.cp(File.join(ss_dir, 'config', 'database.yml'), config_dir)
      
      # application.rb
      # necessary to include substruct engine before filters
      app_rb = File.join(ss_dir, 'config', 'application.rb.example')
      FileUtils.cp(app_rb, File.join(tmp_dir, 'app', 'controllers', 'application.rb'))
      
      # touch loading.html - necessary for submodal
      FileUtils.touch(File.join(tmp_dir, 'public', 'loading.html'))
      
      # remove index.html so people don't get stupid "welcome to rails" page
      FileUtils.rm(File.join(tmp_dir, 'public', 'index.html'))
      
      # rm application_helper so it'll use the one in substruct dir
      # ...might be better to copy?
      FileUtils.rm(File.join(tmp_dir, 'app/helpers', 'application_helper.rb'))
      
      Dir.chdir('..')
      puts "Tar and feathering..."
      rel_archive = "#{release_name}.tar.gz"
      `tar -czf #{rel_archive} #{release_name}`
      
      puts "Removing temp dir..."
      FileUtils.rm_rf(release_name)
      
      puts "Moving release to download directory..."
      FileUtils.mv(rel_archive, '../public/releases/')
      
      puts "Done."
    end
    
    desc %q\
    Tags a release. VERSION=new_version_number
    \
    task :tag => :environment do
      version = ENV['VERSION']
      raise "Please specify a VERSION." if version.nil?
      puts "Tagging for version: #{version}"
      puts `svn copy vendor/plugins ../tags/rel_#{version}`
    end
  
  end
  
end

def check_installed_gem(gem_name)
  begin
    gem gem_name
  rescue Gem::LoadError
    puts 
    puts '!!! GEM LOAD ERROR'
    puts 
    puts "You are missing the #{gem_name} gem."
    puts "Please install it before proceeding."
    puts
    raise
  end
end