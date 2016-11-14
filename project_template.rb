if yes?("Include authentication?")
	auth = true
	gem "devise"
	
	token_auth = ask("Include token_authentication?\n\n1. simple_auth_token generator\n\n(any key to skip token authentication)")
end

if yes?("Using rvm?")
	rvm_ruby_version = ask("which rvm ruby_version?")
	rvm_ruby_gemset = ask("which rvm ruby_gemset?")
	run("echo #{rvm_ruby_version} > .ruby-version")
	run("echo #{rvm_ruby_gemset} > .ruby-gemset")
end

after_bundle do

	if auth
		generate(:"devise:install")
		devise_model_name = ask("Devise model name:")
		generate(:devise, devise_model_name)
		if token_auth == 1
			inside('lib') do
			  run "wget http://github.com/rizel10/simple_token_auth/archive/master.zip && unzip master.zip 'simple_token_auth-master/generators/*' && rsync -av simple_token_auth-master/generators ./ && rm -rf master.zip && rm -rf simple_token_auth-master"
			end
			generate(:authentication, devise_model_name)
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