namespace :sync do
  desc 'Setup admin user. usage: setup_admin_user["email", password"]'
  task :setup_admin_user, [:email, :password] => :environment do |task, args|
    ##############################################
    # make the requested admin user

    User.where(email: args[:email]).first_or_create!(password: args[:password], role: 'admin')

    # finished creating users
    ##############################################
  end

end
