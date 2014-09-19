require 'rubygems'
require 'mechanize'
require 'uri'
require 'http-cookie'


class Discover

	def initialize(commonWords, page)
		f = File.open(commonWords, "r")
		@agent = Mechanize.new
		@page = page
		@base = getBasePath(page)

		puts @base

		begin
			@commonArray = Array.new
			f.each_line do |line|
  				@commonArray.push(line)
  				puts line
			end
			f.close
		rescue SystemCallError
			puts 'IO Failed. Check file path'
			f.close
			File.delete(commonWords)
			raise
		end	

		athenticate()
		findLinks()
		getFormParams()
		puts getCookies()
	end

	def findLinks
		page = @agent.get(@page)
		pp page
		linksArray = Array.new
		page.links.each do |link|
			linksArray.push(link)
			puts( link.uri )
		end
	end

	def athenticate
		page = @agent.get(@page)
		form = page.forms.first 


		form['username'] = "admin"
		form['password'] = "password"
		page2 = form.click_button

		#Might want to iterate through page to really check if its the same
		if page2.title.eql?(page.title)
			puts 'Login did not work'
		else
			@page = page2
		end
	end

	def pageGuess
		@commanArray.each do |word|
			page = @agent.get(@base + '/' + word)
			puts page
		end
	end

	def parseUrl


	end


	def getFormParams
		page = @agent.get(@pages)
		page.forms
	end

	def getCookies
		return @agent.cookies.to_s
	end

	def getBasePath(page)
		uri = URI(page)
		return "#{uri.scheme}://#{uri.host}"
	end

end



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
	page = agent.get('http://localhost:8888/dvwa/login.php')
	pp page

	form = page.forms.first 

	form['username'] = "admin"
	form['password'] = "password"
	page2 = form.click_button

	pp page2

	#might want to iterate through page to really check if its the same
	if page2.title.eql?(page.title)
		puts 'Login did not work'
	end

	getLinks(page)
end


#main()
