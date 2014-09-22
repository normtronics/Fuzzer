require 'rubygems'
require 'mechanize'
require 'uri'
require 'http-cookie'


class Discover

	def initialize(commonWords, page)
		f = File.open(commonWords, "r")
		@agent = Mechanize.new
		@page = @agent.get(page)
		@base = @page.uri.to_s
		@links = findLinks

		puts @base
		puts @links

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

		
		#authenticate()
		findLinks()
		getFormParams()
		puts getCookies()
	end
	
	def findLinks
		page = @agent.get(@page)
		allLinks = Array.new()
		base = getBasePath(page.uri.to_s)
		page.links.each do |l|
			begin
				unless l.uri.to_s.downcase.include?("logout")
					next_page = @agent.get(base.merge l.uri)
					if next_page.uri.host.eql?(page.uri.host)
						puts "GO: " + next_page.uri.to_s
						allLinks.push(l.uri)
					end
				end
			rescue Mechanize::ResponseCodeError
				puts 'Could not find page'
			end
		end
		i = 0
		while i < allLinks.size do
			puts allLinks[i].to_s
			currPage = @agent.get(base.merge allLinks[i])
			currPage.links.each do |link|
				unless l.uri.to_s.downcase.include?("logout")
					begin
						check_page = @agent.get(base.merge link.uri)
						if !allLinks.include?(link.uri)
							allLinks.push(link.uri)
						end
					rescue Mechanize::ResponseCodeError
						puts 'Could not find page'
					end
				end
			end
			i+=1
		end
		urls = Array.new()
		allLinks.each do |link|
			urls.push(base.merge link)
		end
	end	

	def getURL( link )
		return @base + link.href
	end

	def authenticate
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
		puts '----------Now Guessing Pages--------------'
		@commonArray.each do |word|
			begin
				url = @base + '/' + word
				page = @agent.get(url)
				puts 'Found page ' + url
			rescue Mechanize::ResponseCodeError
				puts 'Could not find page ' + url
			end
		end
	end

	def parseUrl( page, inputs)
	
		page.uri.query.to_s.split('&').each do | input |
			inputs.push input.split('=')[0]
		end

	end

	def discoverInputs

		@links.each do | l |
			inputs = Array.new
			page = @agent.get(l)
			pp page
			puts page.uri
			forms = page.forms()
			forms.each_with_index do | f | 
				f.keys.each do | key | 
					inputs.push( key )
					f[key] = "input"
				end
				currPage = f.click_button
				parseUrl(currPage, inputs)
				if( not inputs.empty? )
					puts "    " + inputs.uniq.to_s
				end
			end
		end

	end

	def getFormParams
		page = @agent.get(@pages)
		page.forms
	end

	def getCookies
		return @agent.cookies.to_s
	end

	def getBasePath(page)
		return URI(page)
	end

end


def getLinks(page)
	agent = Mechanize.new
	page = agent.get('http://127.0.0.1:8080/bodgeit/')
	allLinks = Array.new()
	page.links.each do |l|
		allLinks.push(l.uri)
	end
	i = 0
	while i < allLinks.size do
		currPage = agent.get(allLinks[i])
		currPage.links.each do |link|
			if !allLinks.include?(link.uri)
				allLinks.push(link.uri)
			end
		end
		i+=1
	end
	urls = Array.new()
	allLinks.each do |link|
		urls.push(page.uri.merge link)
	end
	urls.each do |link|
		puts link
	end
end	

def main()
	agent = Mechanize.new
	page = agent.get('http://127.0.0.1/dvwa/login.php')
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

def main2()
	agent = Mechanize.new
	page = agent.get('http://127.0.0.1:8080/bodgeit/')
	getLinks(page)
end



#main
