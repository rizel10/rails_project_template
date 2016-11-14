gem "paranoia"

if yes?("Include authentication?")
	auth = true
	gem "devise"
	
	token_auth = ask("Include token_authentication?\n\n1. simple_auth_token generator\n\n(any key to skip)\n")
end

if yes?("Geolocation queries?")
	gem "geokit-rails"
end

if yes?("Using file upload?")
	carrierwave = true
	gem "carrierwave"
	gem 'mini_magick'
end

if yes?("Using delayed_jobs?")
	delayed_jobs = true
	gem "delayed_job_active_record"
end

case ask("Which paginator gem?\n\n1. kaminari\n2. will_paginate\n\n(any key to skip)\n")
when "1"
	gem "kaminari"
	kaminari = true
when "2"
	gem "will_paginate"
end

if yes?("Include push notification?")
	push = true
	gem "houston"
	gem "fcm"
end

if yes?("Using rvm?")
	rvm_ruby_version = ask("which rvm ruby_version?")
	rvm_ruby_gemset = ask("which rvm ruby_gemset?")
	run("rvm #{rvm_ruby_version}")
	run("rvm gemset create #{rvm_ruby_gemset}")
	run("rvm gemset use #{rvm_ruby_gemset}")
	run("echo #{rvm_ruby_version} > .ruby-version")
	run("echo #{rvm_ruby_gemset} > .ruby-gemset")
end

after_bundle do

	if auth
		generate(:"devise:install")
		devise_model_name = ask("Devise model name:")
		
		if devise_model_name == ""
			devise_model_name = "User"
		end
		
		generate(:devise, devise_model_name)
		
		if token_auth.to_i == 1
			inside('lib') do
			  run "wget http://github.com/rizel10/simple_token_auth/archive/master.zip && unzip master.zip 'simple_token_auth-master/generators/*' && rsync -av simple_token_auth-master/generators ./ && rm -rf master.zip && rm -rf simple_token_auth-master"
			end
			generate(:authentication, devise_model_name)
		end
	end

	if carrierwave
		uploader_name = ask("Carrierwave uploader name:")
		if uploader_name == ""
			uploader_name = "Avatar"
		end
		generate(:carrierwave, uploader_name)
	end

	if delayed_jobs
		generate(:"delayed_job:active_record")
	end

	if kaminari
		generate(:"kaminari:config")
	end

	if push
		run("mkdir apple_certificates")
		inside('apple_certificates') do
			run("echo '' > development.pem")
			run("echo '' > production.pem")
		end
		
		inside('config') do
			run("printf 'development:\n   fcm_key: \n   sender_id: \nproduction:\n   fcm_key: \n   sender_id: ' > fcm.yml")
		end

		inside('config/initializers') do
			run("echo FCM_PUSHER = FCM.new(YAML.load_file(Rails.root.to_s + '/config/fcm.yml')[Rails.env]['fcm_key']) > fcm.rb")
			run("printf \"case Rails.env\nwhen \"development\"\n\tAPN = Houston::Client.development\n\tAPN.certificate = File.read(\"apple_certificates/development.pem\")\nwhen \"production\"\n\tAPN = Houston::Client.production\n\tAPN.certificate = File.read(\"apple_certificates/production.pem\")\nend\" > houston.rb")
		end
	end

	if yes?("Is a git repo?")
		git_repo_url = ask("remote origin url:")
	  git :init
	  git add: '.'
	  git commit: "-a -m 'Initial commit'"
	  git remote: "add origin #{git_repo_url}"
	  git push: "-u origin master"
	end
end