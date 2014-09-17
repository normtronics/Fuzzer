require 'rubygems'
require 'mechanize'

def getLinks( page )
	puts("Link: ")
	page.links.each do |link|
		#puts( link.text )
		puts( link.href ) 
	end
end

def customAuth(form, agent)

	form['username'] = "admin"
	form['password'] = "password"
	 # Required otherwise form submission fails silently
    form["Login"] = 'submit'
    return agent.submit(form)

end

def getFieldsOnPage(form)
	keys = form.keys
	puts('keys: ')
	keys.each do | field |  
		puts( field )
	end 
end


def main()
	agent = Mechanize.new
	page = agent.get('http://127.0.0.1/dvwa/login.php')

	form = page.forms.first 
	if(form.has_field?'username' and form.has_field?'password')
		page = customAuth(form, agent)
	end

	page.forms.each do | form |
		getFieldsOnPage(form)
	end
	
	getLinks(page)
end




main()


