namespace :blog do
  desc 'Remove generated files'
  task :clean do
    system "rm -rf _site"
  end
  
  desc 'Build the site and run the server for dev'
  task :local do
    system "jekyll --server --pygments"
  end
  
  desc 'Deploying to webserver'
  task :deploy do
    #the "adam" user only has write perms on this one specific directory - it uses ssh via keyfile so no password is needed
    system "jekyll && scp -r -P 22255 _site/* adam@thecoffman.com:/var/www/thecoffman.com"
  end

  desc 'Create new post markdown file'
  task :post, [:post_title] do |t,args|
    require 'date'
    system "echo \"---\nlayout: post\ntitle: #{args.post_title}\ncomments: true\n---\" >  _posts/#{Date.today.year}-#{Date.today.strftime("%m")}-#{Date.today.strftime("%d")}-#{args.post_title.downcase.split(' ').join('-')}.md"
  end
end
