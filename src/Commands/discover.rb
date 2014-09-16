require 'rubygems'
require 'mechanize'

def getLinks( page )
	puts("Link: ")
	page.links.each do |link|
		array.push(link)
		puts( link.text )
		#puts( link.href ) 
	end
end

def main()
	agent = Mechanize.new
	page = agent.get('http://127.0.0.1/dvwa/login.php')


	form = page.forms.first 

	puts(form)
	# keys = form.keys
	# puts('keys: ')
	# keys.each do | field |  
	# 	puts( field )
	# 	form[field] = 'admin'
	# end 
	form['username'] = "admin"
	form['password'] = "password"
	puts( form['username'])
	puts( form['password'])
	page = agent.submit(form)
	pp page
	getLinks(page)
end


main()


