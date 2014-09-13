require 'rubygems'
require 'mechanize'

agent = Mechanize.new
page = agent.get('http://google.com/')


puts(page)
array = Array.new
form = page.forms() 
form.each do |f|
	keys = f.keys
	puts('keys: ')
	puts( keys )
end 


def getLinks()
	page.links.each do |link|
		array.push(link)
		#puts( link.text )
		#puts( link.href ) 
	end
end


